import 'package:parallax/data/models/weak_condition.dart';

class SiteModel {
  final int rank;
  final int siteId;
  final String name;
  final String analogType;
  final String labeledAs;
  final double lat;
  final double lon;
  final double distance;
  final double similarityScore;
  final String status;
  final bool inTop10;
  final String warningLevel;
  final String warningText;
  final Map<String, double> conditions;
  final List<WeakCondition> weakConditions;

  const SiteModel({
    required this.rank,
    required this.siteId,
    required this.name,
    required this.analogType,
    required this.labeledAs,
    required this.lat,
    required this.lon,
    required this.distance,
    required this.similarityScore,
    required this.status,
    required this.inTop10,
    required this.warningLevel,
    required this.warningText,
    required this.conditions,
    required this.weakConditions,
  });

  Set<String> get weakFeatures =>
      weakConditions.map((condition) => condition.feature).toSet();

  bool isWeakOn(String feature) => weakFeatures.contains(feature);

  bool get hasWarnings => warningText.trim().isNotEmpty;

  factory SiteModel.fromJson(Map<String, dynamic> json) {
    final rawWeakConditions = json['weak_conditions'] as List<dynamic>? ?? [];
    return SiteModel(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      siteId: (json['site_id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? 'Unknown site',
      analogType: json['analog_type'] as String? ?? 'Unknown',
      labeledAs: json['labeled_as'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lon: (json['lon'] as num?)?.toDouble() ?? 0,
      distance: (json['distance'] as num?)?.toDouble() ?? 0,
      similarityScore: (json['similarity_score'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'Not recommended',
      inTop10: json['in_top10'] as bool? ?? false,
      warningLevel: json['warning_level'] as String? ?? 'n/a',
      warningText: json['warning_text'] as String? ?? '',
      conditions: Map<String, double>.from(
        (json['conditions'] as Map? ?? {}).map(
          (key, value) => MapEntry(key as String, (value as num).toDouble()),
        ),
      ),
      weakConditions: rawWeakConditions
          .map((item) => WeakCondition.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  @override
  String toString() => 'SiteModel($name, #$rank, $status)';
}
