import 'dart:convert';

List<int> formDataAndEncode(Map<String, String> data) {
  String temp;
  data.forEach((key, value) {
    if (temp != null) {
      temp += "&";
    }
    temp += "${key}=${value}";
  });
  return utf8.encode(temp);
}
