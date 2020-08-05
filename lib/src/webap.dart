import 'package:nkust_api/src/utils/session.dart';
//parser
import 'package:nkust_api/src/parser/ap_parser.dart';
//response data type
import 'package:nkust_api/src/utils/response.dart';

import 'package:nkust_api/src/utils/config.dart';

class NKUST_API {
  static NKUST_API _instance;
  static NkustAPIConfig config;
  bool isLogin;

  static NKUST_API get instance {
    if (_instance == null) {
      _instance = NKUST_API();
      config = NkustAPIConfig();
    }
    return _instance;
  }

  void setConfig(NkustAPIConfig customizeConfig) {
    config = customizeConfig;
    Session.instance.timeoutMs = config.timeoutMs;
  }

  Future<ResponseData> apLogin(String username, String password) async {
    /*
    Retrun typoe ResponseData
    errorCode:
    1000   Login succss.
    1001   Login fail.
    5040   Timeout.
    5400   Something error.

    */

    ResponseData res = await Session.instance.post(
        "https://webap.nkust.edu.tw/nkust/perchk.jsp",
        body: {"uid": username, "pwd": password},
        headers: {"content-type": "application/x-www-form-urlencoded"});
    switch (res.errorCode) {
      case 200:
        break;
      case 5040:
        // timeout
        return ResponseData(errorCode: 5040, errorMessage: "Connect timeout.");
        break;
      default:
        return ResponseData(errorCode: 5400, errorMessage: "Something error.");
        break;
    }

    switch (apLoginParser(res.response.body)) {
      //parse login html.
      case 100:
        // login success.
        isLogin = true;
        return ResponseData(errorCode: 1000, errorMessage: "login success.");
      case 101:
        //login fail.
        return ResponseData(errorCode: 1001, errorMessage: "login fial.");
    }
  }

  Future<ResponseData> apQuery(
      String queryQid, Map<String, String> queryData) async {
    /*
    Retrun type ResponseData
    errorCode:
      2000   succss.
      5040   Timeout.
      5400   Something error.

    */
    String url =
        "https://webap.nkust.edu.tw/nkust/${queryQid.substring(0, 2)}_pro/${queryQid}.jsp";

    ResponseData request = await Session.instance.post(url,
        body: queryData,
        headers: {"content-type": "application/x-www-form-urlencoded"});
    if (request.errorCode == 200) {
      return ResponseData(
          errorCode: 2000, errorMessage: "Success", response: request.response);
    }
    switch (request.errorCode) {
      case 5040:
        // timeout
        return ResponseData(errorCode: 5040, errorMessage: "Connect timeout.");
        break;
      default:
        return ResponseData(errorCode: 5400, errorMessage: "Something error.");
        break;
    }
  }

  Future<ResponseData> userInfo() async {
    /*
    Retrun type ResponseData
    errorCode:
    2000   succss.

    5040   Timeout.
    5400   Something error.

    */
    if (this.isLogin == false) {
      return ResponseData(errorCode: 10002, errorMessage: "Need Login.");
    }
    var query = await apQuery("ag003", null);
    if (query.errorCode >= 2000 && query.errorCode < 2100) {
      query.parseData = apUserInfoParser(query.response.body);
      return query;
    }
    return query;
  }

  Future<ResponseData> semesters() async {
    /*
    Retrun type ResponseData
    errorCode:
    2000   succss.

    5040   Timeout.
    5400   Something error.

    */
    if (this.isLogin == false) {
      return ResponseData(errorCode: 10002, errorMessage: "Need Login.");
    }
    var query = await apQuery("ag304_01", null);
    if (query.errorCode >= 2000 && query.errorCode < 2100) {
      query.parseData = semestersParser(query.response.body);
      return query;
    }
    return query;
  }

  Future<ResponseData> scores(String years, String semesterValue) async {
    /*
    Retrun type ResponseData
    errorCode:
    2000   succss.

    5040   Timeout.
    5400   Something error.

    */
    if (this.isLogin == false) {
      return ResponseData(errorCode: 10002, errorMessage: "Need Login.");
    }
    var query =
        await apQuery("ag008", {"arg01": years, "arg02": semesterValue});
    if (query.errorCode >= 2000 && query.errorCode < 2100) {
      query.parseData = scoresParser(query.response.body);
      return query;
    }
    return query;
  }

  Future<ResponseData> coursetable(String years, String semesterValue) async {
    /*
    Retrun type ResponseData
    errorCode:
    2000   succss.

    5040   Timeout.
    5400   Something error.

    */
    if (this.isLogin == false) {
      return ResponseData(errorCode: 10002, errorMessage: "Need Login.");
    }
    var query =
        await apQuery("ag222", {"arg01": years, "arg02": semesterValue});
    if (query.errorCode >= 2000 && query.errorCode < 2100) {
      query.parseData = coursetableParser(query.response.body);
      return query;
    }
    return query;
  }

  Future<ResponseData> midtermAlerts(String years, String semesterValue) async {
    /*
    Retrun type ResponseData
    errorCode:
    2000   succss.

    5040   Timeout.
    5400   Something error.

    */
    if (this.isLogin == false) {
      return ResponseData(errorCode: 10002, errorMessage: "Need Login.");
    }
    var query =
        await apQuery("ag009", {"arg01": years, "arg02": semesterValue});
    if (query.errorCode >= 2000 && query.errorCode < 2100) {
      query.parseData = midtermAlertsParser(query.response.body);
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

    5040   Timeout.
    5400   Something error.

    */
    if (this.isLogin == false) {
      return ResponseData(errorCode: 10002, errorMessage: "Need Login.");
    }
    var query =
        await apQuery("ak010", {"arg01": years, "arg02": semesterValue});
    if (query.errorCode >= 2000 && query.errorCode < 2100) {
      query.parseData = rewardAndPenaltyParser(query.response.body);
      return query;
    }
    return query;
  }

  Future<ResponseData> roomList(String cmpAreaId) async {
    /*
    Retrun type ResponseData
    errorCode:
    2000   succss.


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
      query.parseData = roomListParser(query.response.body);
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

    5040   Timeout.
    5400   Something error.


    */
    if (this.isLogin == false) {
      return ResponseData(errorCode: 10002, errorMessage: "Need Login.");
    }
    var query = await apQuery("ag302_02",
        {"room_id": roomId, "yms_yms": "${years}#${semesterValue}"});
    if (query.errorCode >= 2000 && query.errorCode < 2100) {
      query.parseData = roomCourseTableQueryParser(query.response.body);
      return query;
    }
    return query;
  }
}
