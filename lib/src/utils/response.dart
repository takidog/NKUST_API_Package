class ResponseData {
  int errorCode = 200;
  String errorMessage;
  Map<String, dynamic> parseData;
  ResponseData({this.errorCode, this.errorMessage, this.parseData});
}
