import 'package:flutter/material.dart';
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
import 'package:parallax/data/models/reference_model.dart';
import 'package:parallax/data/models/site_model.dart';
import 'package:parallax/data/models/weak_condition.dart';
import 'package:parallax/logic/bloc/analog_bloc.dart';
import 'package:parallax/logic/bloc/analog_events.dart';
import 'package:parallax/logic/bloc/analog_states.dart';
import 'package:parallax/logic/bloc/mission_bloc.dart';
import 'package:parallax/logic/bloc/mission_events.dart';
import 'package:parallax/logic/bloc/mission_states.dart';

class SiteDetailScreen extends StatelessWidget {
  final int? siteId;
  final SiteModel? initialSite;

  const SiteDetailScreen({super.key, this.siteId, this.initialSite});

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
        final site =
            initialSite ?? (siteId == null ? null : data.findSite(siteId!));

        if (site == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(title: const Text('Site details')),
            body: AppEmptyState(
              icon: Icons.search_off_rounded,
              title: 'Site not found',
              message:
                  'Open a site from the Explore list to see its full profile.',
              actionLabel: 'Back to explore',
              onAction: () => context.go('/explore'),
            ),
          );
        }

        return BlocBuilder<MissionBloc, MissionState>(
          builder: (context, mission) {
            return _SiteDetailContent(data: data, mission: mission, site: site);
          },
        );
      },
    );
  }
}

class _SiteDetailContent extends StatelessWidget {
  final AnalogsData data;
  final MissionState mission;
  final SiteModel site;

  const _SiteDetailContent({
    required this.data,
    required this.mission,
    required this.site,
  });

