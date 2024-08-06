import 'dart:async';

import 'package:api_client/src/utils/list_extensions.dart';
import 'package:api_client/src/utils/type_extensions.dart';
import 'package:macros/macros.dart';

sealed class HttpMethod implements MethodDefinitionMacro {
  final String path;

  const HttpMethod(this.path);

  @override
  FutureOr<void> buildDefinitionForMethod(MethodDeclaration method, FunctionDefinitionBuilder builder) async {
      final isSerializable = await checkMethodTypesForJsonSerialization(method, builder);
      if(isSerializable) {
        await buildApiMethodImplementation(method, builder);
      }
  }

  Future<bool> checkMethodTypesForJsonSerialization(MethodDeclaration method, FunctionDefinitionBuilder builder) async {
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

  Future<bool> _isJsonDeserializable(TypeAnnotation type, FunctionDefinitionBuilder builder) async {
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

    final returnType = (method.returnType as NamedTypeAnnotation).typeArguments.single; // we know returnType is Future<T>


    builder.augment(FunctionBodyCode.fromParts([
      'async {\n',
      '\t\tfinal response = await dio.get(\'$path\');\n', 
      '\t\treturn ',
      returnType.code,
      '.fromJson(response.data);',
      '\n\t}',
      ]),);
  }
}

macro class Get extends HttpMethod {
  const Get(super.path);

}

class Post extends HttpMethod {
  const Post(super.path);
}

class Put extends HttpMethod {
  const Put(super.path);
}

class Patch extends HttpMethod {
  const Patch(super.path);
}

class Delete extends HttpMethod {
  const Delete(super.path);
}

class Body {
  const Body();
}

class Query {
  final String name;
  const Query(this.name);
}

class PathParam {
  final String? name;
  const PathParam([this.name]);
}