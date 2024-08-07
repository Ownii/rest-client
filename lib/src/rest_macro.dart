// ignore_for_file: prefer_relative_imports, require_trailing_commas

import 'dart:async';

import 'package:api_client/src/rest.dart';
import 'package:api_client/src/utils/list_extensions.dart';
import 'package:api_client/src/utils/type_extensions.dart';
import 'package:macros/macros.dart';

mixin RequestMacro on HttpMethod implements MethodDefinitionMacro {
  @override
  FutureOr<void> buildDefinitionForMethod(
      MethodDeclaration method, FunctionDefinitionBuilder builder) async {
    final isSerializable =
        await checkMethodTypesForJsonSerialization(method, builder);
    if (isSerializable) {
      await buildApiMethodImplementation(method, builder);
    }
  }

  Future<bool> checkMethodTypesForJsonSerialization(
      MethodDeclaration method, FunctionDefinitionBuilder builder) async {
    var isValid = true;
    if (!_isFuture(method.returnType)) {
      builder.report(Diagnostic(
          DiagnosticMessage(
              'return type of a restful method needs to be a Future',
              target: method.returnType.asDiagnosticTarget),
          Severity.error));
      isValid = false;
    } else {
      final genericType =
          (method.returnType as NamedTypeAnnotation).typeArguments.singleOrNull;

      if (genericType == null ||
          !(await _isJsonDeserializable(genericType, builder))) {
        builder.report(Diagnostic(
            DiagnosticMessage(
                'return type `${genericType?.name}` is not json serializable',
                target: (genericType ?? method.returnType).asDiagnosticTarget),
            Severity.error));
        isValid = false;
      }
    }

    // TODO: find body parameter
    // TODO: body for get not valid
    return isValid;
  }

  bool _isJsonSerializable(TypeAnnotation type) {
    // TODO: check if has method `toJson` return Map<String, dynamic>
    return false;
  }

  Future<bool> _isJsonDeserializable(
      TypeAnnotation type, FunctionDefinitionBuilder builder) async {
    // get fromJson constructor
    final namedType = type as NamedTypeAnnotation;
    final typeDeclaration =
        await builder.typeDeclarationOf(namedType.identifier);
    final constructors = await builder.constructorsOf(typeDeclaration);
    final fromJson = constructors
        .firstWhereOrNull((method) => method.identifier.name == 'fromJson');
    if (fromJson == null) {
      return false;
    }

    // check if constructor takes Map<String, Object>
    final jsonParam = fromJson.positionalParameters.singleOrNull;
    if (jsonParam == null || jsonParam.type.name != 'Map') {
      return false;
    }

    final mapTypes = (jsonParam.type as NamedTypeAnnotation).typeArguments;
    if (mapTypes.length != 2 ||
        mapTypes.firstOrNull?.name != 'String' ||
        mapTypes.lastOrNull?.name != 'Object') {
      return false;
    }

    return true;
  }

  bool _isFuture(TypeAnnotation type) {
    return type is NamedTypeAnnotation && type.identifier.name == 'Future';
  }

  Future<void> buildApiMethodImplementation(
      MethodDeclaration method, FunctionDefinitionBuilder builder) async {
    final returnType = (method.returnType as NamedTypeAnnotation)
        .typeArguments
        .single; // we know returnType is Future<T>
    final queryParams = getQueryParams(method);

    builder.augment(
      FunctionBodyCode.fromParts([
        'async {\n',
        '\t\tfinal response = await dio.get(\'$path\'',
        if (queryParams.isNotEmpty)
          ', queryParameters: {${queryParams.entries.map((entry) => '\'${entry.key}\': ${entry.value}').join(', ')}}',
        ');\n',
        '\t\treturn ',
        returnType.code,
        '.fromJson(response.data);',
        '\n\t}',
      ]),
    );
  }

  Map<String, String> getQueryParams(MethodDeclaration method) {
    final parameters = [
      ...method.positionalParameters,
      ...method.namedParameters
    ];
    final queryParams = parameters.where((param) =>
        param.metadata.any((meta) => _isAnnotationType(meta, 'Query')));
    return {
      for (final param in queryParams)
        param.name: param.name, // TODO: get name from annotation if provided
    };
  }

  bool _isAnnotationType(MetadataAnnotation meta, String type) {
    return switch (meta) {
      ConstructorMetadataAnnotation() => meta.type.name == type,
      _ => false,
    };
  }
}
