import 'dart:async';

import 'package:macros/macros.dart';

macro class ApiClient implements ClassDefinitionMacro {

  const ApiClient();

  @override
  FutureOr<void> buildDefinitionForClass(ClassDeclaration clazz, TypeDefinitionBuilder builder) {
  }
}
