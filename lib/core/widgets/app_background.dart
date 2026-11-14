import 'package:flutter/material.dart';
import 'package:parallax/core/constants/app_colors.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  final double imageOpacity;
  final bool showImage;

  const AppBackground({
    super.key,
    required this.child,
    this.imageOpacity = 0.16,
    this.showImage = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.background),
        if (showImage)
          Opacity(
            opacity: imageOpacity,
            child: Image.asset('assets/images/home_bg.png', fit: BoxFit.cover),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.background.withValues(alpha: 0.22),
                AppColors.background.withValues(alpha: 0.72),
                AppColors.background,
              ],
              stops: const [0, 0.55, 1],
            ),
          ),
        ),
        child,
      ],
    );
  }
}
