import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:parallax/core/constants/app_colors.dart';
import 'package:parallax/core/constants/app_typography.dart';
import 'package:parallax/core/constants/condition_catalog.dart';
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
import 'package:parallax/logic/bloc/mission_states.dart';

class MissionBriefScreen extends StatelessWidget {
  const MissionBriefScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnalogBloc, AnalogStates>(
      builder: (context, state) {
        if (state is AnalogLoading || state is AnalogInitial) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: AppLoadingView(),
          );
        }
        if (state is AnalogError) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: AppErrorView(
              message: state.message,
              onRetry: () =>
                  context.read<AnalogBloc>().add(const FetchAnalogsEvent()),
            ),
          );
        }
        final data = (state as FetchAnalogsSuccess).data;
        return BlocBuilder<MissionBloc, MissionState>(
          builder: (context, mission) {
            return _BriefContent(data: data, mission: mission);
          },
        );
      },
    );
  }
}

class _BriefContent extends StatelessWidget {
  final AnalogsData data;
  final MissionState mission;

  const _BriefContent({required this.data, required this.mission});

  @override
  Widget build(BuildContext context) {
    final sites = mission.shortlist
        .map((id) => data.findSiteIn(mission.target, id))
        .whereType<SiteModel>()
        .toList(growable: false);

    if (sites.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Mission Brief')),
        body: AppEmptyState(
          icon: Icons.description_outlined,
          title: 'Nothing to brief yet',
          message:
              'Add sites to your shortlist, then generate a mission brief.',
          actionLabel: 'Explore analogs',
          onAction: () => context.go('/explore'),
        ),
      );
    }

    final profile = profileLabel(
      conditions: mission.conditions,
      lowRiskOnly: mission.lowRiskOnly,
    );
    final sorted = [...sites]
      ..sort((a, b) => b.similarityScore.compareTo(a.similarityScore));
    final primary = sorted.first;
    final backup = sorted.length > 1 ? sorted[1] : null;
    final safest =
        ([...sites]..sort((a, b) {
              final warningCompare = warningSeverity(a.warningLevel)
                  .compareTo(warningSeverity(b.warningLevel));
              if (warningCompare != 0) return warningCompare;
              return b.similarityScore.compareTo(a.similarityScore);
            }))
            .first;
    final date = _formatDate(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mission Brief'),
        actions: [
          IconButton(
            onPressed: () {
              Clipboard.setData(
                ClipboardData(
                  text: _buildText(
                    sites: sites,
                    primary: primary,
                    backup: backup,
                    safest: safest,
                    target: mission.target,
                    profile: profile,
                    date: date,
                  ),
                ),
              );
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    content: Text('Mission brief copied to clipboard.'),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
            },
            icon: const Icon(
              Icons.copy_rounded,
              color: AppColors.textPrimary,
              size: 19,
            ),
          ),
        ],
      ),
      body: AppBackground(
        imageOpacity: 0.05,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 30),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.surfaceLight.withValues(alpha: 0.32),
                    AppColors.surface,
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'MISSION BRIEF',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 10,
                          letterSpacing: 2.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        date,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${mission.target} analog site selection',
                    style: AppTypography.screenTitle.copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 7,
                    runSpacing: 5,
                    children: [
                      _MetaChip(label: '${mission.target} target'),
                      _MetaChip(label: '$profile profile'),
                      _MetaChip(label: '${sites.length} sites'),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Divider(
                    height: 1,
                    color: AppColors.surfaceLight.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'SELECTED ANALOGS',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 9,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (var index = 0; index < sites.length; index++) ...[
                    _BriefSiteRow(index: index + 1, site: sites[index]),
                    if (index != sites.length - 1)
                      Divider(
                        height: 18,
                        color: AppColors.surfaceLight.withValues(alpha: 0.3),
                      ),
                  ],
                  const SizedBox(height: 17),
                  Divider(
                    height: 1,
                    color: AppColors.surfaceLight.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'RECOMMENDATION',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 9,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 9),
                  _BriefRecommendationRow(
                    label: 'Primary',
                    site: primary,
                    color: AppColors.accent,
                  ),
                  if (backup != null)
                    _BriefRecommendationRow(
                      label: 'Backup',
                      site: backup,
                      color: AppColors.accentLight,
                    ),
                  _BriefRecommendationRow(
                    label: 'Lowest risk',
                    site: safest,
                    color: AppColors.recommended,
                  ),
                  const SizedBox(height: 17),
                  const Text(
                    'METHODOLOGY',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 9,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Sites are ranked by the dataset\'s relative environmental similarity score. Filtering uses each site\'s reported weak conditions; the original ranking is never re-scored.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'LIMITATIONS',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 9,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'This brief compares environmental conditions only. It does not include site access, logistics, cost, permits, or surface composition.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.public_rounded,
                          color: AppColors.accent,
                          size: 12,
                        ),
                      ),
                      const SizedBox(width: 7),
                      const Text(
                        'Generated by Parallax',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Environmental analogs',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(
                      text: _buildText(
                        sites: sites,
                        primary: primary,
                        backup: backup,
                        safest: safest,
                        target: mission.target,
                        profile: profile,
                        date: date,
                      ),
                    ),
                  );
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text('Mission brief copied to clipboard.'),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                },
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Copy brief'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.background,
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: () => context.go('/explore'),
                child: const Text(
                  'Back to explore',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _buildText({
    required List<SiteModel> sites,
    required SiteModel primary,
    required SiteModel? backup,
    required SiteModel safest,
    required String target,
    required String profile,
    required String date,
  }) {
    final buffer = StringBuffer()
      ..writeln('PARALLAX — MISSION BRIEF')
      ..writeln('$date · $target target · $profile profile')
      ..writeln()
      ..writeln('SELECTED ANALOGS');
    for (var index = 0; index < sites.length; index++) {
      final site = sites[index];
      buffer
        ..writeln(
          '${index + 1}. ${site.name} — rank #${site.rank}, '
          'score ${formatScore(site.similarityScore)}, '
          '${site.status}',
        )
        ..writeln(
          '   ${site.analogType} · '
          '${formatCoordinate(site.lat, isLatitude: true)}, '
          '${formatCoordinate(site.lon, isLatitude: false)}',
        )
        ..writeln(
          '   Trade-off: ${site.weakConditions.isEmpty ? 'None reported' : conditionLabel(site.weakConditions.first.feature)}',
        );
    }
    buffer
      ..writeln()
      ..writeln('RECOMMENDATION')
      ..writeln('Primary: ${primary.name}')
      ..writeln('Backup: ${backup?.name ?? 'Add another site'}')
      ..writeln('Lowest risk: ${safest.name}')
      ..writeln()
      ..writeln(
        'Methodology: relative environmental score from the dataset; filters use reported weak conditions.',
      )
      ..writeln(
        'Limitations: environmental conditions only; no access, logistics, cost, permits, or surface composition.',
      );
    return buffer.toString();
  }
}

