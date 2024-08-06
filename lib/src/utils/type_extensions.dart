import 'package:macros/macros.dart';

extension TypeAnnotationX on TypeAnnotation {
  String get name {
    if (this is NamedTypeAnnotation) {
      return (this as NamedTypeAnnotation).identifier.name;
    }
    return 'unknown type';
  }
}

extension TypePhaseIntrospectorX on TypePhaseIntrospector {
  Future<NamedTypeAnnotationCode> type(String library, String name) async {
    final type = await resolveIdentifier(Uri.parse(library), name);
    return NamedTypeAnnotationCode(name: type);
  }
}
