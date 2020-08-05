import 'package:nkust_api/src/webap.dart';

void main() async {
  // NKUST_API.instance.setProxy("127.0.0.1:8888");
  var res = await NKUST_API.instance.apLogin("1106137280", "buluniha");
  print(res.errorCode);
  return;
  if (res.errorCode == 1000) {
    var s = await NKUST_API.instance.scores("109", "1");
    if (s.errorCode >= 2000 && s.errorCode <= 2100) {
      print(s.parseData);
    }
  }
}
