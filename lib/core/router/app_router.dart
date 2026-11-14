import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:parallax/core/constants/app_colors.dart';
import 'package:parallax/core/constants/app_typography.dart';
import 'package:parallax/data/models/site_model.dart';
import 'package:parallax/presentation/screens/about/about_screen.dart';
import 'package:parallax/presentation/screens/brief/mission_brief_screen.dart';
import 'package:parallax/presentation/screens/explore/explore_screen.dart';
import 'package:parallax/presentation/screens/fine_tune/fine_tune_screen.dart';
import 'package:parallax/presentation/screens/home/home_screen.dart';
import 'package:parallax/presentation/screens/main_shell.dart';
import 'package:parallax/presentation/screens/shortlist/shortlist_screen.dart';
import 'package:parallax/presentation/screens/site_detail/site_detail_screen.dart';
import 'package:parallax/presentation/screens/splash/splash_screen.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => _page(state, const SplashScreen()),
      ),
      GoRoute(
        path: '/fine-tune',
        pageBuilder: (context, state) => _page(state, const FineTuneScreen()),
      ),
      GoRoute(
        path: '/site/:siteId',
        pageBuilder: (context, state) {
          final siteId = int.tryParse(state.pathParameters['siteId'] ?? '');
          final site = state.extra is SiteModel
              ? state.extra as SiteModel
              : null;
          return _page(
            state,
            SiteDetailScreen(siteId: siteId, initialSite: site),
          );
        },
      ),
      GoRoute(
        path: '/brief',
        pageBuilder: (context, state) =>
            _page(state, const MissionBriefScreen()),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (context, state) =>
                    _page(state, const HomeScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/explore',
                pageBuilder: (context, state) =>
                    _page(state, const ExploreScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/shortlist',
                pageBuilder: (context, state) =>
                    _page(state, const ShortlistScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/about',
                pageBuilder: (context, state) =>
                    _page(state, const AboutScreen()),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => _RouteErrorScreen(
      message: state.error?.toString() ?? 'The page could not be opened.',
    ),
  );

  static CustomTransitionPage<void> _page(GoRouterState state, Widget child) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 240),
      reverseTransitionDuration: const Duration(milliseconds: 190),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curve,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.035, 0),
              end: Offset.zero,
            ).animate(curve),
            child: child,
          ),
        );
      },
    );
  }
}

class _RouteErrorScreen extends StatelessWidget {
  final String message;

  const _RouteErrorScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.explore_off_outlined,
                color: AppColors.accent,
                size: 42,
              ),
              const SizedBox(height: 14),
              Text(
                'This page is not available',
                textAlign: TextAlign.center,
                style: AppTypography.sectionTitle,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(color: AppColors.accent),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () => context.go('/home'),
                child: const Text('Back to home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
