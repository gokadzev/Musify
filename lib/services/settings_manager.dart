import 'package:hive_flutter/hive_flutter.dart';

String? downloadDirectory = Hive.box('settings').get('downloadPath');
