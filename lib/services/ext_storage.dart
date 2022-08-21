import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

// ignore: avoid_classes_with_only_static_members
class ExtStorageProvider {
  // asking for permission
  static Future<bool> requestPermission(Permission permission) async {
    if (await permission.isGranted) {
      return true;
    } else {
      final result = await permission.request();
      if (result == PermissionStatus.granted) {
        return true;
      } else {
        return false;
      }
    }
  }

  // getting external storage path
  static Future<String?> getExtStorage({required String dirName}) async {
    Directory? directory;

    try {
      // checking platform
      if (Platform.isAndroid) {
        if (await requestPermission(Permission.storage)) {
          directory = await getExternalStorageDirectory();

          // getting main path
          final newPath = directory!.path
              .replaceFirst('Android/data/com.gokadzev.musify/files', dirName);

          directory = Directory(newPath);

          // checking if directory exist or not
          if (!await directory.exists()) {
            // if directory not exists then asking for permission to create folder
            await requestPermission(Permission.manageExternalStorage);
            //creating folder

            await directory.create(recursive: true);
          }
          if (await directory.exists()) {
            try {
              // if directory exists then returning the complete path
              return newPath;
            } catch (e) {
              rethrow;
            }
          }
        } else {
          return throw 'something went wrong';
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
        return directory.path;
      } else {
        directory = await getDownloadsDirectory();
        return directory!.path;
      }
    } catch (e) {
      rethrow;
    }
    return directory.path;
  }
}
