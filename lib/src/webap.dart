//dio
import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
//overwrite origin Cookie Manager.
import 'package:NKUST_API_Package/src/utils/privateCookieManager.dart';
//parser
import 'package:NKUST_API_Package/src/parser/apParser.dart';
//response data type
import 'package:NKUST_API_Package/src/utils/response.dart';

class NKUST_API {
  static Dio dio;
  static NKUST_API _instance;
  static CookieJar cookieJar;
  bool isLogin;

  static NKUST_API get instance {
    if (_instance == null) {
      _instance = NKUST_API();
      dio = Dio();
      cookieJar = CookieJar();
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

  static dioInit() {
    // Use PrivateCookieManager to overwrite origin CookieManager, because
    // Cookie name of the NKUST ap system not follow the RFC6265. :(
    dio.interceptors.add(PrivateCookieManager(cookieJar));
    dio.options.headers['user-agent'] =
        'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/84.0.4147.89 Safari/537.36';
  }

  Future<ResponseData> apLogin(String username, String password) async {
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
    try {
      Response res = await dio.post(
          "https://webap.nkust.edu.tw/nkust/perchk.jsp",
          data: {"uid": username, "pwd": password},
          options: Options(contentType: Headers.formUrlEncodedContentType));
      if (res.statusCode != 200) {
        return ResponseData(errorCode: 5001);
      }
      switch (apLoginParser(res.data)) {
        //parse login html.
        case 100:
          // login success.
          isLogin = true;
          return ResponseData(errorCode: 1000, errorMessage: "login success.");
        case 101:
          //login fail.
          return ResponseData(errorCode: 1001, errorMessage: "login fial.");
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

  Future<Response> apQuery(
      String queryQid, Map<String, String> queryData) async {
    String url =
        "http://webap.nkust.edu.tw/nkust/${queryQid.substring(0, 2)}_pro/${queryQid}.jsp";
    return await dio.post(url,
        data: queryData,
        options: Options(contentType: Headers.formUrlEncodedContentType));
  }
}
