import 'package:api_client/api_client.dart';
import 'package:api_client/src/rest.dart';
import 'package:json/json.dart';

@JsonCodable()
class TestModel {}

@ApiClient()
class TestApiV1 {
  @Get('/test')
  external Future<TestModel> getTestData();
}

void main() async {
  final client = TestApiV1();
  final data = await client.getTestData();
  print(data);
}
