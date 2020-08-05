import 'dart:async';

import 'package:nkust_api/src/utils/response.dart';
import 'package:nkust_api/src/utils/tool.dart';
import 'package:http/http.dart' as http;

class NkustApClient extends http.BaseClient {
  final http.Client _inner;

  Map<String, String> cookie = {};
  NkustApClient(this._inner);

  // basic cookie handle, only key and value.
  handleCookie(Map<String, String> headers) {
    headers.forEach((key, value) {
      if (key == "set-cookie") {
        value.split(",").forEach((element) {
          if (element.split(";")[0].indexOf(" ") == -1) {
            this.cookie.addAll({
              element.substring(0, element.split(";")[0].indexOf("=")):
                  element.substring(element.split(";")[0].indexOf("=") + 1,
                      element.indexOf(";"))
            });
          }
        });
      }
    });
  }

  String cookieString() {
    String _temp = "";
    this.cookie.forEach((key, value) {
      if (_temp != "") {
        _temp += "; ";
      }
      _temp += "${key}=${value}";
    });
    return _temp;
  }

  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Connection'] = "close";
    request.headers['user-agent'] =
        'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/84.0.4147.89 Safari/537.36';

    if (cookieString() != "") {
      request.headers['cookie'] = cookieString();
    }

    return _inner.send(request);
  }
}

class Session {
  static Session _instance;
  static NkustApClient httpRequest;
  int timeoutMs = 5500;

  static Session get instance {
    if (_instance == null) {
      _instance = Session();
      httpRequest = NkustApClient(http.Client());
    }
    return _instance;
  }

  Future<ResponseData> post(String url,
      {Map<String, String> body, Map<String, String> headers}) async {
    try {
      http.Response res = await httpRequest
          .post(url, body: formDataAndEncode(body), headers: headers)
          .timeout(Duration(milliseconds: timeoutMs));
      httpRequest.handleCookie(res.headers);
      if (res.statusCode == 200) {
        return ResponseData(errorCode: 200, response: res);
      }

      return ResponseData(errorCode: 0, response: res);
    } catch (e) {
      print(e);
      if (e.runtimeType == TimeoutException) {
        return ResponseData(errorCode: 5040);
      }
      return ResponseData(errorCode: 5400);
    }
  }
}
