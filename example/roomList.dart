import 'package:nkust_api/src/webap.dart';

void main() async {
  NkustApi.instance.setProxy("127.0.0.1:8888");
  var res = await NkustApi.instance.apLogin("username", "password");

  if (res.errorCode == 1000) {
    var s = await NkustApi.instance.roomList("1");
    if (s.errorCode >= 2000 && s.errorCode <= 2100) {
      print(s.parseData);
    }
  }
}