  @override
  Widget build(BuildContext context) {
    final current = data.findSiteIn(mission.target, site.siteId) ?? site;
    final otherTarget = mission.target == 'Moon' ? 'Mars' : 'Moon';
    final other = data.findSiteIn(otherTarget, site.siteId);
    final reference = data.references[mission.target];
    final isShortlisted = mission.shortlist.contains(current.siteId);
    final recommendedForBoth = data.isRecommendedInBoth(current.siteId);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Site details'),
        actions: [
          IconButton(
            onPressed: () => _toggleShortlist(context, mission, current),
            icon: Icon(
              isShortlisted
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              color: isShortlisted ? AppColors.accent : AppColors.textPrimary,
            ),
          ),
        ],
      ),
      body: AppBackground(
        imageOpacity: 0.08,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 130),
          children: [
            _SiteHeader(site: current, recommendedForBoth: recommendedForBoth),
            const SizedBox(height: 16),
            _ScoreCard(site: current, target: mission.target),
            if (other != null) ...[
              const SizedBox(height: 10),
              _CrossTargetCard(
                otherTarget: otherTarget,
                other: other,
                onTap: () => context.read<MissionBloc>().add(
                  MissionTargetChanged(otherTarget),
                ),
              ),
            ],
            const SizedBox(height: 20),
            const _SectionTitle(
              title: 'Why this site?',
              subtitle: 'Condition groups with a reported weakness.',
            ),
            const SizedBox(height: 9),
            _WhyCard(site: current),
            const SizedBox(height: 20),
            const _SectionTitle(
              title: 'Conditions vs reference',
              subtitle: 'Measured site values and the target reference.',
            ),
            const SizedBox(height: 9),
            _ConditionsCard(
              site: current,
              target: mission.target,
              reference: reference,
            ),
            const SizedBox(height: 20),
            const _SectionTitle(
              title: 'Trade-offs',
              subtitle: 'What to plan for if you select this site.',
            ),
            const SizedBox(height: 9),
            _TradeOffsCard(site: current),
            const SizedBox(height: 20),
            _LocationCard(site: current),
          ],
        ),
      ),
      bottomNavigationBar: _ActionBar(
        isShortlisted: isShortlisted,
        onShortlist: () => _toggleShortlist(context, mission, current),
        onCompare: () {
          if (!isShortlisted) {
            if (mission.shortlist.length >= 3) {
              _showFullShortlistMessage(context);
              return;
            }
            context.read<MissionBloc>().add(
              MissionShortlistToggled(current.siteId),
            );
          }
          context.go('/shortlist');
        },
      ),
    );
  }

  void _toggleShortlist(
    BuildContext context,
    MissionState mission,
    SiteModel current,
  ) {
    final isIn = mission.shortlist.contains(current.siteId);
    if (!isIn && mission.shortlist.length >= 3) {
      _showFullShortlistMessage(context);
      return;
    }
    context.read<MissionBloc>().add(MissionShortlistToggled(current.siteId));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            isIn
                ? '${current.name} removed from shortlist.'
                : '${current.name} added to shortlist.',
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _showFullShortlistMessage(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('You can compare up to 3 sites.'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

class _SiteHeader extends StatelessWidget {
  final SiteModel site;
  final bool recommendedForBoth;

  const _SiteHeader({required this.site, required this.recommendedForBoth});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 7,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
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
            StatusPill(status: site.status),
            if (site.inTop10)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentLight.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'TOP 10',
                  style: TextStyle(
                    color: AppColors.accentLight,
                    fontSize: 8,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            if (recommendedForBoth)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.recommended.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      color: AppColors.recommended,
                      size: 11,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'BOTH TARGETS',
                      style: TextStyle(
                        color: AppColors.recommended,
                        fontSize: 8,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          site.name,
          style: AppTypography.screenTitle.copyWith(fontSize: 30),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 10,
          runSpacing: 5,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.terrain_outlined,
                  color: AppColors.textMuted,
                  size: 13,
                ),
                const SizedBox(width: 4),
                Text(
                  site.analogType,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
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
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final SiteModel site;
  final String target;

  const _ScoreCard({required this.site, required this.target});

  @override
  Widget build(BuildContext context) {
    final value = (site.similarityScore / 100).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.surfaceLight.withValues(alpha: 0.36),
            AppColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.surfaceLight.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 78,
            height: 78,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: value,
                  strokeWidth: 6,
                  backgroundColor: AppColors.surfaceLight.withValues(
                    alpha: 0.35,
                  ),
                  valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                ),
                Center(
                  child: Text(
                    formatScore(site.similarityScore),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Relative score',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                ),
                const SizedBox(height: 2),
                Text(
                  'Rank #${site.rank} for $target',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Environmental distance ${formatDistance(site.distance)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 6),
                WarningPill(level: site.warningLevel),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CrossTargetCard extends StatelessWidget {
  final String otherTarget;
  final SiteModel other;
  final VoidCallback onTap;

  const _CrossTargetCard({
    required this.otherTarget,
    required this.other,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.surfaceLight.withValues(alpha: 0.45),
          ),
        ),
        child: Row(
          children: [
            Icon(
              otherTarget == 'Moon'
                  ? Icons.nightlight_round
                  : Icons.public_rounded,
              color: otherTarget == 'Moon'
                  ? AppColors.accent
                  : AppColors.notRecommended,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Also ranked #${other.rank} for $otherTarget',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ),
            StatusPill(status: other.status),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 17,
            ),
          ],
        ),
      ),
    );
  }
}

class _WhyCard extends StatelessWidget {
  final SiteModel site;

  const _WhyCard({required this.site});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: AppColors.surfaceLight.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        children: [
          for (var index = 0; index < conditionGroups.length; index++) ...[
            _GroupRow(group: conditionGroups[index], site: site),
            if (index != conditionGroups.length - 1)
              Divider(
                height: 17,
                color: AppColors.surfaceLight.withValues(alpha: 0.3),
              ),
          ],
        ],
      ),
    );
  }
}

class _GroupRow extends StatelessWidget {
  final ConditionGroup group;
  final SiteModel site;

  const _GroupRow({required this.group, required this.site});

  @override
  Widget build(BuildContext context) {
    final weakInGroup = group.conditions
        .where((condition) => site.isWeakOn(condition.key))
        .toList(growable: false);
    final isClean = weakInGroup.isEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: (isClean ? AppColors.recommended : AppColors.warningCaution)
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            group.icon,
            color: isClean ? AppColors.recommended : AppColors.warningCaution,
            size: 16,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                group.title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isClean
                    ? 'No reported weakness'
                    : weakInGroup
                          .map((condition) => conditionLabel(condition.key))
                          .join(', '),
                style: TextStyle(
                  color: isClean
                      ? AppColors.textSecondary
                      : AppColors.warningCaution,
                  fontSize: 10,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        Icon(
          isClean
              ? Icons.check_circle_outline_rounded
              : Icons.warning_amber_rounded,
          color: isClean ? AppColors.recommended : AppColors.warningCaution,
          size: 16,
        ),
      ],
    );
  }
}

class _ConditionsCard extends StatelessWidget {
  final SiteModel site;
  final String target;
  final ReferenceModel? reference;

  const _ConditionsCard({
    required this.site,
    required this.target,
    required this.reference,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 13, 15, 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: AppColors.surfaceLight.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Condition',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(
                width: 74,
                child: Text(
                  'Site',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(
                width: 74,
                child: Text(
                  target,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 18),
            ],
          ),
          const SizedBox(height: 3),
          for (final key in allConditionKeys)
            _ConditionComparisonRow(
              conditionKey: key,
              siteValue: site.conditions[key] ?? 0,
              referenceValue: reference?.valueFor(key) ?? 0,
              isWeak: site.isWeakOn(key),
            ),
        ],
      ),
    );
  }
}

