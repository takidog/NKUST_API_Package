import 'package:dio/dio.dart';

class ResponseData {
  int errorCode = 200;
  String errorMessage;
  Map<String, dynamic> parseData;
  Response response;
  ResponseData(
      {this.errorCode, this.errorMessage, this.parseData, this.response});
}
