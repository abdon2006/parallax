import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:parallax/core/constants/app_colors.dart';
import 'package:parallax/core/constants/condition_catalog.dart';
import 'package:parallax/core/utils/mission_utils.dart';
import 'package:parallax/core/widgets/app_animated_entry.dart';
import 'package:parallax/core/widgets/app_background.dart';
import 'package:parallax/core/widgets/app_states.dart';
import 'package:parallax/data/models/analogs_data.dart';
import 'package:parallax/logic/bloc/analog_bloc.dart';
import 'package:parallax/logic/bloc/analog_events.dart';
import 'package:parallax/logic/bloc/analog_states.dart';
import 'package:parallax/logic/bloc/mission_bloc.dart';
import 'package:parallax/logic/bloc/mission_events.dart';
import 'package:parallax/logic/bloc/mission_states.dart';

class FineTuneScreen extends StatelessWidget {
  const FineTuneScreen({super.key});

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
            return _FineTuneContent(data: data, mission: mission);
          },
        );
      },
    );
  }
}

class _FineTuneContent extends StatelessWidget {
  final AnalogsData data;
  final MissionState mission;

  const _FineTuneContent({required this.data, required this.mission});

  @override
  Widget build(BuildContext context) {
    final sites = data.sitesFor(mission.target);
    final impacts = MissionFilter.conditionImpactCounts(
      sites,
      statusFilter: mission.statusFilter,
      lowRiskOnly: mission.lowRiskOnly,
    );
    final preview = MissionFilter.apply(
      sites,
      conditions: mission.conditions,
      statusFilter: mission.statusFilter,
      top10Only: false,
      lowRiskOnly: mission.lowRiskOnly,
      searchQuery: '',
      sortBy: 'rank',
    );
    final label = profileLabel(
      conditions: mission.conditions,
      lowRiskOnly: mission.lowRiskOnly,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Fine-tune profile'),
        actions: [
          TextButton(
            onPressed: () =>
                context.read<MissionBloc>().add(const MissionProfileReset()),
            child: const Text(
              'Reset',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
      body: AppBackground(
        imageOpacity: 1,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 130),
          children: [
            _TargetSelector(mission: mission),
            const SizedBox(height: 14),
            _ProfileSummary(
              target: mission.target,
              label: label,
              count: preview.length,
              conditions: mission.conditions,
              lowRiskOnly: mission.lowRiskOnly,
            ),
            const SizedBox(height: 20),

            const Text(
              'Select the conditions that matter most. Sites with a reported weakness in any selected condition will be hidden.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            for (final group in conditionGroups) ...[
              AppAnimatedEntry(
                child: _ConditionGroupCard(
                  group: group,
                  selectedConditions: mission.conditions,
                  impacts: impacts,
                  onToggle: (key) => context.read<MissionBloc>().add(
                    MissionConditionToggled(key),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 6),
            _OptionsCard(mission: mission),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.surfaceLight.withValues(alpha: 0.45),
                ),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.accent,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Filtering uses each site\'s reported weak conditions. We do not re-score sites or change the original ranking.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _ApplyBar(
        count: preview.length,
        onApply: () => context.go('/explore'),
      ),
    );
  }
}

class _TargetSelector extends StatelessWidget {
  final MissionState mission;

  const _TargetSelector({required this.mission});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.surfaceLight.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        children: [
          for (final target in ['Moon', 'Mars'])
            Expanded(
              child: _TargetButton(
                label: target,
                selected: mission.target == target,
                color: target == 'Moon'
                    ? AppColors.accent
                    : AppColors.notRecommended,
                onTap: () => context.read<MissionBloc>().add(
                  MissionTargetChanged(target),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TargetButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TargetButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.16) : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? color : AppColors.textMuted,
            fontSize: 16,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ProfileSummary extends StatelessWidget {
  final String target;
  final String label;
  final int count;
  final Set<String> conditions;
  final bool lowRiskOnly;

  const _ProfileSummary({
    required this.target,
    required this.label,
    required this.count,
    required this.conditions,
    required this.lowRiskOnly,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.surfaceLight.withValues(alpha: 0.35),
            AppColors.surface.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: AppColors.accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label profile',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$target · $count matching sites',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
                if (conditions.isNotEmpty || lowRiskOnly) ...[
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 5,
                    runSpacing: 4,
                    children: [
                      for (final condition in conditions)
                        _MiniChip(label: conditionShortLabel(condition)),
                      if (lowRiskOnly) const _MiniChip(label: 'Low-risk'),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Text(
            '$count',
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;

  const _MiniChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.accent,
          fontSize: 8,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ConditionGroupCard extends StatelessWidget {
  final ConditionGroup group;
  final Set<String> selectedConditions;
  final Map<String, int> impacts;
  final ValueChanged<String> onToggle;

  const _ConditionGroupCard({
    required this.group,
    required this.selectedConditions,
    required this.impacts,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: AppColors.surfaceLight.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(group.icon, color: AppColors.accent, size: 17),
              const SizedBox(width: 8),
              Text(
                group.title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (final condition in group.conditions)
            _ConditionRow(
              condition: condition,
              selected: selectedConditions.contains(condition.key),
              impact: impacts[condition.key] ?? 0,
              onTap: () => onToggle(condition.key),
            ),
        ],
      ),
    );
  }
}

class _ConditionRow extends StatelessWidget {
  final ConditionInfo condition;
  final bool selected;
  final int impact;
  final VoidCallback onTap;

  const _ConditionRow({
    required this.condition,
    required this.selected,
    required this.impact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    condition.label,
                    style: TextStyle(
                      color: selected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    condition.whyItMatters,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Tooltip(
              message: 'Sites with this reported weakness',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$impact',
                    style: TextStyle(
                      color: selected ? AppColors.accent : AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Text(
                    'sites',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 8),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 2),
            Switch(
              value: selected,
              onChanged: (_) => onTap(),
              activeThumbColor: AppColors.accent,
              activeTrackColor: AppColors.accent.withValues(alpha: 0.3),
              inactiveThumbColor: AppColors.textMuted,
              inactiveTrackColor: AppColors.surfaceLight.withValues(alpha: 0.4),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionsCard extends StatelessWidget {
  final MissionState mission;

  const _OptionsCard({required this.mission});

  @override
  Widget build(BuildContext context) {
    final includeNotRecommended = mission.statusFilter == 'All';
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: AppColors.surfaceLight.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        children: [
          SwitchListTile(
            value: includeNotRecommended,
            onChanged: (value) => context.read<MissionBloc>().add(
              MissionStatusFilterChanged(value ? 'All' : 'Usable'),
            ),
            activeThumbColor: AppColors.accent,
            title: const Text(
              'Include not recommended sites',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: const Text(
              'Adds sites outside the usable range.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 9),
            ),
          ),
          Divider(
            height: 1,
            color: AppColors.surfaceLight.withValues(alpha: 0.35),
          ),
          SwitchListTile(
            value: mission.lowRiskOnly,
            onChanged: (_) =>
                context.read<MissionBloc>().add(const MissionLowRiskToggled()),
            activeThumbColor: AppColors.accent,
            title: const Text(
              'Low-risk only',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: const Text(
              'Hides sites with a high warning level.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplyBar extends StatelessWidget {
  final int count;
  final VoidCallback onApply;

  const _ApplyBar({required this.count, required this.onApply});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.96),
        border: Border(
          top: BorderSide(
            color: AppColors.surfaceLight.withValues(alpha: 0.45),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    'matching sites',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 9),
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: onApply,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.background,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Apply & explore',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
