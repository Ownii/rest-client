class Get {
  final String path;
  const Get(this.path);
}

class Post {
  final String path;
  const Post(this.path);
}

class Put {
  final String path;
  const Put(this.path);
}

class Patch {
  final String path;
  const Patch(this.path);
}

class Delete {
  final String path;
  const Delete(this.path);
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
