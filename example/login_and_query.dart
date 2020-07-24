import 'package:NKUST_API_Package/src/webap.dart';

void main() async {
  NKUST_API.instance.setProxy("127.0.0.1:8888");
  var res = await NKUST_API.instance.apLogin("guest", "123");
  print(res.errorCode);
  print(res.errorMessage);
  if (res.errorCode == 1000) {
    // get raw html from apQuery.
    // ag008 is score.
    var s = await NKUST_API.instance
        .apQuery("ag008", {"arg01": "108", "arg02": "1"});
    print(s.data);
  }
}
