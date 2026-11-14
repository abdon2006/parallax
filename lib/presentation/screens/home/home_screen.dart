import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:parallax/core/constants/app_colors.dart';
import 'package:parallax/core/constants/app_typography.dart';
import 'package:parallax/core/constants/condition_catalog.dart';
import 'package:parallax/core/utils/mission_utils.dart';
import 'package:parallax/core/widgets/app_animated_entry.dart';
import 'package:parallax/core/widgets/app_background.dart';
import 'package:parallax/core/widgets/app_states.dart';
import 'package:parallax/core/widgets/status_pill.dart';
import 'package:parallax/data/models/analogs_data.dart';
import 'package:parallax/data/models/site_model.dart';
import 'package:parallax/logic/bloc/analog_bloc.dart';
import 'package:parallax/logic/bloc/analog_events.dart';
import 'package:parallax/logic/bloc/analog_states.dart';
import 'package:parallax/logic/bloc/mission_bloc.dart';
import 'package:parallax/logic/bloc/mission_events.dart';
import 'package:parallax/logic/bloc/mission_states.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      imageOpacity: 1,
      child: SafeArea(
        child: BlocBuilder<AnalogBloc, AnalogStates>(
          builder: (context, state) {
            if (state is AnalogLoading || state is AnalogInitial) {
              return const AppLoadingView();
            }
            if (state is AnalogError) {
              return AppErrorView(
                message: state.message,
                onRetry: () =>
                    context.read<AnalogBloc>().add(const FetchAnalogsEvent()),
              );
            }
            final data = (state as FetchAnalogsSuccess).data;
            return BlocBuilder<MissionBloc, MissionState>(
              builder: (context, mission) {
                return _HomeContent(data: data, mission: mission);
              },
            );
          },
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final AnalogsData data;
  final MissionState mission;

  const _HomeContent({required this.data, required this.mission});

  @override
  Widget build(BuildContext context) {
    final sites = data.sitesFor(mission.target);
    final moon = data.sitesFor('Moon');
    final mars = data.sitesFor('Mars');
    final moonRecommended = moon
        .where((site) => site.status == 'Recommended')
        .length;
    final marsRecommended = mars
        .where((site) => site.status == 'Recommended')
        .length;
    final matching = MissionFilter.apply(
      sites,
      conditions: mission.conditions,
      statusFilter: mission.statusFilter,
      top10Only: false,
      lowRiskOnly: mission.lowRiskOnly,
      searchQuery: '',
      sortBy: 'rank',
    );
    final topSite = matching.isEmpty ? null : matching.first;

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
      children: [
        ///  HEADER
        AppAnimatedEntry(
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.35),
                  ),
                ),
                child: const Icon(
                  Icons.public_rounded,
                  color: AppColors.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PARALLAX',
                    style: AppTypography.screenTitle.copyWith(
                      fontSize: 22,
                      letterSpacing: 2,
                    ),
                  ),
                  const Text(
                    'ANALOG SITE FINDER',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 8,
                      letterSpacing: 2.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),

        /// Section Header
        AppAnimatedEntry(
          delay: const Duration(milliseconds: 50),
          child: Text(
            'Find your\nplanetary analog.',
            style: AppTypography.screenTitle.copyWith(fontSize: 34),
          ),
        ),
        const SizedBox(height: 10),
        AppAnimatedEntry(
          delay: const Duration(milliseconds: 90),
          child: Text(
            'Earth\'s closest training grounds for the Moon and Mars.',
            style: AppTypography.body,
          ),
        ),
        const SizedBox(height: 26),

        /// SECTION TITLE
        Row(
          children: [
            Text(
              'CHOOSE A TARGET',
              style: AppTypography.caption.copyWith(
                letterSpacing: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '${sites.length} sites',
              style: AppTypography.caption.copyWith(fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 12),

        /// MARS & MOON
        Row(
          children: [
            Expanded(
              child: _TargetCard(
                target: 'Moon',
                imagePath: 'assets/images/moon.webp',
                selected: mission.target == 'Moon',
                recommendedCount: moonRecommended,
                onTap: () => context.read<MissionBloc>().add(
                  const MissionTargetChanged('Moon'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TargetCard(
                target: 'Mars',
                imagePath: 'assets/images/mars.webp',
                selected: mission.target == 'Mars',
                recommendedCount: marsRecommended,
                onTap: () => context.read<MissionBloc>().add(
                  const MissionTargetChanged('Mars'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 26),
        Row(
          children: [
            Text(
              'WHAT MATTERS MOST?',
              style: AppTypography.caption.copyWith(
                letterSpacing: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => context.push('/fine-tune'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Fine-tune  →',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        /// List Of Presets
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: missionPresets.length + 1,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              if (index == missionPresets.length) {
                return _CustomPresetCard(
                  selected:
                      mission.hasProfile &&
                      profileLabel(
                            conditions: mission.conditions,
                            lowRiskOnly: mission.lowRiskOnly,
                          ) ==
                          'Custom',
                  onTap: () => context.push('/fine-tune'),
                );
              }
              final preset = missionPresets[index];
              final selected = _isPresetSelected(mission, preset);
              final count = MissionFilter.countForPreset(sites, preset);
              return _PresetCard(
                preset: preset,
                count: count,
                selected: selected,
                onTap: () => context.read<MissionBloc>().add(
                  MissionPresetApplied(preset.name),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 22),
        _StatsCard(
          totalSites: sites.length,
          moonRecommended: moonRecommended,
          marsRecommended: marsRecommended,
        ),
        if (topSite != null) ...[
          const SizedBox(height: 26),
          Row(
            children: [
              Expanded(
                child: Text(
                  'TOP MATCH FOR ${mission.target.toUpperCase()}',
                  style: AppTypography.caption.copyWith(
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.go('/explore'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'View all',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _TopPickCard(
            site: topSite,
            onTap: () =>
                context.push('/site/${topSite.siteId}', extra: topSite),
          ),
        ] else ...[
          const SizedBox(height: 26),
          _NoTopMatchCard(onTap: () => context.push('/fine-tune')),
        ],
        const SizedBox(height: 26),
        SizedBox(
          height: 54,
          child: FilledButton.icon(
            onPressed: () => context.go('/explore'),
            icon: const Icon(Icons.explore_rounded, size: 20),
            label: const Text('Explore all analogs'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.background,
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () => context.go('/about'),
            child: const Text(
              'How the score works',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ),
        ),
      ],
    );
  }

  bool _isPresetSelected(MissionState mission, MissionPreset preset) {
    return mission.lowRiskOnly == preset.lowRiskOnly &&
        mission.conditions.length == preset.conditions.length &&
        mission.conditions.containsAll(preset.conditions);
  }
}

class _TargetCard extends StatelessWidget {
  final String target;
  final String imagePath;
  final bool selected;
  final int recommendedCount;
  final VoidCallback onTap;

  const _TargetCard({
    required this.target,
    required this.imagePath,
    required this.selected,
    required this.recommendedCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = target == 'Moon'
        ? AppColors.accent
        : AppColors.notRecommended;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedScale(
        scale: selected ? 1.02 : 1,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
          height: 200,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected
                  ? color
                  : AppColors.surfaceLight.withValues(alpha: 0.7),
              width: selected ? 1.8 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: selected ? color : AppColors.textMuted,
                    size: 18,
                  ),
                  const Spacer(),
                  Text(
                    target == 'Moon' ? 'ORBITAL' : 'PLANETARY',
                    style: TextStyle(
                      color: color.withValues(alpha: 0.8),
                      fontSize: 7,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Center(
                    child: AnimatedScale(
                      scale: selected ? 1.05 : 1,
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      child: Image.asset(imagePath, fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
              Text(
                target,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$recommendedCount recommended',
                style: TextStyle(
                  color: selected ? color : AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PresetCard extends StatelessWidget {
  final MissionPreset preset;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _PresetCard({
    required this.preset,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedScale(
        scale : selected ? 1.01 : 1 ,
        duration: const Duration(milliseconds: 500),
       curve:  Curves.easeInOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve:  Curves.easeInOutCubic,
          width: 150,
          padding: const EdgeInsets.all(12),
          margin: EdgeInsets.all(
          2),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.12)
                : AppColors.surface.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? AppColors.accent.withValues(alpha: 0.75)
                  : AppColors.surfaceLight.withValues(alpha: 0.55),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                preset.icon,
                color: selected ? AppColors.accent : AppColors.textSecondary,
                size: 32,
              ),
              const Spacer(),
              Text(
                preset.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$count sites',
                style: TextStyle(
                  color: selected ? AppColors.accent : AppColors.textMuted,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomPresetCard extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const _CustomPresetCard({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve : Curves.easeInOutCubic,
        width: 138,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.12)
              : AppColors.surface.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.75)
                : AppColors.surfaceLight.withValues(alpha: 0.55),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.tune_rounded,
              color: AppColors.textSecondary,
              size: 24,
            ),
            const Spacer(),
            const Text(
              'Custom',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              selected ? 'Editing profile' : 'Pick conditions',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final int totalSites;
  final int moonRecommended;
  final int marsRecommended;

  const _StatsCard({
    required this.totalSites,
    required this.moonRecommended,
    required this.marsRecommended,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.surfaceLight.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          _Stat(value: '$totalSites', label: 'Earth analogs'),
          _Divider(),
          _Stat(
            value: '$moonRecommended',
            label: 'Moon-ready',
            color: AppColors.accent,
          ),
          _Divider(),
          _Stat(
            value: '$marsRecommended',
            label: 'Mars-ready',
            color: AppColors.notRecommended,
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _Stat({
    required this.value,
    required this.label,
    this.color = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 30,
      color: AppColors.surfaceLight.withValues(alpha: 0.6),
    );
  }
}

class _NoTopMatchCard extends StatelessWidget {
  final VoidCallback onTap;

  const _NoTopMatchCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.surfaceLight.withValues(alpha: 0.45),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.tune_rounded,
              color: AppColors.warningCaution,
              size: 20,
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'No sites match this profile yet. Fine-tune your conditions or reset the filters.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _TopPickCard extends StatelessWidget {
  final SiteModel site;
  final VoidCallback onTap;

  const _TopPickCard({required this.site, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.surfaceLight.withValues(alpha: 0.46),
              AppColors.surface.withValues(alpha: 0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '#${site.rank} TOP MATCH',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 8,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Spacer(),
                StatusPill(status: site.status),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        site.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        site.analogType,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatScore(site.similarityScore),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 32,
                        height: 1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Text(
                      'relative score',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 8),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                const Icon(
                  Icons.place_outlined,
                  color: AppColors.textMuted,
                  size: 13,
                ),
                const SizedBox(width: 4),
                Text(
                  '${formatCoordinate(site.lat, isLatitude: true)}, '
                  '${formatCoordinate(site.lon, isLatitude: false)}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 9,
                  ),
                ),
                const Spacer(),
                if (site.weakConditions.isNotEmpty)
                  Flexible(
                    child: Text(
                      'Weak: ${conditionShortLabel(site.weakConditions.first.feature)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: warningColor(site.warningLevel),
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Text(
                  'View analog',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.accent,
                  size: 14,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
