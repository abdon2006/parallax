import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:parallax/core/constants/app_colors.dart';
import 'package:parallax/core/constants/app_typography.dart';
import 'package:parallax/core/constants/condition_catalog.dart';
import 'package:parallax/core/utils/mission_utils.dart';
import 'package:parallax/core/widgets/app_background.dart';
import 'package:parallax/core/widgets/app_states.dart';
import 'package:parallax/core/widgets/site_card.dart';
import 'package:parallax/core/widgets/status_pill.dart';
import 'package:parallax/data/models/analogs_data.dart';
import 'package:parallax/data/models/site_model.dart';
import 'package:parallax/logic/bloc/analog_bloc.dart';
import 'package:parallax/logic/bloc/analog_events.dart';
import 'package:parallax/logic/bloc/analog_states.dart';
import 'package:parallax/logic/bloc/mission_bloc.dart';
import 'package:parallax/logic/bloc/mission_events.dart';
import 'package:parallax/logic/bloc/mission_states.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: context.read<MissionBloc>().state.searchQuery,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MissionBloc, MissionState>(
      listenWhen: (previous, current) =>
          previous.searchQuery != current.searchQuery,
      listener: (context, state) {
        if (_searchController.text == state.searchQuery) return;
        _searchController
          ..text = state.searchQuery
          ..selection = TextSelection.collapsed(
            offset: state.searchQuery.length,
          );
      },
      child: AppBackground(
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
                  return _ExploreContent(
                    data: data,
                    mission: mission,
                    searchController: _searchController,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ExploreContent extends StatelessWidget {
  final AnalogsData data;
  final MissionState mission;
  final TextEditingController searchController;

  const _ExploreContent({
    required this.data,
    required this.mission,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    final sites = data.sitesFor(mission.target);
    final filtered = MissionFilter.apply(
      sites,
      conditions: mission.conditions,
      statusFilter: mission.statusFilter,
      top10Only: mission.top10Only,
      lowRiskOnly: mission.lowRiskOnly,
      searchQuery: mission.searchQuery,
      sortBy: mission.sortBy,
    );
    final recommendedCount = sites
        .where((site) => site.status == 'Recommended')
        .length;
    final sections = _buildSections(filtered, mission.statusFilter);
    final showTopStrip =
        mission.conditions.isEmpty &&
        !mission.lowRiskOnly &&
        !mission.top10Only &&
        mission.searchQuery.trim().isEmpty &&
        mission.statusFilter == 'Usable';
    final items = <Object>[];
    for (final section in sections) {
      items.add(section);
      items.addAll(section.sites);
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _ExploreHeader(
            mission: mission,
            totalSites: sites.length,
            filteredCount: filtered.length,
            recommendedCount: recommendedCount,
            searchController: searchController,
          ),
        ),
        if (showTopStrip && filtered.isNotEmpty)
          SliverToBoxAdapter(
            child: _TopStrip(
              sites: filtered.take(3).toList(),
              onViewAll: () =>
                  context.read<MissionBloc>().add(const MissionTop10Toggled()),
              onOpen: (site) =>
                  context.push('/site/${site.siteId}', extra: site),
            ),
          ),
        if (filtered.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: AppEmptyState(
              icon: Icons.tune_rounded,
              title: 'No sites match this profile',
              message: 'Try removing a condition, widening the status filter, or clearing the search.',
              actionLabel: 'Reset filters',
              onAction: () {
                searchController.clear();
                context.read<MissionBloc>().add(const MissionProfileReset());
              },
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                if (item is _SiteSection) {
                  return Padding(
                    padding: EdgeInsets.only(
                      top: index == 0 ? 16 : 22,
                      bottom: 10,
                    ),
                    child: AppSectionHeader(
                      title: item.title,
                      subtitle: item.subtitle,
                      count: item.sites.length,
                    ),
                  );
                }
                final site = item as SiteModel;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SiteCard(
                    site: site,
                    onTap: () =>
                        context.push('/site/${site.siteId}', extra: site),
                  ),
                );
              },
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 28)),
      ],
    );
  }

  List<_SiteSection> _buildSections(
    List<SiteModel> filtered,
    String statusFilter,
  ) {
    final sections = <_SiteSection>[];
    final recommended = filtered
        .where((site) => site.status == 'Recommended')
        .toList(growable: false);
    final acceptable = filtered
        .where((site) => site.status == 'Acceptable')
        .toList(growable: false);
    final notRecommended = filtered
        .where((site) => site.status == 'Not recommended')
        .toList(growable: false);

    if (statusFilter == 'Usable' || statusFilter == 'Recommended') {
      if (recommended.isNotEmpty) {
        sections.add(
          _SiteSection(
            title: 'Recommended',
            subtitle: 'Best environmental fit.',
            sites: recommended,
          ),
        );
      }
    }
    if (statusFilter == 'Usable' || statusFilter == 'Acceptable') {
      if (acceptable.isNotEmpty) {
        sections.add(
          _SiteSection(
            title: 'Acceptable',
            subtitle: 'Usable with trade-offs.',
            sites: acceptable,
          ),
        );
      }
    }
    if (statusFilter == 'All') {
      if (recommended.isNotEmpty) {
        sections.add(
          _SiteSection(
            title: 'Recommended',
            subtitle: 'Best environmental fit.',
            sites: recommended,
          ),
        );
      }
      if (acceptable.isNotEmpty) {
        sections.add(
          _SiteSection(
            title: 'Acceptable',
            subtitle: 'Usable with trade-offs.',
            sites: acceptable,
          ),
        );
      }
      if (notRecommended.isNotEmpty) {
        sections.add(
          _SiteSection(
            title: 'Not recommended',
            subtitle: 'Outside the usable range.',
            sites: notRecommended,
          ),
        );
      }
    }
    if (statusFilter == 'Not recommended' && notRecommended.isNotEmpty) {
      sections.add(
        _SiteSection(
          title: 'Not recommended',
          subtitle: 'Outside the usable range.',
          sites: notRecommended,
        ),
      );
    }
    return sections;
  }
}

