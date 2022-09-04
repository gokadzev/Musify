import 'package:flutter/material.dart';
import 'package:musify/ui/rootPage.dart';

class CustomAnimatedBottomBar extends StatelessWidget {
  CustomAnimatedBottomBar({
    super.key,
    this.showElevation = true,
    this.onTap,
    this.selectedItemColor,
    this.backgroundColor,
    this.unselectedItemColor,
    this.selectedColorOpacity,
    this.itemShape = const StadiumBorder(),
    this.margin = const EdgeInsets.all(8),
    this.itemPadding = const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.easeOutQuint,
    this.radius = BorderRadius.zero,
    required this.items,
  });
  final Color? backgroundColor;
  final bool showElevation;
  final List<BottomNavBarItem> items;
  final Function(int)? onTap;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final double? selectedColorOpacity;
  final ShapeBorder itemShape;
  final EdgeInsets margin;
  final EdgeInsets itemPadding;
  final Duration duration;
  final Curve curve;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? Theme.of(context).bottomAppBarColor;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: radius,
        boxShadow: [
          if (showElevation)
            const BoxShadow(
              color: Colors.black12,
              blurRadius: 2,
            ),
        ],
      ),
      child: SafeArea(
        minimum: margin,
        child: ValueListenableBuilder<int>(
          valueListenable: activeTab,
          builder: (_, value, __) {
            return Row(
              mainAxisAlignment: items.length <= 2
                  ? MainAxisAlignment.spaceEvenly
                  : MainAxisAlignment.spaceBetween,
              children: [
                for (final item in items)
                  TweenAnimationBuilder<double>(
                    tween: Tween(
                      end: items.indexOf(item) == value ? 1.0 : 0.0,
                    ),
                    curve: curve,
                    duration: duration,
                    builder: (context, t, _) {
                      final selectedColor =
                          item.activeColor ?? selectedItemColor;

                      final unselectedColor =
                          item.inactiveColor ?? unselectedItemColor;

                      return Material(
                        color: Color.lerp(
                          selectedColor!.withOpacity(0),
                          selectedColor
                              .withOpacity(selectedColorOpacity ?? 0.1),
                          t,
                        ),
                        shape: itemShape,
                        child: InkWell(
                          onTap: () => onTap?.call(items.indexOf(item)),
                          customBorder: itemShape,
                          focusColor: selectedColor.withOpacity(0.1),
                          highlightColor: selectedColor.withOpacity(0.1),
                          splashColor: selectedColor.withOpacity(0.1),
                          hoverColor: selectedColor.withOpacity(0.1),
                          child: Padding(
                            padding: Localizations.localeOf(context) ==
                                    const Locale('en', '')
                                ? itemPadding -
                                    (Directionality.of(context) ==
                                            TextDirection.ltr
                                        ? EdgeInsets.only(
                                            right: itemPadding.right * t,
                                          )
                                        : EdgeInsets.only(
                                            left: itemPadding.left * t,
                                          ))
                                : const EdgeInsets.all(15),
                            child: Row(
                              children: [
                                IconTheme(
                                  data: IconThemeData(
                                    color: Color.lerp(
                                      unselectedColor,
                                      selectedColor,
                                      t,
                                    ),
                                    size: 24,
                                  ),
                                  child: items.indexOf(item) == value
                                      ? item.activeIcon ?? item.icon
                                      : item.icon,
                                ),
                                if (Localizations.localeOf(context) ==
                                    const Locale('en', ''))
                                  ClipRect(
                                    clipBehavior: Clip.antiAlias,
                                    child: SizedBox(
                                      height: 20,
                                      child: Align(
                                        alignment: const Alignment(-0.2, 0),
                                        widthFactor: t,
                                        child: Padding(
                                          padding: Directionality.of(context) ==
                                                  TextDirection.ltr
                                              ? EdgeInsets.only(
                                                  left: itemPadding.left / 2,
                                                  right: itemPadding.right,
                                                )
                                              : EdgeInsets.only(
                                                  left: itemPadding.left,
                                                  right: itemPadding.right / 2,
                                                ),
                                          child: DefaultTextStyle(
                                            style: TextStyle(
                                              color: Color.lerp(
                                                selectedColor.withOpacity(0),
                                                selectedColor,
                                                t,
                                              ),
                                              fontWeight: FontWeight.w600,
                                            ),
                                            child: item.title,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class BottomNavBarItem {
  BottomNavBarItem({
    required this.icon,
    required this.title,
    this.activeColor,
    this.inactiveColor,
    this.activeIcon,
  });
  final Widget icon;
  final Widget? activeIcon;
  final Widget title;
  final Color? activeColor;
  final Color? inactiveColor;
}
