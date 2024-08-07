// ignore_for_file: prefer_relative_imports, require_trailing_commas

import 'dart:async';

import 'package:api_client/src/rest.dart';
import 'package:api_client/src/utils/list_extensions.dart';
import 'package:api_client/src/utils/type_extensions.dart';
import 'package:api_client/src/utils/builder_extensions.dart';
import 'package:macros/macros.dart';

import 'libraries.dart';

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
    final queryParams = getQueryParams(method, builder);

    final path = _buildPath(method, builder);

    builder.augment(
      FunctionBodyCode.fromParts([
        'async {\n',
        '\t\tfinal response = await dio.request(\'$path\',',
        if (queryParams.isNotEmpty)
          'queryParameters: {${queryParams.entries.map((entry) => '\'${entry.key}\': ${entry.value}').join(', ')}},',
        'options: ',
        (await builder.type(Lib.dio, 'Options')),
        '(method: \'${this.method}\'),',
        ');\n',
        '\t\treturn ',
        returnType.code,
        '.fromJson(response.data);',
        '\n\t}',
      ]),
    );
  }

  String _buildPath(
      MethodDeclaration method, FunctionDefinitionBuilder builder) {
    RegExp regExp = RegExp(r'\{([a-zA-Z_]\w*)\}');
    // TODO: check if all path params are actually parameters
    // TODO: check if used parameters are url encodable
    // TODO: check if there are not annoated parameters that are no path params

    return path.replaceAllMapped(regExp, (Match match) {
      return '\${${match[1]}}';
    });
  }

  Map<String, String> getQueryParams(
      MethodDeclaration method, FunctionDefinitionBuilder builder) {
    final parameters = [
      ...method.positionalParameters,
      ...method.namedParameters
    ];
    final queryParams = parameters
        .where((param) =>
            param.metadata.any((meta) => _isAnnotationType(meta, 'Query')))
        .associate((param) => _getQueryFromAnnotation(
            param.metadata
                .firstWhere((meta) => _isAnnotationType(meta, 'Query')),
            builder));
    return {
      for (final param in queryParams.keys)
        queryParams[param]?.name ?? param.name: param.name,
    };
  }

  Query _getQueryFromAnnotation(
      MetadataAnnotation meta, FunctionDefinitionBuilder builder) {
    switch (meta) {
      case ConstructorMetadataAnnotation():
        final nameArgument = meta.positionalArguments.firstOrNull;
        if (nameArgument != null) {
          // analyzer crashs if we try to report on meta itself
          // meta.type reports on macro, not sure why, but okay for now
          builder.reportWarning(
            'name argument in ${meta.type.name} is currenctly not support because of lack of inspection api, the parameter name is used instead',
            meta.type.asDiagnosticTarget,
          );
        }
        return Query();
      default:
        throw UnimplementedError();
    }
  }

  bool _isAnnotationType(MetadataAnnotation meta, String type) {
    return switch (meta) {
      ConstructorMetadataAnnotation() => meta.type.name == type,
      _ => false,
    };
  }
}
