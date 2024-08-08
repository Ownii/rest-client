// ignore_for_file: prefer_relative_imports, require_trailing_commas

import 'dart:async';

import 'package:rest_client/src/rest.dart';
import 'package:macros/macros.dart';

import 'rest_request_builder.dart';

mixin RequestMacro on HttpMethod implements MethodDefinitionMacro {
  @override
  FutureOr<void> buildDefinitionForMethod(
      MethodDeclaration method, FunctionDefinitionBuilder builder) async {
    final requestBuilder =
        RestRequestBuilder(builder, path: path, method: this);
    await requestBuilder.withReturnType(method.returnType);

    for (var param in [
      ...method.positionalParameters,
      ...method.namedParameters
    ]) {
      await requestBuilder.withParameter(param);
    }

    final request = await requestBuilder.build();
    if (request != null) {
      builder.augment(FunctionBodyCode.fromParts(request));
    }
  }
}
