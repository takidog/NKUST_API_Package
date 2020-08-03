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
|   1001    | Login fail<br />Password wrong.                              |                Null                |            Null            |
|    TBD    |                                                              |                                    |                            |
|   5000    | NKUST Server error                                           |                Null                |            Null            |
|   5002    | Dio error, a little bit possible is <br />NKUST Server error |                Null                |            Null            |
|   5040    | Timeout                                                      |                Null                |            Null            |
|   5400    | Something error.                                             |                Null                |            Null            |

