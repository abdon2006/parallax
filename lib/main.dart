import 'package:flutter/material.dart';
import 'package:parallax/core/constants/app_colors.dart';
import 'package:parallax/core/constants/app_typography.dart';
import 'package:parallax/core/theme/app_theme.dart';

void main() {
  runApp(const ParallaxApp());
}

class ParallaxApp extends StatelessWidget {
  const ParallaxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parallax',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const _DesignPreview(),
    );
  }
}

class _DesignPreview extends StatelessWidget {
  const _DesignPreview();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DESIGN SYSTEM',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 10),
                Text('Parallax', style: AppTypography.screenTitle),
                const SizedBox(height: 8),
                Text(
                  'Colors, typography, and core components are ready.',
                  style: AppTypography.body,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.surfaceLight.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 7,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.recommended,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Monturaqui', style: AppTypography.cardTitle),
                            const SizedBox(height: 3),
                            Text(
                              'Recommended · relative score 100',
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {},
                    child: const Text('Explore analogs'),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Environmental analogs only.',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
