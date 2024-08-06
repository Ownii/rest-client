import 'dart:async';

import 'package:api_client/src/utils/list_extensions.dart';
import 'package:macros/macros.dart';

macro class ApiClient implements ClassDefinitionMacro {

  const ApiClient();

  @override
  FutureOr<void> buildDefinitionForClass(ClassDeclaration clazz, TypeDefinitionBuilder builder) async {
    final methods = await builder.methodsOf(clazz);
    for(final method in methods) {
      final isSerializable = await checkMethodTypesForJsonSerialization(method, builder);
      if(isSerializable) {
        await buildApiMethodImplementation(method, await builder.buildMethod(method.identifier));
      }

    }
    // final firstMethod = methods.firstOrNull;
    // if( firstMethod == null) return;
    // final returnType = firstMethod.returnType;
    // final methodBuilder = await builder.buildMethod(firstMethod.identifier);
    // final dartFuture = Uri.parse('dart:async');
    // final dartCode = Uri.parse('dart:core');
    // final futureType = await builder.resolveIdentifier(dartFuture, 'Future');
    // final futureCode = NamedTypeAnnotationCode(name: futureType);
    // final exceptionType = await builder.resolveIdentifier(dartCode, 'Exception');
    // final exceptionCode = NamedTypeAnnotationCode(name: exceptionType);
    // methodBuilder.augment(FunctionBodyCode.fromParts([
    //   'async {\n  return ', 
    //   futureCode,
    //   '.error(', 
    //   exceptionCode, 
    //   '("Not implemented yet"));\n}'
    //   ]));
    // builder.report(Diagnostic(DiagnosticMessage('return type `TestModel` is not json serializable', target: returnType.asDiagnosticTarget), Severity.error));
  }

  Future<bool> checkMethodTypesForJsonSerialization(MethodDeclaration method, TypeDefinitionBuilder builder) async {
    var isValid = true;
    if( !_isFuture(method.returnType) ) {
      builder.report(Diagnostic(DiagnosticMessage('return type of a restful method needs to be a Future', target: method.returnType.asDiagnosticTarget), Severity.error));
      isValid = false;
    }
    else {
      final genericType = (method.returnType as NamedTypeAnnotation).typeArguments.singleOrNull;

      if( genericType == null || !(await _isJsonDeserializable(genericType, builder)) ) {
        builder.report(Diagnostic(DiagnosticMessage('return type `${genericType?.name}` is not json serializable', target: (genericType ?? method.returnType).asDiagnosticTarget), Severity.error));
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

  Future<bool> _isJsonDeserializable(TypeAnnotation type, TypeDefinitionBuilder builder) async {
    // get fromJson constructor
    final namedType = type as NamedTypeAnnotation;
    final typeDeclaration = await builder.typeDeclarationOf(namedType.identifier);
    final constructors = await builder.constructorsOf(typeDeclaration);
    final fromJson = constructors.firstWhereOrNull((method) => method.identifier.name == 'fromJson');
    if( fromJson == null) {
      return false;
    }

    // check if constructor takes Map<String, Object>
    final jsonParam = fromJson.positionalParameters.singleOrNull;
    if( jsonParam == null || jsonParam.type.name != 'Map' ) {
      return false;
    }

    final mapTypes = (jsonParam.type as NamedTypeAnnotation).typeArguments;
    if( mapTypes.length != 2 || mapTypes.firstOrNull?.name != 'String' || mapTypes.lastOrNull?.name != 'Object' ) {
      return false;
    }

    return true;
  }
  bool _isFuture(TypeAnnotation type) {
    return type is NamedTypeAnnotation && type.identifier.name == 'Future';
  }
  Future<void> buildApiMethodImplementation(MethodDeclaration method, FunctionDefinitionBuilder builder) async {

    final future = builder.type('dart:async', 'Future');

    final returnType = (method.returnType as NamedTypeAnnotation).typeArguments.single; // we know returnType is Future<T>

    builder.augment(FunctionBodyCode.fromParts([
      'async {\n  return ', 
      future,
      '.value(', 
      returnType.code,
      '.fromJson({}));\n}',
      ]),);
  }

}

extension _TypeAnnotationX on TypeAnnotation {

  String get name {
    if (this is NamedTypeAnnotation) return (this as NamedTypeAnnotation).identifier.name;
    return 'unknown type';
  } 

}

extension _TypePhaseIntrospectorX on TypePhaseIntrospector {
  Future<NamedTypeAnnotationCode> type(String library, String name) async {
    final type = await resolveIdentifier(Uri.parse(library), name);
    return NamedTypeAnnotationCode(name: type);
  }
}
