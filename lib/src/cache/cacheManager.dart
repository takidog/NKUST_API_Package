import 'dart:collection';

class cacheData {
  String key;
  dynamic value;
  int expeireTime;

  cacheData({this.key, this.value, this.expeireTime});
}

class cacheManager {
  static LinkedHashMap dataPool = new LinkedHashMap();

  void add(String key, dynamic data, {int expeirdTimeMs = -1}) {
    if (expeirdTimeMs < 0) {
      dataPool.addAll({key: cacheData(key: key, value: data)});
      return;
    }

    dataPool.addAll({
      key: cacheData(
          key: key,
          value: data,
          expeireTime:
              new DateTime.now().millisecondsSinceEpoch + expeirdTimeMs)
    });
  }

  void clearAllexpeirdData() async {
    List toRemoveList = [];
    dataPool.forEach((key, value) {
      if (value.expeireTime != null &&
          value.expeireTime < new DateTime.now().millisecondsSinceEpoch) {
        toRemoveList.add(key);
      }
    });
    dataPool.removeWhere((key, value) => toRemoveList.contains(key));
  }

  static cacheData getData(String key) {
    return dataPool[key];
  }

  dynamic getValue(String key) {
    var temp = getData(key);
    if (temp == null) {
      return null;
    }
    if (temp.expeireTime != null &&
        temp.expeireTime < new DateTime.now().millisecondsSinceEpoch) {
      remove(key);
      clearAllexpeirdData();
      return null;
    }
    return temp.value;
  }

  bool isExist(String key) {
    if (dataPool[key] != null &&
        dataPool[key].expeireTime > new DateTime.now().millisecondsSinceEpoch) {
      return true;
    }
    return false;
  }

  void remove(String key) {
    dataPool.remove(key);
  }

  bool updateExpeirdTime(String key, int expeirdTimeMs) {
    if (dataPool[key] == null || expeirdTimeMs <= -1) {
      return false;
    }

    dataPool[key].expeireTime =
        new DateTime.now().millisecondsSinceEpoch + expeirdTimeMs;
    return true;
  }

  bool updateData(String key, dynamic data) {
    if (dataPool[key] == null) {
      return false;
    }
    dataPool[key].value = data;
    return true;
  }

  int getLength() {
    return dataPool.length;
  }
}
