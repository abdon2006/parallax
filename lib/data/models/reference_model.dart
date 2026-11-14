class ReferenceModel {
  final Map<String, double> conditions;

  const ReferenceModel({required this.conditions});

  double? valueFor(String condition) => conditions[condition];

  factory ReferenceModel.fromJson(Map<String, dynamic> json) {
    return ReferenceModel(
      conditions: Map<String, double>.from(
        json.map((key, value) => MapEntry(key, value.toDouble())),
      ),
    );
  }
}