class _ConditionComparisonRow extends StatelessWidget {
  final String conditionKey;
  final double siteValue;
  final double referenceValue;
  final bool isWeak;

  const _ConditionComparisonRow({
    required this.conditionKey,
    required this.siteValue,
    required this.referenceValue,
    required this.isWeak,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              conditionShortLabel(conditionKey),
              style: TextStyle(
                color: isWeak ? AppColors.textPrimary : AppColors.textSecondary,
                fontSize: 10,
                fontWeight: isWeak ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          SizedBox(
            width: 74,
            child: Text(
              formatConditionValue(conditionKey, siteValue),
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(
            width: 74,
            child: Text(
              formatConditionValue(conditionKey, referenceValue),
              textAlign: TextAlign.right,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
            ),
          ),
          SizedBox(
            width: 18,
            child: Icon(
              isWeak ? Icons.warning_amber_rounded : Icons.check_rounded,
              color: isWeak ? AppColors.warningCaution : AppColors.recommended,
              size: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _TradeOffsCard extends StatelessWidget {
  final SiteModel site;

  const _TradeOffsCard({required this.site});

  @override
  Widget build(BuildContext context) {
    if (site.weakConditions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.recommended.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: AppColors.recommended.withValues(alpha: 0.3),
          ),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              color: AppColors.recommended,
              size: 18,
            ),
            SizedBox(width: 9),
            Expanded(
              child: Text(
                'No reported weaknesses. This site matches the reference on all measured conditions.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(15, 6, 15, 6),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: AppColors.surfaceLight.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        children: [
          for (var index = 0; index < site.weakConditions.length; index++) ...[
            _TradeOffRow(weak: site.weakConditions[index]),
            if (index != site.weakConditions.length - 1)
              Divider(
                height: 16,
                color: AppColors.surfaceLight.withValues(alpha: 0.3),
              ),
          ],
        ],
      ),
    );
  }
}

class _TradeOffRow extends StatelessWidget {
  final WeakCondition weak;

  const _TradeOffRow({required this.weak});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.warningCaution.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.warningCaution,
              size: 15,
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
                        conditionLabel(weak.feature),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${formatConditionValue(weak.feature, weak.siteValue)} '
                      'vs ${formatConditionValue(weak.feature, weak.referenceValue)}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  tradeOffExplanation(weak.feature),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final SiteModel site;

  const _LocationCard({required this.site});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: AppColors.surfaceLight.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.public_rounded,
              color: AppColors.accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Location',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 9),
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatCoordinate(site.lat, isLatitude: true)}, '
                  '${formatCoordinate(site.lon, isLatitude: false)}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Labeled as ${site.labeledAs}',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
              ),
              const SizedBox(height: 3),
              Text(
                'Distance ${formatDistance(site.distance)}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
        ),
      ],
    );
  }
}

class _ActionBar extends StatelessWidget {
  final bool isShortlisted;
  final VoidCallback onShortlist;
  final VoidCallback onCompare;

  const _ActionBar({
    required this.isShortlisted,
    required this.onShortlist,
    required this.onCompare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.97),
        border: Border(
          top: BorderSide(color: AppColors.surfaceLight.withValues(alpha: 0.4)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onShortlist,
                icon: Icon(
                  isShortlisted
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  size: 17,
                ),
                label: Text(
                  isShortlisted ? 'In shortlist' : 'Add to shortlist',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: BorderSide(
                    color: AppColors.accent.withValues(alpha: 0.55),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: onCompare,
                icon: const Icon(Icons.compare_arrows_rounded, size: 18),
                label: const Text('Compare'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
