import 'package:parallax/core/constants/condition_catalog.dart';
import 'package:parallax/data/models/site_model.dart';

class MissionFilter {
  MissionFilter._();

  static List<SiteModel> apply(
    List<SiteModel> sites, {
    required Set<String> conditions,
    required String statusFilter,
    required bool top10Only,
    required bool lowRiskOnly,
    required String searchQuery,
    required String sortBy,
  }) {
    final query = searchQuery.trim().toLowerCase();
    final result = sites.where((site) {
      if (!matchesStatus(site, statusFilter)) return false;
      if (top10Only && !site.inTop10) return false;
      if (lowRiskOnly && warningSeverity(site.warningLevel) >= 2) {
        return false;
      }
      if (conditions.isNotEmpty &&
          site.weakConditions.any(
            (weak) => conditions.contains(weak.feature),
          )) {
        return false;
      }
      if (query.isNotEmpty && !site.name.toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList();

    switch (sortBy) {
      case 'name':
        result.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      case 'distance':
        result.sort((a, b) => a.distance.compareTo(b.distance));
      default:
        result.sort((a, b) => a.rank.compareTo(b.rank));
    }
    return result;
  }

  static bool matchesStatus(SiteModel site, String statusFilter) {
    switch (statusFilter) {
      case 'Recommended':
        return site.status == 'Recommended';
      case 'Acceptable':
        return site.status == 'Acceptable';
      case 'Not recommended':
        return site.status == 'Not recommended';
      case 'All':
        return true;
      case 'Usable':
      default:
        return site.status != 'Not recommended';
    }
  }

  /// identify the weak condition on the selected sites
  static Map<String, int> conditionImpactCounts(
    List<SiteModel> sites, {
    required String statusFilter,
    required bool lowRiskOnly,
  }) {
    final base = sites.where((site) {
      if (!matchesStatus(site, statusFilter)) return false;
      if (lowRiskOnly && warningSeverity(site.warningLevel) >= 2) {
        return false;
      }
      return true;
    }).toList();

    return {
      for (final key in allConditionKeys)
        key: base.where((site) => site.isWeakOn(key)).length,
    };
  }

  static int countForPreset(List<SiteModel> sites, MissionPreset preset) {
    return apply(
      sites,
      conditions: preset.conditions,
      statusFilter: 'Usable',
      top10Only: false,
      lowRiskOnly: preset.lowRiskOnly,
      searchQuery: '',
      sortBy: 'rank',
    ).length;
  }
}

String profileLabel({
  required Set<String> conditions,
  required bool lowRiskOnly,
}) {
  if (conditions.isEmpty && !lowRiskOnly) return 'Balanced';
  if (conditions.isEmpty && lowRiskOnly) return 'Low-risk';
  for (final preset in missionPresets) {
    if (preset.lowRiskOnly == lowRiskOnly &&
        preset.conditions.length == conditions.length &&
        preset.conditions.containsAll(conditions)) {
      return preset.name;
    }
  }
  return 'Custom';
}

String formatConditionValue(String key, double value) {
  switch (key) {
    case 'temp_avg':
    case 'temp_max':
    case 'temp_min':
      return '${value.toStringAsFixed(1)}°C';
    case 'pressure':
      return '${value.toStringAsFixed(1)} hPa';
    case 'wind':
      return '${value.toStringAsFixed(1)} m/s';
    case 'solar_radiation':
      return '${value.toStringAsFixed(0)} W/m²';
    case 'uv_index':
      return value.toStringAsFixed(1);
    case 'humidity':
      return '${value.toStringAsFixed(1)}%';
    case 'rainfall':
      return '${value.toStringAsFixed(2)} mm/day';
    case 'elevation':
      return '${value.toStringAsFixed(0)} m';
    default:
      return value.toStringAsFixed(2);
  }
}

String formatCoordinate(double value, {required bool isLatitude}) {
  final direction = isLatitude
      ? (value >= 0 ? 'N' : 'S')
      : (value >= 0 ? 'E' : 'W');
  return '${value.abs().toStringAsFixed(2)}°$direction';
}

String formatDistance(double value) => value.toStringAsFixed(2);

String formatScore(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(1);

int warningSeverity(String level) {
  switch (level.toLowerCase()) {
    case 'high':
      return 2;
    case 'caution':
      return 1;
    case 'none':
      return 0;
    default:
      return 0;
  }
}

int statusRank(String status) {
  switch (status) {
    case 'Recommended':
      return 2;
    case 'Acceptable':
      return 1;
    default:
      return 0;
  }
}

String tradeOffExplanation(String feature) {
  switch (feature) {
    case 'temp_avg':
      return 'Average temperature differs from the reference. Thermal control needs attention.';
    case 'temp_max':
      return 'Peak temperature is far from the reference. Check equipment heat tolerance.';
    case 'temp_min':
      return 'Minimum temperature differs from the reference. Plan for cold-soak testing.';
    case 'pressure':
      return 'Pressure differs from the reference. Pressure-suited operations may be required.';
    case 'wind':
      return 'Wind exposure differs from the reference. Consider dust and mechanical stress.';
    case 'solar_radiation':
      return 'Solar radiation differs from the reference. Power and shielding assumptions change.';
    case 'uv_index':
      return 'UV exposure differs from the reference. Review shielding and material aging.';
    case 'humidity':
      return 'Humidity differs from the reference. Corrosion and condensation risks change.';
    case 'rainfall':
      return 'Rainfall differs from the reference. Water intrusion and erosion risks change.';
    case 'elevation':
      return 'Elevation differs from the reference. Expect different air density and access conditions.';
    default:
      return 'This condition differs from the reference environment.';
  }
}

List<String> cleanGroupsFor(SiteModel site) {
  final clean = <String>[];
  for (final group in conditionGroups) {
    final hasWeakness = group.conditions.any(
      (condition) => site.isWeakOn(condition.key),
    );
    if (!hasWeakness) clean.add(group.title);
  }
  return clean;
}

String weakestConditionLabel(SiteModel site) {
  if (site.weakConditions.isEmpty) return 'None reported';
  return conditionLabel(site.weakConditions.first.feature);
}
