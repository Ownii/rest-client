import 'package:api_client/api_client.dart';
import 'package:api_client/src/rest.dart';
import 'package:json/json.dart';

@JsonCodable()
class TestModel {}


// Variant 1

@ApiClient()
class TestApiV1 {
  @Get('/test')
  external Future<TestModel> getTestData();
}

// generated code

augment class TestApiV1 {
  // augment Future<TestModel> getTestData() {
  //   return Future.value(TestModel.fromJson({}));
  // }
}


void main() async {
  final client = TestApiV1();
  final data = await client.getTestData();
  print(data);
}

// Variant 2

@ApiClient()
abstract class TestApiV2 {

  factory TestApiV2() => _TestApiV2();

  Future<TestModel> getTestData();
}

// Generated code


class _TestApiV2 implements TestApiV2 {
  @override
  Future<TestModel> getTestData() {
    return Future.value(TestModel.fromJson({}));
  }
}


void main2() async {
  final client = TestApiV2();
  final data = await client.getTestData();
  print(data);
}
