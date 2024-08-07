import 'package:macros/macros.dart';

import 'libraries.dart';
import 'rest.dart';
import 'utils/builder_extensions.dart';
import 'utils/type_extensions.dart';
import 'validator.dart';

class RestRequestBuilder {
  final FunctionDefinitionBuilder builder;
  final Validator validator;

  bool _valid = true;

  String path;
  String method = 'GET';

  TypeAnnotation? _returnType;
  final Map<String, String> _queryParams = {};
  final List<String> _pathParams = [];

  RestRequestBuilder(this.builder, {required this.path, required this.method})
      : validator = Validator(builder);

  Future<void> withReturnType(TypeAnnotation returnType) async {
    if (!validator.isFuture(returnType)) {
      _reportError(
        'return type of a restful method needs to be a Future',
        returnType.asDiagnosticTarget,
      );
      return;
    }
    final generic =
        (returnType as NamedTypeAnnotation).typeArguments.singleOrNull;

    if (generic == null || !(await validator.isDeserializable(generic))) {
      _reportError(
        'return type `${generic?.name}` is not json serializable',
        (generic ?? returnType).asDiagnosticTarget,
      );
      return;
    }

    _returnType = generic;

    return;
  }

  Future<void> withParameter(
    FormalParameterDeclaration parameter,
  ) async {
    final annotations = parameter.metadata;
    if (annotations.isEmpty) {
      _addPathParameter(parameter);
      return;
    }
    if (annotations.length > 1) {
      _reportError(
        'Only one annotation is allowed',
        parameter.asDiagnosticTarget,
      );
      return;
    }

    final annotation = annotations.first;
    switch (annotation.typeName) {
      case 'Query':
        _addQueryParam(parameter, annotation);
        break;
      case 'Body':
        _addBodyParam(parameter);
        break;

      case 'BodyField':
        _addBodyField(parameter, annotation);
        break;
      default:
        _reportError(
          'Unknown annotation ${annotation.typeName}',
          parameter
              .asDiagnosticTarget, // TODO: cant report on annotation at this moment
        );
    }
    return;
  }

  void _addQueryParam(
    FormalParameterDeclaration parameter,
    MetadataAnnotation annotation,
  ) {
    final queryAnnotation = _getQueryFromAnnotation(annotation);
    _queryParams[queryAnnotation.name ?? parameter.name] = parameter.name;
  }

  Query _getQueryFromAnnotation(MetadataAnnotation meta) {
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

  void _addPathParameter(FormalParameterDeclaration parameter) {
    _pathParams.add(parameter.identifier.name);
    // TODO: check if all path params are actually parameters
    // TODO: check if used parameters are url encodable
    // TODO: check if there are not annoated parameters that are no path params
  }

  void _addBodyParam(FormalParameterDeclaration parameter) {
    // TODO: check if method supports body
    // TODO: check if body serializable
  }

  void _addBodyField(
    FormalParameterDeclaration parameter,
    MetadataAnnotation annotation,
  ) {
    // TODO: check if method supports body
    // TODO: check if body field serializable
  }

  Future<List<Object>?> build() async {
    if (!_valid) return null;

    final path = _buildPath();

    return [
      'async {\n',
      '\t\tfinal response = await dio.request(\'$path\',',
      if (_queryParams.isNotEmpty)
        'queryParameters: {${_queryParams.entries.map((entry) => '\'${entry.key}\': ${entry.value}').join(', ')}},',
      'options: ',
      (await builder.type(Lib.dio, 'Options')),
      '(method: \'$method\'),',
      ');\n',
      if (_returnType != null) ...[
        '\t\treturn ',
        _returnType!.code,
        '.fromJson(response.data);',
      ],
      '\n\t}',
    ];
  }

  String _buildPath() {
    RegExp regExp = RegExp(r'\{([a-zA-Z_]\w*)\}');

    return path.replaceAllMapped(regExp, (Match match) {
      return '\${${match[1]}}';
    });
  }

  void _reportError(String message, DiagnosticTarget target) {
    builder.reportError(message, target);
    _valid = false;
  }
}
