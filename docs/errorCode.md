ResponseData  type

```dart
class ResponseData {
  int errorCode = 200;
  String errorMessage;
  Map<String, dynamic> parseData;
  Response response;
  ResponseData(
      {this.errorCode, this.errorMessage, this.parseData, this.response});
}

```

| errorCode | description                                                  | parseData<br />Map<String,dynamic> | response<br />dio.Response |
| :-------: | :----------------------------------------------------------- | :--------------------------------: | :------------------------: |
|   1000    | Login success  <br />(only use on webap login)               |                Null                |            Null            |
|   2000    | General success                                              |                Yes                 |            Yes             |
|    TBD    |                                                              |                                    |                            |
|    TBD    |                                                              |                                    |                            |
|   5000    | NKUST Server error                                           |                 No                 |             No             |
|   5002    | Dio error, a little bit possible is <br />NKUST Server error |                 No                 |             No             |
|   5040    | Timeout                                                      |                 No                 |             No             |
|   5400    | Something error.                                             |                 No                 |             No             |

