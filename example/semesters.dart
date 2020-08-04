import 'package:nkust_api/src/webap.dart';

void main() async {
  NKUST_API.instance.setProxy("127.0.0.1:8888");

  var res = await NKUST_API.instance.apLogin("username", "password");

  if (res.errorCode == 1000) {
    var s = await NKUST_API.instance.semesters();
    if (s.errorCode >= 2000 && s.errorCode <= 2100 && s.parseData != null) {
      print(s.parseData);
    }
  }
}
