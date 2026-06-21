import 'amenity_model.dart';

class LocationScore {
  final double overall;
  final Map<String, CategoryScore> categories;
  final String profile;
  final DateTime calculatedAt;

  const LocationScore({
    required this.overall,
    required this.categories,
    required this.profile,
    required this.calculatedAt,
  });

  factory LocationScore.fromJson(Map<String, dynamic> json) => LocationScore(
        overall: (json['overall'] as num).toDouble(),
        categories: (json['categories'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, CategoryScore.fromJson(v as Map<String, dynamic>)),
        ),
        profile: json['profile'] as String? ?? 'default',
        calculatedAt: DateTime.tryParse(json['calculated_at'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'overall': overall,
        'categories': categories.map((k, v) => MapEntry(k, v.toJson())),
        'profile': profile,
        'calculated_at': calculatedAt.toIso8601String(),
      };
}

class CategoryScore {
  final String id;
  final String label;
  final double score;
  final int count;
  final double weight;
  final AmenityModel? closest;

  const CategoryScore({
    required this.id,
    required this.label,
    required this.score,
    required this.count,
    required this.weight,
    this.closest,
  });

  CategoryScore copyWith({
    String? id,
    String? label,
    double? score,
    int? count,
    double? weight,
    AmenityModel? closest,
  }) =>
      CategoryScore(
        id: id ?? this.id,
        label: label ?? this.label,
        score: score ?? this.score,
        count: count ?? this.count,
        weight: weight ?? this.weight,
        closest: closest ?? this.closest,
      );

  factory CategoryScore.fromJson(Map<String, dynamic> json) => CategoryScore(
        id: json['id'] as String,
        label: json['label'] as String,
        score: (json['score'] as num).toDouble(),
        count: json['count'] as int,
        weight: (json['weight'] as num).toDouble(),
        closest: json['closest'] != null
            ? AmenityModel.fromJson(json['closest'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'score': score,
        'count': count,
        'weight': weight,
        if (closest != null) 'closest': closest!.toJson(),
      };
}

class AnalysisResult {
  final String id;
  final DateTime analyzedAt;
  final LocationScore score;
  final List<AmenityModel> amenities;
  final String? aiSummary;
  final String profile;

  const AnalysisResult({
    required this.id,
    required this.analyzedAt,
    required this.score,
    required this.amenities,
    required this.aiSummary,
    required this.profile,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) => AnalysisResult(
        id: json['id'] as String,
        analyzedAt: DateTime.tryParse(json['analyzed_at'] as String? ?? '') ?? DateTime.now(),
        score: LocationScore.fromJson(json['score'] as Map<String, dynamic>),
        amenities: (json['amenities'] as List)
            .map((e) => AmenityModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        aiSummary: json['ai_summary'] as String?,
        profile: json['profile'] as String? ?? 'default',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'analyzed_at': analyzedAt.toIso8601String(),
        'score': score.toJson(),
        'amenities': amenities.map((a) => a.toJson()).toList(),
        if (aiSummary != null) 'ai_summary': aiSummary,
        'profile': profile,
      };
}
