

import 'rest_macro.dart';

abstract class HttpMethod {
  final String path;

  const HttpMethod(this.path);  
}

macro class Get extends HttpMethod with RequestMacro {
  const Get(super.path);

}

class Post extends HttpMethod with RequestMacro {
  const Post(super.path);
}

class Put extends HttpMethod with RequestMacro {
  const Put(super.path);
}

class Patch extends HttpMethod with RequestMacro {
  const Patch(super.path);
}

class Delete extends HttpMethod with RequestMacro {
  const Delete(super.path);
}

class Body {
  const Body();
}

class Query {
  final String? name;
  const Query([this.name]);
}

class PathParam {
  final String? name;
  const PathParam([this.name]);
}