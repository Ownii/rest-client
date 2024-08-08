import 'package:macros/macros.dart';

import 'utils/list_extensions.dart';
import 'utils/type_extensions.dart';

class Validator {
  final DefinitionPhaseIntrospector builder;

  Validator(this.builder);

  bool isFuture(TypeAnnotation type) {
    return type is NamedTypeAnnotation && type.name == 'Future';
  }

  Future<bool> isDeserializable(TypeAnnotation type) async {
    // TODO: can also be a list of json serializable
    // TODO: can also be a map of json serializable

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

    // check if constructor takes Map<String, Object> wh
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

  Future<bool> isSerializable(TypeAnnotation type) async {
    return true;
  }
}
