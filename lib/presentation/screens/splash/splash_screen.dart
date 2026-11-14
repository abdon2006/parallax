import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:parallax/core/constants/app_colors.dart';
import 'package:parallax/core/widgets/app_animated_entry.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _scale = Tween<double>(
      begin: 0.88,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();
    Future<void>.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) context.go('/home');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/splash_bg.png', fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.background.withValues(alpha: 0.2),
                  AppColors.background.withValues(alpha: 0.45),
                  AppColors.background.withValues(alpha: 0.92),
                ],
              ),
            ),
          ),
          FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppAnimatedEntry(
                      child: SizedBox(
                        height: 150,
                        width: 150,
                        child: SvgPicture.asset('assets/images/logo.svg'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    AppAnimatedEntry(
                      delay: const Duration(milliseconds: 120),
                      child: const Text(
                        'PARALLAX',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 7,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    AppAnimatedEntry(
                      delay: const Duration(milliseconds: 220),
                      child: const Text(
                        'EARTH ANALOGS FOR THE MOON & MARS',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 8,
                          letterSpacing: 2.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 36,
            child: FadeTransition(
              opacity: _fade,
              child: const Column(
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.6,
                      color: AppColors.accent,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'LOADING ANALOG DATA',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 7,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
