import 'package:fluttertoast/fluttertoast.dart';
import 'package:musify/style/appColors.dart';
import 'package:musify/style/appTheme.dart';

void showToast(String text) {
  Fluttertoast.showToast(
    backgroundColor: getMaterialColorFromColor(accent),
    textColor: isAccentWhite(),
    msg: text,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
    fontSize: 14,
  );
}
