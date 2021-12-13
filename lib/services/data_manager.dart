import 'package:hive/hive.dart';

addOrUpdateData(category, key, value) async {
  var box = await Hive.openBox(category);
  box.put(key, value);
}

getData(category, key) async {
  var box = await Hive.openBox(category);
  return box.get(key);
}

deleteData(category, key) async {
  var box = await Hive.openBox(category);
  box.delete(key);
}
