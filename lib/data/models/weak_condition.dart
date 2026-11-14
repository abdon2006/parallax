class WeakCondition {
  final String feature;
  final double siteValue;
  final double referenceValue;

  const WeakCondition({
    required this.feature,
    required this.siteValue,
    required this.referenceValue,
  });

  factory WeakCondition.fromJson(Map<String, dynamic> json) {
    return WeakCondition(
      feature: json['feature'] as String? ?? '',
      siteValue: (json['site_value'] as num?)?.toDouble() ?? 0,
      referenceValue: (json['reference_value'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  String toString() => '$feature ($siteValue vs $referenceValue)';
}
