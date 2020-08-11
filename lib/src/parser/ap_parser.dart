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

Map<String, dynamic> scoresParser(String html) {
  var document = parse(html);

  Map<String, dynamic> data = {
    "scores": [],
    "detail": {
      "conduct": null,
      "classRank": null,
      "departmentRank": null,
      'average': null
    }
  };
  //detail part
  try {
    RegExp exp = new RegExp(r".{0,4}：([0-9./]{0,})");
    var matches = exp.allMatches(document
        .getElementsByTagName('caption')[0]
        .getElementsByTagName("div")[0]
        .text);
    data['detail'] = {
      "conduct": double.parse(matches.elementAt(0).group(1)),
      "classRank": matches.elementAt(2).group(1),
      "departmentRank": matches.elementAt(3).group(1),
      "average": (matches.elementAt(1).group(1) != "")
          ? double.parse(matches.elementAt(1).group(1))
          : 0.0
    };
  } on Exception catch (e) {}
  //scores part

  try {
    var table =
        document.getElementsByTagName("table")[1].getElementsByTagName("tr");
    for (int scoresIndex = 1; scoresIndex < table.length; scoresIndex++) {
      var td = table[scoresIndex].getElementsByTagName('td');
      data['scores'].add({
        "title": td[1].text,
        'units': td[2].text,
        'hours': td[3].text,
        'required': td[4].text,
        'at': td[5].text,
        'middleScore': td[6].text,
        'finalScore': td[7].text,
        'remark': td[8].text,
      });
    }
  } on Exception catch (e) {}

  return data;
}

Map<String, dynamic> coursetableParser(String html) {
  Map<String, dynamic> data = {
    "courses": [],
    "coursetable": {
      "timeCodes": [],
      "Monday": [],
      "Tuesday": [],
      "Wednesday": [],
      "Thursday": [],
      "Friday": [],
      "Saturday": [],
      "Sunday": []
    }
  };
  var document = parse(html);

  if (document.getElementsByTagName("table").length == 0) {
    //table not found
    return data;
  }
  try {
    //the top table parse
    var topTable =
        document.getElementsByTagName("table")[0].getElementsByTagName("tr");
    for (int i = 1; i < topTable.length; i++) {
      var td = topTable[i].getElementsByTagName('td');
      data['courses'].add({
        'code': td[0].text,
        'title': td[1].text,
        'className': td[2].text,
        'group': td[3].text,
        'units': td[4].text,
        'hours': td[5].text,
        'required': td[6].text,
        'at': td[7].text,
        'times': td[8].text,
        "instructors": td[9].text.split(","),
        'location': {'room': td[10].text}
      });
    }
  } on Exception catch (e) {} on RangeError catch (r) {}

  //the second talbe.

  //make timetable
  var secondTable =
      document.getElementsByTagName("table")[1].getElementsByTagName("tr");
  try {
    //remark:Best split is regex but... Chinese have some difficulty Q_Q
    for (int i = 1; i < secondTable.length; i++) {
      var _temptext =
          secondTable[i].getElementsByTagName('td')[0].text.replaceAll(" ", "");

      data['coursetable']['timeCodes'].add(_temptext
          .substring(0, _temptext.length - 10)
          .replaceAll(String.fromCharCode(160), ""));
    }
  } on Exception catch (e) {}
  //make each day.
  List keyName = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];
  ;

  try {
    for (int key = 0; key < keyName.length; key++) {
      for (int eachSession = 1;
          eachSession < data['coursetable']['timeCodes'].length;
          eachSession++) {
        var eachDays = document
            .getElementsByTagName("table")[1]
            .getElementsByTagName("tr")[eachSession]
            .getElementsByTagName("td")[key + 1];
        var splitData = (eachDays.outerHtml
            .substring(35, eachDays.outerHtml.length - 11)
            .split("<br>"));

        var _eachDaysDate = document
            .getElementsByTagName("table")[1]
            .getElementsByTagName("tr")[eachSession]
            .getElementsByTagName("td")[0]
            .outerHtml;
        var courseTime = _eachDaysDate
            .substring(_eachDaysDate.indexOf("&nbsp;<br>") + 10,
                _eachDaysDate.indexOf("<br>&nbsp;<"))
            .split("<br>");

        if (splitData.length <= 1) {
          continue;
        }
        String title = splitData[0];
        if (title.indexOf(">") > -1) {
          title = title.substring(title.indexOf(">") + 1, title.length);
        }
        data['coursetable'][keyName[key]].add({
          'title': title,
          'date': {
            "startTime": courseTime[1].split('-')[0],
            "endTime": courseTime[1].split('-')[1],
            'section': courseTime[0]
                .replaceAll(" ", "")
                .replaceAll(String.fromCharCode(160), "")
          },
          'location': {"room": splitData[2]},
          'instructors': splitData[1].split(","),
        });
      }
    }
  } on Exception catch (e) {}
  return data;
}

Map<String, dynamic> midtermAlertsParser(String html) {
  Map<String, dynamic> data = {"courses": []};

  var document = parse(html);
  if (document.getElementsByTagName("table").length < 2) {
    return data;
  }
  var table =
      document.getElementsByTagName("table")[1].getElementsByTagName("tr");
  try {
    for (int i = 1; i < table.length; i++) {
      var tdData = table[i].getElementsByTagName("td");
      if (tdData.length < 5) {
        continue;
      }
      if (tdData[5].text[0] == "是") {
        data["courses"].add({
          "entry": tdData[0].text,
          "className": tdData[1].text,
          "title": tdData[2].text,
          "group": tdData[3].text,
          "instructors": tdData[4].text,
          "reason": tdData[6].text,
          "remark": tdData[7].text
        });
      }
    }
  } on Exception catch (e) {
    print(e);
  }
  return data;
}

