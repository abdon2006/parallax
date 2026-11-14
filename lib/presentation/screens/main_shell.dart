import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:parallax/core/constants/app_colors.dart';
import 'package:parallax/logic/bloc/mission_bloc.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  static const _items = [
    _NavItem(
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    _NavItem(
      label: 'Explore',
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore_rounded,
    ),
    _NavItem(
      label: 'Shortlist',
      icon: Icons.bookmark_border_rounded,
      activeIcon: Icons.bookmark_rounded,
    ),
    _NavItem(
      label: 'About',
      icon: Icons.info_outline_rounded,
      activeIcon: Icons.info_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final shortlistCount = context.select<MissionBloc, int>(
      (bloc) => bloc.state.shortlist.length,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Material(
            color: AppColors.surface,
            elevation: 8,
            shadowColor: AppColors.background.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(40),
            child: Container(
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: AppColors.surfaceLight, width: 0.8),
              ),
              child: Row(
                children: List.generate(_items.length, (index) {
                  final item = _items[index];
                  final selected = navigationShell.currentIndex == index;
                  final showBadge =
                      item.label == 'Shortlist' && shortlistCount > 0;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(32),
                        onTap: () {
                          navigationShell.goBranch(
                            index,
                            initialLocation:
                                index == navigationShell.currentIndex,
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.accent.withValues(alpha: 0.14)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Icon(
                                    selected ? item.activeIcon : item.icon,
                                    size: 21,
                                    color: selected
                                        ? AppColors.accent
                                        : AppColors.textMuted,
                                  ),
                                  if (showBadge)
                                    Positioned(
                                      right: -7,
                                      top: -5,
                                      child: Container(
                                        width: 16,
                                        height: 16,
                                        alignment: Alignment.center,
                                        decoration: const BoxDecoration(
                                          color: AppColors.notRecommended,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '$shortlistCount',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item.label,
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: selected
                                      ? AppColors.accent
                                      : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}
