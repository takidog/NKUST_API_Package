import 'dart:async';
import 'dart:io';

int apLoginParser(String html) {
  //100 login success
  //101 login fail

  if (html.indexOf("alert(") < 0 &&
      html.indexOf("top.location.href='index.html") > -1) {
    return 100;
  }
  return 101;
}

void main() {
  new File('file.txt').readAsString().then((String contents) {
    print(apLoginParser(contents));
  });
}
