import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:parallax/core/constants/app_colors.dart';
import 'package:parallax/core/constants/app_typography.dart';
import 'package:parallax/core/utils/mission_utils.dart';
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

class ShortlistScreen extends StatelessWidget {
  const ShortlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      imageOpacity: 0.08,
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
                return _ShortlistContent(data: data, mission: mission);
              },
            );
          },
        ),
      ),
    );
  }
}

class _ShortlistContent extends StatelessWidget {
  final AnalogsData data;
  final MissionState mission;

  const _ShortlistContent({required this.data, required this.mission});

  @override
  Widget build(BuildContext context) {
    final selected = mission.shortlist
        .map((id) => data.findSiteIn(mission.target, id))
        .whereType<SiteModel>()
        .toList(growable: false);

    if (selected.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 18),
            Text(
              'Shortlist & Compare',
              style: AppTypography.screenTitle.copyWith(fontSize: 30),
            ),
            const Spacer(),
            AppEmptyState(
              icon: Icons.bookmark_border_rounded,
              title: 'Your shortlist is empty',
              message: 'Add up to 3 sites from Explore, then compare them side by side and generate a mission brief.',
              actionLabel: 'Explore analogs',
              onAction: () => context.go('/explore'),
            ),
            const Spacer(),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Shortlist & Compare',
                    style: AppTypography.screenTitle.copyWith(fontSize: 30),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${selected.length} of 3 sites selected for ${mission.target}.',
                    style: AppTypography.body.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => context.read<MissionBloc>().add(
                const MissionShortlistCleared(),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Clear',
                style: TextStyle(color: AppColors.textMuted, fontSize: 10),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        for (final site in selected) ...[
          _ShortlistCard(
            site: site,
            onOpen: () => context.push('/site/${site.siteId}', extra: site),
            onRemove: () => context.read<MissionBloc>().add(
              MissionShortlistToggled(site.siteId),
            ),
          ),
          const SizedBox(height: 9),
        ],
        const SizedBox(height: 14),
        if (selected.length < 2)
          _AddMoreCard(onTap: () => context.go('/explore'))
        else ...[
          const Text(
            'SIDE-BY-SIDE',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              letterSpacing: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 9),
          _CompareTable(sites: selected),
          const SizedBox(height: 16),
          _RecommendationCard(sites: selected),
        ],
        const SizedBox(height: 18),
        SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: () => context.push('/brief'),
            icon: const Icon(Icons.description_outlined, size: 19),
            label: const Text('Generate mission brief'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.background,
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'A brief summarizes your selection, trade-offs, and recommendation.',
            style: TextStyle(
              color: AppColors.textMuted.withValues(alpha: 0.9),
              fontSize: 9,
            ),
          ),
        ),
      ],
    );
  }
}

class _ShortlistCard extends StatelessWidget {
  final SiteModel site;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  const _ShortlistCard({
    required this.site,
    required this.onOpen,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.fromLTRB(13, 11, 5, 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.surfaceLight.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  '#${site.rank}',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      site.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        StatusPill(status: site.status),
                        const SizedBox(width: 7),
                        Text(
                          site.analogType,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatScore(site.similarityScore),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    'score',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 8),
                  ),
                ],
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.textMuted,
                  size: 17,
                ),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddMoreCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddMoreCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.add_circle_outline_rounded,
              color: AppColors.accent,
              size: 22,
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Add another site to compare',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.accent,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _CompareTable extends StatelessWidget {
  final List<SiteModel> sites;

  const _CompareTable({required this.sites});

