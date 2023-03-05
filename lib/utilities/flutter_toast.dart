import 'package:fluttertoast/fluttertoast.dart';
import 'package:musify/style/app_colors.dart';
import 'package:musify/style/app_themes.dart';

void showToast(String text) {
  Fluttertoast.showToast(
    backgroundColor: getMaterialColorFromColor(colorScheme.primary),
    textColor: isAccentWhite(),
    msg: text,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
    fontSize: 14,
  );
}
