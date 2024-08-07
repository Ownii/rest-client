enum Lib {
  async('dart:async'),
  core('dart:core'),
  dio('package:dio/dio.dart');

  const Lib(this._path);

  final String _path;

  Uri get uri {
    return Uri.parse(_path);
  }
}
