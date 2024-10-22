// ignore_for_file: prefer_relative_imports

import 'dart:async';

import 'package:api_client/src/utils/type_extensions.dart';
import 'package:macros/macros.dart';

import 'libraries.dart';

macro class ApiClient implements ClassDeclarationsMacro {

  final String? baseUrl;

  const ApiClient({this.baseUrl});

  @override
  FutureOr<void> buildDeclarationsForClass(ClassDeclaration clazz, MemberDeclarationBuilder builder) async {
    // TODO: check if dio is already declared
   await _declareDio(builder);
  }

  Future<void> _declareDio(MemberDeclarationBuilder builder) async {
    final dio = await builder.type(Lib.dio, 'Dio');
    final baseOptions = await builder.type(Lib.dio, 'BaseOptions');
    builder.declareInType(DeclarationCode.fromParts([
      '\tfinal dio = ',
      dio,
      '(',
      if(baseUrl != null)
      ...[
        baseOptions, 
        '(baseUrl: \'$baseUrl\')',
      ],
      ');\n',
      ],),);
  }

}

