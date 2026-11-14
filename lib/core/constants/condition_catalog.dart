import 'package:flutter/material.dart';

class ConditionInfo {
  final String key;
  final String label;
  final String shortLabel;
  final String unit;
  final String whyItMatters;

  const ConditionInfo({
    required this.key,
    required this.label,
    required this.shortLabel,
    required this.unit,
    required this.whyItMatters,
  });
}

class ConditionGroup {
  final String title;
  final IconData icon;
  final List<ConditionInfo> conditions;

  const ConditionGroup({
    required this.title,
    required this.icon,
    required this.conditions,
  });
}

class MissionPreset {
  final String name;
  final String description;
  final IconData icon;
  final Set<String> conditions;
  final bool lowRiskOnly;

  const MissionPreset({
    required this.name,
    required this.description,
    required this.icon,
    required this.conditions,
    required this.lowRiskOnly,
  });
}

const List<ConditionGroup> conditionGroups = [
  ConditionGroup(
    title: 'Temperature',
    icon: Icons.thermostat_rounded,
    conditions: [
      ConditionInfo(
        key: 'temp_avg',
        label: 'Average temperature',
        shortLabel: 'Avg temp',
        unit: '°C',
        whyItMatters: 'Drives thermal control and crew comfort.',
      ),
      ConditionInfo(
        key: 'temp_max',
        label: 'Maximum temperature',
        shortLabel: 'Max temp',
        unit: '°C',
        whyItMatters: 'Tests equipment heat tolerance.',
      ),
      ConditionInfo(
        key: 'temp_min',
        label: 'Minimum temperature',
        shortLabel: 'Min temp',
        unit: '°C',
        whyItMatters: 'Sets cold-soak requirements.',
      ),
    ],
  ),
  ConditionGroup(
    title: 'Atmosphere',
    icon: Icons.air_rounded,
    conditions: [
      ConditionInfo(
        key: 'pressure',
        label: 'Atmospheric pressure',
        shortLabel: 'Pressure',
        unit: 'hPa',
        whyItMatters: 'Affects pressure suits and sealed habitats.',
      ),
      ConditionInfo(
        key: 'wind',
        label: 'Wind speed',
        shortLabel: 'Wind',
        unit: 'm/s',
        whyItMatters: 'Drives dust exposure and mechanical stress.',
      ),
    ],
  ),
  ConditionGroup(
    title: 'Radiation',
    icon: Icons.wb_sunny_outlined,
    conditions: [
      ConditionInfo(
        key: 'solar_radiation',
        label: 'Solar radiation',
        shortLabel: 'Solar',
        unit: 'W/m²',
        whyItMatters: 'Sets power budgets and shielding needs.',
      ),
      ConditionInfo(
        key: 'uv_index',
        label: 'UV index',
        shortLabel: 'UV',
        unit: '',
        whyItMatters: 'Affects material aging and exposure limits.',
      ),
    ],
  ),
  ConditionGroup(
    title: 'Moisture',
    icon: Icons.water_drop_outlined,
    conditions: [
      ConditionInfo(
        key: 'humidity',
        label: 'Humidity',
        shortLabel: 'Humidity',
        unit: '%',
        whyItMatters: 'Changes corrosion and condensation risks.',
      ),
      ConditionInfo(
        key: 'rainfall',
        label: 'Rainfall',
        shortLabel: 'Rain',
        unit: 'mm/day',
        whyItMatters: 'Introduces water intrusion and erosion.',
      ),
    ],
  ),
  ConditionGroup(
    title: 'Terrain',
    icon: Icons.terrain_rounded,
    conditions: [
      ConditionInfo(
        key: 'elevation',
        label: 'Elevation',
        shortLabel: 'Elevation',
        unit: 'm',
        whyItMatters: 'Changes air density, access, and training value.',
      ),
    ],
  ),
];

final List<String> allConditionKeys = [
  for (final group in conditionGroups)
    for (final condition in group.conditions) condition.key,
];

const List<MissionPreset> missionPresets = [
  MissionPreset(
    name: 'Balanced',
    description: 'No hard constraints',
    icon: Icons.balance_rounded,
    conditions: {},
    lowRiskOnly: false,
  ),
  MissionPreset(
    name: 'Thermal',
    description: 'Temperature first',
    icon: Icons.thermostat_rounded,
    conditions: {'temp_avg', 'temp_max', 'temp_min'},
    lowRiskOnly: false,
  ),
  MissionPreset(
    name: 'Atmosphere',
    description: 'Pressure and wind',
    icon: Icons.air_rounded,
    conditions: {'pressure', 'wind'},
    lowRiskOnly: false,
  ),
  MissionPreset(
    name: 'Radiation',
    description: 'Solar and UV',
    icon: Icons.wb_sunny_outlined,
    conditions: {'solar_radiation', 'uv_index'},
    lowRiskOnly: false,
  ),
  MissionPreset(
    name: 'Low-risk',
    description: 'Avoid high warnings',
    icon: Icons.verified_outlined,
    conditions: {},
    lowRiskOnly: true,
  ),
];

ConditionInfo? conditionInfo(String key) {
  for (final group in conditionGroups) {
    for (final condition in group.conditions) {
      if (condition.key == key) return condition;
    }
  }
  return null;
}

String conditionLabel(String key) {
  final info = conditionInfo(key);
  if (info != null) return info.label;
  return key.replaceAll('_', ' ');
}

String conditionShortLabel(String key) {
  final info = conditionInfo(key);
  if (info != null) return info.shortLabel;
  return key.replaceAll('_', ' ');
}

String conditionUnit(String key) => conditionInfo(key)?.unit ?? '';

MissionPreset? presetByName(String name) {
  for (final preset in missionPresets) {
    if (preset.name == name) return preset;
  }
  return null;
}
