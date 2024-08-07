

import 'rest_macro.dart';

abstract class HttpMethod {
  final String path;
  abstract final String method;
  final bool canHaveBody = true;

  const HttpMethod(this.path);  
}

macro class Get extends HttpMethod with RequestMacro {

  const Get(super.path);
  
  @override
  String get method => 'GET';

  @override
  bool get canHaveBody => false;

}

macro class Post extends HttpMethod with RequestMacro {
  const Post(super.path);
  @override
  String get method => 'POST';
}

macro class Put extends HttpMethod with RequestMacro {
  const Put(super.path);
  @override
  String get method => 'PUT';
}

macro class Patch extends HttpMethod with RequestMacro {
  const Patch(super.path);
  @override
  String get method => 'PATCH';
}

macro class Delete extends HttpMethod with RequestMacro {
  const Delete(super.path);
  @override
  String get method => 'DELETE';
}

class Body {
  const Body();
}

/// Use this annotation to mark a field as a body field
/// it gets passed into the json body
/// if [name] is not provided the parameter name is used
/// The parameter type needs to be json serializable
class BodyField {
  final String? name;
  const BodyField([this.name]);
}

class Query {
  final String? name;
  const Query([this.name]);
}