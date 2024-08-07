import 'package:macros/macros.dart';

import '../libraries.dart';

extension TypeAnnotationX on TypeAnnotation {
  String get name {
    if (this is NamedTypeAnnotation) {
      return (this as NamedTypeAnnotation).identifier.name;
    }
    return 'unknown type';
  }
}

extension TypePhaseIntrospectorX on TypePhaseIntrospector {
  Future<NamedTypeAnnotationCode> type(Lib library, String name) async {
    final type = await resolveIdentifier(library.uri, name);
    return NamedTypeAnnotationCode(name: type);
  }
}