class _MetaChip extends StatelessWidget {
  final String label;

  const _MetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 8,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _BriefSiteRow extends StatelessWidget {
  final int index;
  final SiteModel site;

  const _BriefSiteRow({required this.index, required this.site});

  @override
  Widget build(BuildContext context) {
    final cleanGroups = cleanGroupsFor(site);
    final tradeOff = site.weakConditions.isEmpty
        ? 'None reported'
        : '${conditionLabel(site.weakConditions.first.feature)} '
              '(${formatConditionValue(site.weakConditions.first.feature, site.weakConditions.first.siteValue)} vs '
              '${formatConditionValue(site.weakConditions.first.feature, site.weakConditions.first.referenceValue)})';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$index',
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      site.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '#${site.rank} · ${formatScore(site.similarityScore)}',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  StatusPill(status: site.status, fontSize: 8),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${site.analogType} · '
                      '${formatCoordinate(site.lat, isLatitude: true)}, '
                      '${formatCoordinate(site.lon, isLatitude: false)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                'Strength: ${cleanGroups.isEmpty ? 'Limited' : cleanGroups.take(2).join(', ')}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 8,
                  height: 1.4,
                ),
              ),
              Text(
                'Trade-off: $tradeOff',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 8,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BriefRecommendationRow extends StatelessWidget {
  final String label;
  final SiteModel site;
  final Color color;

  const _BriefRecommendationRow({
    required this.label,
    required this.site,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          SizedBox(
            width: 66,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 8),
            ),
          ),
          Expanded(
            child: Text(
              site.name,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '#${site.rank}',
            style: TextStyle(
              color: color,
              fontSize: 8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
