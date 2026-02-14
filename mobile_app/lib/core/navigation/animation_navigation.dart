import 'package:flutter/material.dart';

class AnimatedNavigation {
  static void pushReplacement(
    BuildContext context,
    Widget page, {
    bool fromRight = true,
  }) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, animation, __, child) {
          final begin = Offset(fromRight ? 1 : -1, 0);
          const end = Offset.zero;

          final slide = Tween(begin: begin, end: end)
              .animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ));

          final fade = Tween<double>(begin: 0, end: 1).animate(animation);

          return SlideTransition(
            position: slide,
            child: FadeTransition(
              opacity: fade,
              child: child,
            ),
          );
        },
      ),
    );
  }
}
