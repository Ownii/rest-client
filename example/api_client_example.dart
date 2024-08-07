import 'package:api_client/api_client.dart';
import 'package:api_client/src/rest.dart';
import 'package:json/json.dart';
// ignore: unused_import // sometimes the import in the augemented code fails, TODO: check why
import 'package:dio/dio.dart';

@JsonCodable()
class TestModel {}

@ApiClient()
class TestApiV1 {
  @Get('/test')
  external Future<TestModel> getTestData(@Query() String id);

  @Get('/test/{id}')
  external Future<TestModel> getTestDataWithPathParam(String id);

  @Post('/test')
  external Future<TestModel> postTestData(@Body() TestModel data);

  @Put('/test')
  external Future<TestModel> putTestData(@BodyField() String value);
}

void main() async {
  final client = TestApiV1();
  final data = await client.getTestData('123');
  print(data);
}
