import 'package:http/http.dart' as http;

class ResponseData {
  int errorCode = 200;
  String errorMessage;
  Map<String, dynamic> parseData;
  http.Response response;
  ResponseData(
      {this.errorCode, this.errorMessage, this.parseData, this.response});
}