  @override
  Widget build(BuildContext context) {
    final bestRank = sites.map((site) => site.rank).reduce(math.min);
    final bestScore = sites
        .map((site) => site.similarityScore)
        .reduce(math.max);
    final bestDistance = sites.map((site) => site.distance).reduce(math.min);
    final bestWarning = sites
        .map((site) => warningSeverity(site.warningLevel))
        .reduce(math.min);
    final bestStatus = sites
        .map((site) => statusRank(site.status))
        .reduce(math.max);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: AppColors.surfaceLight.withValues(alpha: 0.45),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          defaultColumnWidth: const FixedColumnWidth(116),
          columnWidths: const {0: FixedColumnWidth(94)},
          border: TableBorder(
            horizontalInside: BorderSide(
              color: AppColors.surfaceLight.withValues(alpha: 0.25),
            ),
          ),
          children: [
            TableRow(
              children: [
                _headerCell(''),
                for (final site in sites) _headerCell(site.name),
              ],
            ),
            TableRow(
              children: [
                _labelCell('Rank'),
                for (final site in sites)
                  _valueCell('#${site.rank}', isBest: site.rank == bestRank),
              ],
            ),
            TableRow(
              children: [
                _labelCell('Score'),
                for (final site in sites)
                  _valueCell(
                    formatScore(site.similarityScore),
                    isBest: site.similarityScore == bestScore,
                  ),
              ],
            ),
            TableRow(
              children: [
                _labelCell('Status'),
                for (final site in sites)
                  _valueCell(
                    site.status,
                    isBest: statusRank(site.status) == bestStatus,
                    color: statusColor(site.status),
                  ),
              ],
            ),
            TableRow(
              children: [
                _labelCell('Warning'),
                for (final site in sites)
                  _valueCell(
                    _warningLabel(site.warningLevel),
                    isBest: warningSeverity(site.warningLevel) == bestWarning,
                    color: warningColor(site.warningLevel),
                  ),
              ],
            ),
            TableRow(
              children: [
                _labelCell('Type'),
                for (final site in sites)
                  _valueCell(site.analogType, small: true),
              ],
            ),
            TableRow(
              children: [
                _labelCell('Weakest'),
                for (final site in sites)
                  _valueCell(weakestConditionLabel(site), small: true),
              ],
            ),
            TableRow(
              children: [
                _labelCell('Distance'),
                for (final site in sites)
                  _valueCell(
                    formatDistance(site.distance),
                    isBest: site.distance == bestDistance,
                  ),
              ],
            ),
            TableRow(
              children: [
                _labelCell('Coordinates'),
                for (final site in sites)
                  _valueCell(
                    '${formatCoordinate(site.lat, isLatitude: true)}\n'
                    '${formatCoordinate(site.lon, isLatitude: false)}',
                    small: true,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _warningLabel(String level) {
    switch (level.toLowerCase()) {
      case 'high':
        return 'High';
      case 'caution':
        return 'Caution';
      case 'none':
        return 'None';
      default:
        return 'N/A';
    }
  }

  Widget _headerCell(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _labelCell(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(11, 10, 8, 10),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _valueCell(
    String text, {
    bool isBest = false,
    bool small = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color:
                    color ??
                    (isBest ? AppColors.accent : AppColors.textSecondary),
                fontSize: small ? 9 : 10,
                height: 1.25,
                fontWeight: isBest ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          if (isBest)
            const Icon(Icons.star_rounded, color: AppColors.accent, size: 11),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final List<SiteModel> sites;

  const _RecommendationCard({required this.sites});

  @override
  Widget build(BuildContext context) {
    final sorted = [...sites]
      ..sort((a, b) => b.similarityScore.compareTo(a.similarityScore));
    final primary = sorted.first;
    final backup = sorted.length > 1 ? sorted[1] : null;
    final lowestRisk = [...sites]
      ..sort((a, b) {
        final warningCompare = warningSeverity(a.warningLevel)
            .compareTo(warningSeverity(b.warningLevel));
        if (warningCompare != 0) return warningCompare;
        return b.similarityScore.compareTo(a.similarityScore);
      });
    final safest = lowestRisk.first;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.surfaceLight.withValues(alpha: 0.32),
            AppColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.accent,
                size: 16,
              ),
              SizedBox(width: 7),
              Text(
                'Recommendation',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          _RecommendationRow(
            label: 'Primary',
            site: primary,
            color: AppColors.accent,
          ),
          if (backup != null) ...[
            const SizedBox(height: 8),
            _RecommendationRow(
              label: 'Backup',
              site: backup,
              color: AppColors.accentLight,
            ),
          ],
          const SizedBox(height: 8),
          _RecommendationRow(
            label: 'Lowest risk',
            site: safest,
            color: AppColors.recommended,
          ),
          const SizedBox(height: 10),
          Text(
            backup == null
                ? 'Add a second site to get a backup recommendation.'
                : 'Primary has the highest relative score. Backup is the next-best option; lowest risk has the mildest warning level.',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 9,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationRow extends StatelessWidget {
  final String label;
  final SiteModel site;
  final Color color;

  const _RecommendationRow({
    required this.label,
    required this.site,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
          ),
        ),
        Expanded(
          child: Text(
            site.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          '#${site.rank}',
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
