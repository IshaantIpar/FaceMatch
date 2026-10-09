
class FaceMatchResult {
  final bool success;
  final double similarity;
  final int score;
  final String result;

  const FaceMatchResult({
    required this.success,
    required this.similarity,
    required this.score,
    required this.result,
  });

  bool get isMatch => result == 'MATCH';

  factory FaceMatchResult.fromJson(Map<String, dynamic> json) {
    return FaceMatchResult(
      success: json['success'] as bool? ?? false,
      similarity: (json['similarity'] as num?)?.toDouble() ?? 0.0,
      score: (json['score'] as num?)?.toInt() ?? 0,
      result: json['result'] as String? ?? 'UNKNOWN',
    );
  }
}
