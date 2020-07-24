import 'dart:async';
import 'dart:io';
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';

int apLoginParser(String html) {
  //100 login success
  //101 login fail
  if (html.indexOf(">alert(") < 0) {
    return 100;
  }
  return 101;
}

Map<String, dynamic> apUserInfoParser(String html) {
  Map<String, dynamic> data = new Map();
  var document = parse(html);
  String image_url =
      document.getElementsByTagName("img")[0].attributes["src"].substring(2);
  data['educationSystem'] =
      (document.getElementsByTagName("td")[3].text.replaceAll("學　　制：", ""));
  data['department'] =
      (document.getElementsByTagName("td")[4].text.replaceAll("科　　系：", ""));
  data['className'] =
      (document.getElementsByTagName("td")[8].text.replaceAll("班　　級：", ""));
  data['id'] =
      (document.getElementsByTagName("td")[9].text.replaceAll("學　　號：", ""));
  data['name'] =
      (document.getElementsByTagName("td")[10].text.replaceAll("姓　　名：", ""));
  data['pictureUrl'] = "https://webap.nkust.edu.tw/nkust${image_url}";

  return data;
}

void main() {
  new File('file.txt').readAsString().then((String contents) {
    print(apLoginParser(contents));
  });
}