class _SiteSection {
  final String title;
  final String subtitle;
  final List<SiteModel> sites;

  const _SiteSection({
    required this.title,
    required this.subtitle,
    required this.sites,
  });
}

class _ExploreHeader extends StatelessWidget {
  final MissionState mission;
  final int totalSites;
  final int filteredCount;
  final int recommendedCount;
  final TextEditingController searchController;

  const _ExploreHeader({
    required this.mission,
    required this.totalSites,
    required this.filteredCount,
    required this.recommendedCount,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    final profile = profileLabel(
      conditions: mission.conditions,
      lowRiskOnly: mission.lowRiskOnly,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Explore analogs',
            style: AppTypography.screenTitle.copyWith(fontSize: 30),
          ),
          const SizedBox(height: 5),
          Text(
            'Ranked by environmental similarity to the ${mission.target}.',
            style: AppTypography.body.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _TargetSegment(
                  label: 'Moon',
                  selected: mission.target == 'Moon',
                  color: AppColors.accent,
                  onTap: () => context.read<MissionBloc>().add(
                    const MissionTargetChanged('Moon'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TargetSegment(
                  label: 'Mars',
                  selected: mission.target == 'Mars',
                  color: AppColors.notRecommended,
                  onTap: () => context.read<MissionBloc>().add(
                    const MissionTargetChanged('Mars'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ProfileBar(profile: profile, count: filteredCount, mission: mission),
          const SizedBox(height: 12),
          TextField(
            controller: searchController,
            onChanged: (value) =>
                context.read<MissionBloc>().add(MissionSearchChanged(value)),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Search by site name',
              hintStyle: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.textMuted,
                size: 18,
              ),
              suffixIcon: mission.searchQuery.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        searchController.clear();
                        context.read<MissionBloc>().add(
                          const MissionSearchChanged(''),
                        );
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textMuted,
                        size: 16,
                      ),
                    ),
              filled: true,
              fillColor: AppColors.surface.withValues(alpha: 0.85),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: AppColors.surfaceLight.withValues(alpha: 0.45),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: AppColors.surfaceLight.withValues(alpha: 0.45),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.accent),
              ),
            ),
          ),
          const SizedBox(height: 11),
          _StatusChips(mission: mission),
          const SizedBox(height: 5),
          _FilterRow(mission: mission),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '$filteredCount sites',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '· $recommendedCount recommended · $totalSites total',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TargetSegment extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TargetSegment({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.14)
              : AppColors.surface.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.6)
                : AppColors.surfaceLight.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              label == 'Moon' ? Icons.nightlight_round : Icons.public_rounded,
              color: selected ? color : AppColors.textMuted,
              size: 15,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? color : AppColors.textMuted,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileBar extends StatelessWidget {
  final String profile;
  final int count;
  final MissionState mission;

  const _ProfileBar({
    required this.profile,
    required this.count,
    required this.mission,
  });

  @override
  Widget build(BuildContext context) {
    final hasConditions = mission.conditions.isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.surfaceLight.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: AppColors.accent,
              size: 16,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$profile profile',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasConditions
                      ? mission.conditions.map(conditionShortLabel).join(' · ')
                      : mission.lowRiskOnly
                      ? 'High warnings hidden'
                      : 'No hard constraints',
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
          Text(
            '$count',
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 2),
          TextButton(
            onPressed: () => context.push('/fine-tune'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Edit',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChips extends StatelessWidget {
  final MissionState mission;

  const _StatusChips({required this.mission});

  static const _options = [
    ('Usable', 'Usable'),
    ('Recommended', 'Recommended'),
    ('Acceptable', 'Acceptable'),
    ('Not recommended', 'Not recommended'),
    ('All', 'All'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final option in _options) ...[
            ChoiceChip(
              label: Text(option.$2),
              selected: mission.statusFilter == option.$1,
              onSelected: (_) => context.read<MissionBloc>().add(
                MissionStatusFilterChanged(option.$1),
              ),
              showCheckmark: false,
              labelStyle: TextStyle(
                color: mission.statusFilter == option.$1
                    ? AppColors.background
                    : AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              selectedColor: AppColors.accent,
              backgroundColor: AppColors.surface,
              side: BorderSide(
                color: AppColors.surfaceLight.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(width: 7),
          ],
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final MissionState mission;

  const _FilterRow({required this.mission});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Top 10'),
                  selected: mission.top10Only,
                  onSelected: (_) => context.read<MissionBloc>().add(
                    const MissionTop10Toggled(),
                  ),
                  showCheckmark: false,
                  labelStyle: TextStyle(
                    color: mission.top10Only
                        ? AppColors.background
                        : AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  selectedColor: AppColors.accent,
                  backgroundColor: AppColors.surface,
                  side: BorderSide(
                    color: AppColors.surfaceLight.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(width: 7),
                FilterChip(
                  label: const Text('Low-risk'),
                  selected: mission.lowRiskOnly,
                  onSelected: (_) => context.read<MissionBloc>().add(
                    const MissionLowRiskToggled(),
                  ),
                  showCheckmark: false,
                  labelStyle: TextStyle(
                    color: mission.lowRiskOnly
                        ? AppColors.background
                        : AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  selectedColor: AppColors.accent,
                  backgroundColor: AppColors.surface,
                  side: BorderSide(
                    color: AppColors.surfaceLight.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          initialValue: mission.sortBy,
          onSelected: (value) =>
              context.read<MissionBloc>().add(MissionSortChanged(value)),
          color: AppColors.surface,
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'rank', child: Text('Best match')),
            PopupMenuItem(value: 'distance', child: Text('Distance')),
            PopupMenuItem(value: 'name', child: Text('Name A–Z')),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.surfaceLight.withValues(alpha: 0.55),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.sort_rounded,
                  color: AppColors.textSecondary,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  switch (mission.sortBy) {
                    'name' => 'Name',
                    'distance' => 'Distance',
                    _ => 'Match',
                  },
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TopStrip extends StatelessWidget {
  final List<SiteModel> sites;
  final VoidCallback onViewAll;
  final ValueChanged<SiteModel> onOpen;

  const _TopStrip({
    required this.sites,
    required this.onViewAll,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        children: [
          AppSectionHeader(
            title: 'Top matches',
            subtitle: 'The strongest matches in this dataset.',
            trailing: TextButton(
              onPressed: onViewAll,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'View top 10',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 132,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: sites.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final site = sites[index];
                return _TopAnalogCard(site: site, onTap: () => onOpen(site));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TopAnalogCard extends StatelessWidget {
  final SiteModel site;
  final VoidCallback onTap;

  const _TopAnalogCard({required this.site, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 196,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.surfaceLight.withValues(alpha: 0.42),
              AppColors.surface,
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '#${site.rank}',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  formatScore(site.similarityScore),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const Spacer(),
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
            const SizedBox(height: 2),
            Text(
              site.analogType,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
            ),
            const SizedBox(height: 7),
            StatusPill(status: site.status),
          ],
        ),
      ),
    );
  }
}
