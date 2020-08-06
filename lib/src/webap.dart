//dio
import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
//overwrite origin Cookie Manager.
import 'package:nkust_api/src/utils/private_cookie_manager.dart';
//parser
import 'package:nkust_api/src/parser/ap_parser.dart';
//response data type
import 'package:nkust_api/src/utils/response.dart';

import 'package:nkust_api/src/utils/config.dart';

class NkustApi {
  static Dio dio;
  static NkustApi _instance;
  static CookieJar cookieJar;
  static NkustAPIConfig config;
  bool isLogin;

  static NkustApi get instance {
    if (_instance == null) {
      _instance = NkustApi();
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
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/84.0.4147.89 Safari/537.36';
    dio.options.headers['Connection'] = 'close';
    dio.options.connectTimeout = config.dioTimeoutMs;
    dio.options.receiveTimeout = config.dioTimeoutMs;
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

  Future<ResponseData> apQuery(
      String queryQid, Map<String, String> queryData) async {
    /*
    Retrun type ResponseData
    errorCode:
      2000   succss.
      5000   NKUST server error.
      5002   Dio error, maybe NKUST server error.
      5040   Timeout.
      5400   Something error.

    */
    String url =
        "https://webap.nkust.edu.tw/nkust/${queryQid.substring(0, 2)}_pro/${queryQid}.jsp";
    try {
      Response request = await dio.post(url,
          data: queryData,
          options: Options(contentType: Headers.formUrlEncodedContentType));
      if (request.statusCode == 200) {
        return ResponseData(
            errorCode: 2000, errorMessage: "Success", response: request);
      }
      ;
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

  Future<ResponseData> userInfo() async {
    /*
    Retrun type ResponseData
    errorCode:
    2000   succss.

    5000   NKUST server error.
    5002   Dio error, maybe NKUST server error.
    5040   Timeout.
    5400   Something error.

    */
    if (this.isLogin == false) {
      return ResponseData(errorCode: 10002, errorMessage: "Need Login.");
    }
    var query = await apQuery("ag003", null);
    if (query.errorCode >= 2000 && query.errorCode < 2100) {
      query.parseData = apUserInfoParser(query.response.data);
      return query;
    }
    return query;
  }

  Future<ResponseData> semesters() async {
    /*
    Retrun type ResponseData
    errorCode:
    2000   succss.

    5000   NKUST server error.
    5002   Dio error, maybe NKUST server error.
    5040   Timeout.
    5400   Something error.

    */
    if (this.isLogin == false) {
      return ResponseData(errorCode: 10002, errorMessage: "Need Login.");
    }
    var query = await apQuery("ag304_01", null);
    if (query.errorCode >= 2000 && query.errorCode < 2100) {
      query.parseData = semestersParser(query.response.data);
      return query;
    }
    return query;
  }

  Future<ResponseData> scores(String years, String semesterValue) async {
    /*
    Retrun type ResponseData
    errorCode:
    2000   succss.

    5000   NKUST server error.
    5002   Dio error, maybe NKUST server error.
    5040   Timeout.
    5400   Something error.

    */
    if (this.isLogin == false) {
      return ResponseData(errorCode: 10002, errorMessage: "Need Login.");
    }
    var query =
        await apQuery("ag008", {"arg01": years, "arg02": semesterValue});
    if (query.errorCode >= 2000 && query.errorCode < 2100) {
      query.parseData = scoresParser(query.response.data);
      return query;
    }
    return query;
  }

  Future<ResponseData> coursetable(String years, String semesterValue) async {
    /*
    Retrun type ResponseData
    errorCode:
    2000   succss.

    5000   NKUST server error.
    5002   Dio error, maybe NKUST server error.
    5040   Timeout.
    5400   Something error.

    */
    if (this.isLogin == false) {
      return ResponseData(errorCode: 10002, errorMessage: "Need Login.");
    }
    var query =
        await apQuery("ag222", {"arg01": years, "arg02": semesterValue});
    if (query.errorCode >= 2000 && query.errorCode < 2100) {
      query.parseData = coursetableParser(query.response.data);
      return query;
    }
    return query;
  }

  Future<ResponseData> midtermAlerts(String years, String semesterValue) async {
    /*
    Retrun type ResponseData
    errorCode:
    2000   succss.

    5000   NKUST server error.
    5002   Dio error, maybe NKUST server error.
    5040   Timeout.
    5400   Something error.

    */
    if (this.isLogin == false) {
      return ResponseData(errorCode: 10002, errorMessage: "Need Login.");
    }
    var query =
        await apQuery("ag009", {"arg01": years, "arg02": semesterValue});
    if (query.errorCode >= 2000 && query.errorCode < 2100) {
      query.parseData = midtermAlertsParser(query.response.data);
      return query;
    }
    return query;
  }

  Future<ResponseData> rewardAndPenalty(
      String years, String semesterValue) async {
    /*
    Retrun type ResponseData
    errorCode:
    2000   succss.

    5000   NKUST server error.
    5002   Dio error, maybe NKUST server error.
    5040   Timeout.
    5400   Something error.

    */
    if (this.isLogin == false) {
      return ResponseData(errorCode: 10002, errorMessage: "Need Login.");
    }
    var query =
        await apQuery("ak010", {"arg01": years, "arg02": semesterValue});
    if (query.errorCode >= 2000 && query.errorCode < 2100) {
      query.parseData = rewardAndPenaltyParser(query.response.data);
      return query;
    }
    return query;
  }

  Future<ResponseData> roomList(String cmpAreaId) async {
    /*
    Retrun type ResponseData
    errorCode:
    2000   succss.

    5000   NKUST server error.
    5002   Dio error, maybe NKUST server error.
    5040   Timeout.
    5400   Something error.

    cmpAreaId
    1=建工/2=燕巢/3=第一/4=楠梓/5=旗津
    */
    if (this.isLogin == false) {
      return ResponseData(errorCode: 10002, errorMessage: "Need Login.");
    }
    var query = await apQuery("ag302_01", {"cmp_area_id": cmpAreaId});
    if (query.errorCode >= 2000 && query.errorCode < 2100) {
      query.parseData = roomListParser(query.response.data);
      return query;
    }
    return query;
  }

  Future<ResponseData> roomCourseTableQuery(
      String roomId, String years, String semesterValue) async {
    /*
    Retrun type ResponseData
    errorCode:
    2000   succss.

    5000   NKUST server error.
    5002   Dio error, maybe NKUST server error.
    5040   Timeout.
    5400   Something error.


    */
    if (this.isLogin == false) {
      return ResponseData(errorCode: 10002, errorMessage: "Need Login.");
    }
    var query = await apQuery("ag302_02",
        {"room_id": roomId, "yms_yms": "${years}#${semesterValue}"});
    if (query.errorCode >= 2000 && query.errorCode < 2100) {
      query.parseData = roomCourseTableQueryParser(query.response.data);
      return query;
    }
    return query;
  }
}
