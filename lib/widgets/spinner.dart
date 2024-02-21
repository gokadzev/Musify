import 'package:flutter/material.dart';

class Spinner extends StatelessWidget {
  const Spinner({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(
          Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
