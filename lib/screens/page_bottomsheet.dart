import 'package:flutter/material.dart';

class BottomSheetLikeScreen extends StatefulWidget {
  const BottomSheetLikeScreen({super.key});

  @override
  State<BottomSheetLikeScreen> createState() => _BottomSheetLikeScreenState();
}

class _BottomSheetLikeScreenState extends State<BottomSheetLikeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _dragPosition = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 1, end: 0).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _closeScreen() async {
    await _controller.reverse();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        setState(() {
          _dragPosition += details.delta.dy;
        });
      },
      onVerticalDragEnd: (details) {
        if (_dragPosition > 100) {
          _closeScreen();
        } else {
          setState(() => _dragPosition = 0);
        }
      },
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _dragPosition + (1 - _animation.value) * height),
            child: child,
          );
        },
        child: Material(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                // Заголовок с индикатором
                Container(
                  height: 40,
                  alignment: Alignment.center,
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Контент экрана
                Expanded(
                  child: ListView.builder(
                    itemCount: 20,
                    itemBuilder:
                        (context, index) =>
                            ListTile(title: Text('Item $index')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Метод для открытия экрана
void openBottomSheetLikeScreen(BuildContext context) {
  Navigator.push(
    context,
    PageRouteBuilder(
      opaque: false,
      pageBuilder: (_, __, ___) => const BottomSheetLikeScreen(),
      transitionsBuilder: (context, animation, _, child) {
        return Stack(
          children: [
            // Затемненный фон
            FadeTransition(
              opacity: animation,
              child: Container(color: Colors.black.withOpacity(0.4)),
            ),
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut),
              ),
              child: child,
            ),
          ],
        );
      },
    ),
  );
}
