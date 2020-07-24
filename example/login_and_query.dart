import 'package:NKUST_API_Package/src/webap.dart';

void main() async {
  NKUST_API.instance.setProxy("127.0.0.1:8888");
  var res = await NKUST_API.instance.apLogin("guest", "123");
  print(res.errorCode);
  print(res.errorMessage);
}
