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
  Map<String, dynamic> data = {
    "educationSystem": null,
    "department": null,
    "className": null,
    "id": null,
    "name": null,
    "pictureUrl": null
  };
  var document = parse(html);
  var tdElements = document.getElementsByTagName("td");
  if (tdElements.length < 15) {
    // parse data error.
    return data;
  }
  String image_url =
      document.getElementsByTagName("img")[0].attributes["src"].substring(2);
  data['educationSystem'] = (tdElements[3].text.replaceAll("學　　制：", ""));
  data['department'] = (tdElements[4].text.replaceAll("科　　系：", ""));
  data['className'] = (tdElements[8].text.replaceAll("班　　級：", ""));
  data['id'] = (tdElements[9].text.replaceAll("學　　號：", ""));
  data['name'] = (tdElements[10].text.replaceAll("姓　　名：", ""));
  data['pictureUrl'] = "https://webap.nkust.edu.tw/nkust${image_url}";

  return data;
}

Map<String, dynamic> semestersParser(String html) {
  Map<String, dynamic> data = {
    "data": [],
    "default": {"year": "108", "value": "2", "text": "108學年第二學期(Parse失敗)"}
  };
  var document = parse(html);

  var ymsElements =
      document.getElementById("yms_yms").getElementsByTagName("option");
  if (ymsElements.length < 30) {
    //parse fail.
    return data;
  }
  for (int i = 0; i < ymsElements.length; i++) {
    data['data'].add({
      "year": ymsElements[i].attributes["value"].split("#")[0],
      "value": ymsElements[i].attributes["value"].split("#")[1],
      "text": ymsElements[i].text
    });
    if (ymsElements[i].attributes["selected"] != null) {
      //set default
      data['default'] = {
        "year": ymsElements[i].attributes["value"].split("#")[0],
        "value": ymsElements[i].attributes["value"].split("#")[1],
        "text": ymsElements[i].text
      };
    }
  }
  return data;
}

void main() {
  new File('file.txt').readAsString().then((String contents) {
    print(apLoginParser(contents));
  });
}
