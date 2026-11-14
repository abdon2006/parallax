import 'package:equatable/equatable.dart';
import 'package:parallax/core/constants/condition_catalog.dart';

class MissionState extends Equatable {
  static const _targets = {'Moon', 'Mars'};
  static const _statusFilters = {
    'Usable',
    'Recommended',
    'Acceptable',
    'Not recommended',
    'All',
  };
  static const _sortOptions = {'rank', 'name', 'distance'};
  static const _maxShortlist = 3;
  final String target;
  final Set<String> conditions;
  final String statusFilter;
  final bool top10Only;
  final bool lowRiskOnly;
  final String searchQuery;
  final String sortBy;
  final Set<int> shortlist;

  const MissionState({
    this.target = 'Moon',
    this.conditions = const {},
    this.statusFilter = 'Usable',
    this.top10Only = false,
    this.lowRiskOnly = false,
    this.searchQuery = '',
    this.sortBy = 'rank',
    this.shortlist = const {},
  });

  MissionState copyWith({
    String? target,
    Set<String>? conditions,
    String? statusFilter,
    bool? top10Only,
    bool? lowRiskOnly,
    String? searchQuery,
    String? sortBy,
    Set<int>? shortlist,
  }) {
    return MissionState(
      target: target ?? this.target,
      conditions: conditions ?? this.conditions,
      statusFilter: statusFilter ?? this.statusFilter,
      top10Only: top10Only ?? this.top10Only,
      lowRiskOnly: lowRiskOnly ?? this.lowRiskOnly,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      shortlist: shortlist ?? this.shortlist,
    );
  }

  bool get hasProfile =>
      conditions.isNotEmpty || lowRiskOnly || statusFilter != 'Usable';

  Map<String, dynamic> toJson() => {
    'target': target,
    'conditions': conditions.toList(growable: false),
    'statusFilter': statusFilter,
    'lowRiskOnly': lowRiskOnly,
    'sortBy': sortBy,
    'shortlist': shortlist.toList(growable: false),
  };

  factory MissionState.fromJson(Map<String, dynamic> json) {
    final rawConditions = json['conditions'];
    final rawShortlist = json['shortlist'];
    final rawTarget = json['target'];
    final rawStatusFilter = json['statusFilter'];
    final rawSortBy = json['sortBy'];
    final rawLowRisk = json['lowRiskOnly'];

    final conditions = rawConditions is List
        ? rawConditions
              .whereType<String>()
              .where(allConditionKeys.contains)
              .toSet()
        : const <String>{};
    final shortlist = rawShortlist is List
        ? rawShortlist
              .whereType<num>()
              .map((id) => id.toInt())
              .take(_maxShortlist)
              .toSet()
        : const <int>{};

    return MissionState(
      target: rawTarget is String && _targets.contains(rawTarget)
          ? rawTarget
          : 'Moon',
      conditions: conditions,
      statusFilter:
          rawStatusFilter is String && _statusFilters.contains(rawStatusFilter)
          ? rawStatusFilter
          : 'Usable',
      lowRiskOnly: rawLowRisk is bool ? rawLowRisk : false,
      sortBy: rawSortBy is String && _sortOptions.contains(rawSortBy)
          ? rawSortBy
          : 'rank',
      shortlist: shortlist,
    );
  }

  @override
  List<Object?> get props => [
    target,
    conditions,
    statusFilter,
    top10Only,
    lowRiskOnly,
    searchQuery,
    sortBy,
    shortlist,
  ];
}
