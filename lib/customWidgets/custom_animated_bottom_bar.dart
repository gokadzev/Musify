// pub: https://pub.dev/packages/flashy_tab_bar2
// license: https://raw.githubusercontent.com/Cuberto/flashy-tabbar-android/master/LICENSE
// remade (not original)

import 'package:flutter/material.dart';
import 'package:musify/customWidgets/marque.dart';

class CustomAnimatedBottomBar extends StatelessWidget {
  CustomAnimatedBottomBar({
    super.key,
    this.selectedIndex = 0,
    this.height = 60,
    this.showElevation = true,
    this.iconSize = 20,
    this.backgroundColor,
    this.animationDuration = const Duration(milliseconds: 170),
    this.animationCurve = Curves.linear,
    this.shadows = const [
      BoxShadow(
        color: Colors.black12,
        blurRadius: 3,
      ),
    ],
    required this.items,
    required this.onItemSelected,
  }) {
    assert(height >= 55 && height <= 100);
    assert(items.length >= 2 && items.length <= 5);
  }

  final Curve animationCurve;
  final Duration animationDuration;
  final Color? backgroundColor;
  final double height;
  final double iconSize;
  final List<BottomNavBarItem> items;
  final ValueChanged<int> onItemSelected;
  final int selectedIndex;
  final List<BoxShadow> shadows;
  final bool showElevation;

  @override
  Widget build(BuildContext context) {
    final bg = (backgroundColor == null)
        ? Theme.of(context).bottomAppBarColor
        : backgroundColor;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        boxShadow: showElevation ? shadows : [],
      ),
      child: SafeArea(
        child: Container(
          width: double.infinity,
          height: height,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: items.map((item) {
              final index = items.indexOf(item);
              return Expanded(
                child: GestureDetector(
                  onTap: () => onItemSelected(index),
                  child: _FlashTabBarItem(
                    item: item,
                    tabBarHeight: height,
                    iconSize: iconSize,
                    isSelected: index == selectedIndex,
                    backgroundColor: bg!,
                    animationDuration: animationDuration,
                    animationCurve: animationCurve,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class BottomNavBarItem {
  BottomNavBarItem({
    required this.icon,
    required this.title,
    this.activeColor = const Color(0xff272e81),
    this.inactiveColor = const Color(0xff9496c1),
  });

  Color activeColor;
  final Icon icon;
  Color inactiveColor;
  final Text title;
}

class _FlashTabBarItem extends StatelessWidget {
  const _FlashTabBarItem({
    required this.item,
    required this.isSelected,
    required this.tabBarHeight,
    required this.backgroundColor,
    required this.animationDuration,
    required this.animationCurve,
    required this.iconSize,
  });

  final Curve animationCurve;
  final Duration animationDuration;
  final Color backgroundColor;
  final double iconSize;
  final bool isSelected;
  final BottomNavBarItem item;
  final double tabBarHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      height: double.maxFinite,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        alignment: Alignment.center,
        children: <Widget>[
          AnimatedAlign(
            duration: animationDuration,
            alignment: isSelected ? Alignment.topCenter : Alignment.center,
            child: AnimatedOpacity(
              opacity: isSelected ? 1.0 : 1.0,
              duration: animationDuration,
              child: IconTheme(
                data: IconThemeData(
                  size: iconSize,
                  color: isSelected
                      ? item.activeColor.withOpacity(1)
                      : item.inactiveColor,
                ),
                child: item.icon,
              ),
            ),
          ),
          AnimatedPositioned(
            curve: animationCurve,
            duration: animationDuration,
            top: isSelected ? -2.0 * iconSize : tabBarHeight / 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  width: iconSize,
                  height: iconSize,
                ),
                CustomPaint(
                  painter: _CustomPath(backgroundColor),
                  child: SizedBox(
                    width: 80,
                    height: iconSize,
                  ),
                )
              ],
            ),
          ),
          AnimatedAlign(
            alignment: isSelected ? Alignment.center : Alignment.bottomCenter,
            duration: animationDuration,
            curve: animationCurve,
            child: AnimatedOpacity(
              opacity: isSelected ? 1.0 : 0.0,
              duration: animationDuration,
              child: MarqueeWidget(
                direction: Axis.horizontal,
                child: DefaultTextStyle.merge(
                  style: TextStyle(
                    color: item.activeColor,
                    fontWeight: FontWeight.bold,
                  ),
                  child: item.title,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            child: CustomPaint(
              painter: _CustomPath(backgroundColor),
              child: SizedBox(
                width: 80,
                height: iconSize - 8,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedOpacity(
              duration: animationDuration,
              opacity: isSelected ? 1.0 : 0.0,
              child: Container(
                width: 5,
                height: 5,
                alignment: Alignment.bottomCenter,
                margin: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: item.activeColor,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _CustomPath extends CustomPainter {
  _CustomPath(this.backgroundColor);

  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final paint = Paint();

    path.lineTo(0, 0);
    path.lineTo(0, 2.0 * size.height);
    path.lineTo(1.0 * size.width, 2.0 * size.height);
    path.lineTo(1.0 * size.width, 1.0 * size.height);
    path.lineTo(0, 0);
    path.close();

    paint.color = backgroundColor;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return oldDelegate != this;
  }
}