Map<String, dynamic> rewardAndPenaltyParser(String html) {
  Map<String, dynamic> data = {"data": []};

  var document = parse(html);
  if (document.getElementsByTagName("table").length < 2) {
    return data;
  }
  var table = document
      .getElementsByTagName("table")[1]
      .getElementsByTagName("tr")[1]
      .getElementsByTagName("tr");
  try {
    for (int i = 1; i < table.length; i++) {
      var tdData = table[i].getElementsByTagName("td");
      if (tdData.length < 5) {
        continue;
      }
      if (tdData[3].text.length < 2) {
        continue;
      }
      data["data"].add({
        "date": tdData[2].text,
        "type": tdData[3].text,
        "counts": tdData[4].text,
        "reason": tdData[5].text
      });
    }
  } on Exception catch (e) {
    print(e);
  }
  return data;
}

Map<String, dynamic> roomListParser(String html) {
  Map<String, dynamic> data = {"data": []};

  var document = parse(html);
  var table = document.getElementById("room_id").getElementsByTagName("option");
  try {
    for (int i = 1; i < table.length; i++) {
      data["data"].add(
          {"roomName": table[i].text, "roomId": table[i].attributes["value"]});
    }
  } on Exception catch (e) {
    print(e);
  }
  return data;
}

Map<String, dynamic> roomCourseTableQueryParser(String html) {
  Map<String, dynamic> data = {
    "courses": [],
    "coursetable": {
      "timeCodes": [],
      "Monday": [],
      "Tuesday": [],
      "Wednesday": [],
      "Thursday": [],
      "Friday": [],
      "Saturday": [],
      "Sunday": []
    }
  };
  var document = parse(html);

  if (document.getElementsByTagName("table").length == 0) {
    //table not found
    // return data;
  }
  try {
    //the top table parse
    var topTable =
        document.getElementsByTagName("table")[0].getElementsByTagName("tr");
    for (int i = 1; i < topTable.length; i++) {
      var td = topTable[i].getElementsByTagName('td');
      data['courses'].add({
        'code': td[0].text,
        'title': td[1].text,
        'className': td[2].text,
        'group': td[3].text,
        'units': td[4].text,
        'hours': td[5].text,
        'required': td[6].text,
        'at': td[8].text,
        'times': td[9].text,
        "instructors": td[10].text.split(",")
      });
    }
  } on Exception catch (e) {} on RangeError catch (r) {}

  //the second talbe.

  //make timetable
  var secondTable =
      document.getElementsByTagName("table")[1].getElementsByTagName("tr");
  try {
    //remark:Best split is regex but... Chinese have some difficulty Q_Q
    for (int i = 1; i < secondTable.length; i++) {
      var _temptext =
          secondTable[i].getElementsByTagName('td')[0].text.replaceAll(" ", "");

      data['coursetable']['timeCodes'].add(_temptext
          .substring(0, _temptext.length - 10)
          .replaceAll(String.fromCharCode(160), ""));
    }
  } on Exception catch (e) {}
  //make each day.
  List keyName = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];
  ;

  try {
    for (int key = 0; key < keyName.length; key++) {
      for (int eachSession = 1;
          eachSession < data['coursetable']['timeCodes'].length;
          eachSession++) {
        var eachDays = document
            .getElementsByTagName("table")[1]
            .getElementsByTagName("tr")[eachSession]
            .getElementsByTagName("td")[key + 1];

        var splitData = (eachDays.outerHtml
            .substring(eachDays.outerHtml.indexOf("; font-family: 細明體") + 20,
                eachDays.outerHtml.indexOf(";</font>"))
            .split("<br>"));

        if (splitData.length < 2) {
          continue;
        }
        var _eachDaysDate = document
            .getElementsByTagName("table")[1]
            .getElementsByTagName("tr")[eachSession]
            .getElementsByTagName("td")[0]
            .outerHtml;

        var courseTime = _eachDaysDate
            .substring(_eachDaysDate.indexOf("&nbsp;<br>") + 10,
                _eachDaysDate.indexOf("&nbsp;<br><br><"))
            .split("<br>");

        if (splitData.length <= 1) {
          continue;
        }
        String title = splitData[0];
        if (title.indexOf(">") > -1) {
          title = title.substring(title.indexOf(">") + 1, title.length);
        }
        data['coursetable'][keyName[key]].add({
          'title': title.replaceAll("&nbsp;", ""),
          'date': {
            "startTime": courseTime[1].split('-')[0],
            "endTime": courseTime[1].split('-')[1],
            'section': courseTime[0]
                .replaceAll(" ", "")
                .replaceAll(String.fromCharCode(160), "")
          },
          'instructors': splitData[1].replaceAll("&nbsp;", "").split(","),
        });
      }
    }
  } on Exception catch (e) {}
  return data;
}

void main() {
  new File('file.txt').readAsString().then((String contents) {
    print(apLoginParser(contents));
  });
}
