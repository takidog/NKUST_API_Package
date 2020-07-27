//dio
import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
//overwrite origin Cookie Manager.
import 'package:nkust_api/src/utils/private_cookie_manager.dart';
//response data type
import 'package:nkust_api/src/utils/response.dart';

import 'package:nkust_api/src/utils/config.dart';

import 'dart:convert';
import 'package:crypto/crypto.dart';

String generateMd5(String input) {
  return md5.convert(utf8.encode(input)).toString();
}

class BusEncrypt {
  //0 is from first, 1 is from last.
  static int seedDirection;

  static String seedValue;

  BusEncrypt({String jsCode}) {
    jsEncryptCodeParser(jsCode);
  }

  void jsEncryptCodeParser(String content) {
    // http://bus.kuas.edu.tw/API/Scripts/a1
    RegExp seedFromFirstRegex = new RegExp(r"encA2\('((\d|\w){0,32})'");
    RegExp seedFromLastRegex =
        new RegExp(r"encA2\(e(\w|\d|\s|\W){0,3}'((\d|\w){0,32})'\)");

    var firstMatches = seedFromFirstRegex.allMatches(content);
    var lastMatches = seedFromLastRegex.allMatches(content);
    String seedFromFirst;
    String seedFromLast;

    if (firstMatches.length > 0) {
      seedFromFirst = firstMatches.toList()[firstMatches.length - 1].group(1);
    }
    if (lastMatches.length > 0) {
      seedFromLast = lastMatches.toList()[lastMatches.length - 1].group(2);
    }
    findEndString(content, seedFromFirst);
    if (findEndString(content, seedFromFirst) >
        findEndString(content, seedFromLast)) {
      seedDirection = 0;
      seedValue = seedFromFirst;
      return;
    }
    seedDirection = 1;
    seedValue = seedFromLast;
  }

  String encA1(String value) {
    if (seedDirection == null || seedValue == null) {
      throw Exception("Seed get error");
    }
    if (seedDirection == 0) {
      return generateMd5("${seedValue}${value}");
    }
    return generateMd5("${value}${seedValue}");
  }

  String loginEncrypt(String username, String password) {
    var g = "419191959";
    var i = "930672927";
    var j = "1088434686";
    var k = "260123741";

    g = generateMd5("J${g}");
    i = generateMd5("E${i}");
    j = generateMd5("R${j}");
    k = generateMd5("Y${k}");
    username = generateMd5(username + encA1(g));
    password = generateMd5(username + password + "JERRY" + encA1(i));

    var l = generateMd5(username + password + "KUAS" + encA1(j));
    l = generateMd5(l + username + encA1("ITALAB") + encA1(k));
    l = generateMd5(l + password + "MIS" + k);

    return json.encode({"a": l, "b": g, "c": i, "d": j, "e": k, "f": password});
  }

  int findEndString(String content, String targetString) {
    if (targetString == null) {
      return -1;
    }
    int index = -1;
    int res = 0;
    while (res != -1) {
      res = content.indexOf(targetString, res);
      if (res != -1) {
        index = res;
        res += 1;
      }
    }
    return index;
  }
}

class NKUST_Bus_API {
  static Dio dio;
  static NKUST_Bus_API _instance;
  static CookieJar cookieJar;
  static NkustAPIConfig config;
  bool isLogin;
  static BusEncrypt busEncryptObject;
  static String busHost = "http://bus.kuas.edu.tw/";

  static NKUST_Bus_API get instance {
    if (_instance == null) {
      _instance = NKUST_Bus_API();
      dio = Dio();
      cookieJar = CookieJar();
      config = NkustAPIConfig();
      dioInit();
    }
    return _instance;
  }

  void setProxy(String proxyIP) {
    (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
        (client) {
      client.findProxy = (uri) {
        return "PROXY " + proxyIP;
      };
    };
  }

  void setConfig(NkustAPIConfig customizeConfig) {
    config = customizeConfig;
  }

  static dioInit() {
    // Use PrivateCookieManager to overwrite origin CookieManager, because
    // Cookie name of the NKUST ap system not follow the RFC6265. :(
    dio.interceptors.add(PrivateCookieManager(cookieJar));
    dio.options.headers['user-agent'] =
        'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/84.0.4147.89 Safari/537.36';
    dio.options.connectTimeout = config.dioTimeoutMs;
    dio.options.receiveTimeout = config.dioTimeoutMs;
  }

  void loginPrepare() async {
    // Get global cookie. Only cookies get from the root directory can be used.
    await dio.head(busHost);
    // This function will download encrypt js bus login required.
    var res = await dio.get("http://bus.kuas.edu.tw/API/Scripts/a1");
    busEncryptObject = new BusEncrypt(jsCode: res.data);
  }

  Future<ResponseData> busLogin(String username, String password) async {
    /*
    Retrun typoe ResponseData
    errorCode:
    1000   Login succss.
    1001   Login fail.
    5000   NKUST server error.
    5002   Dio error, maybe NKUST server error.
    5040   Timeout.
    5400   Something error.

    (Not used)
    5041   Client side timeout. 
    5042   Server side timeout.
    */
    if (busEncryptObject == null) {
      await loginPrepare();
    }
    try {
      Response res = await dio.post("${busHost}API/Users/login",
          data: {
            "account": username,
            "password": password,
            "n": busEncryptObject.loginEncrypt(username, password)
          },
          options: Options(contentType: Headers.formUrlEncodedContentType));
      if (res.statusCode != 200) {
        return ResponseData(errorCode: 5001);
      }
      var reqJson = json.decode(res.data);
      if (reqJson['status'] == true && reqJson['code'] == 200) {
        return ResponseData(errorCode: 2001, parseData: reqJson);
      }
      if (reqJson['code'] == 400) {
        return ResponseData(errorCode: 4001, parseData: reqJson);
      }
      if (reqJson['code'] == 302) {
        return ResponseData(errorCode: 4002, parseData: reqJson);
      }
    } on DioError catch (e) {
      if (e.type == DioErrorType.CONNECT_TIMEOUT ||
          e.type == DioErrorType.RECEIVE_TIMEOUT) {
        return ResponseData(errorCode: 5040, errorMessage: "Connect timeout.");
      }
      if (e.type == DioErrorType.RESPONSE) {
        if (e.response.statusCode != 200) {
          return ResponseData(
              errorCode: 5000,
              errorMessage: "NKUST Server have something wrong.");
        }
      }
      return ResponseData(
          errorCode: 5002, errorMessage: "Dio error or NKUST Server error :(");
    } on Exception catch (e) {}
    return ResponseData(errorCode: 5400, errorMessage: "Something error.");
  }
}

void main() async {
  NKUST_Bus_API.instance.setProxy("127.0.0.1:8888");
  var res = await NKUST_Bus_API.instance.busLogin("___", "____");
}
