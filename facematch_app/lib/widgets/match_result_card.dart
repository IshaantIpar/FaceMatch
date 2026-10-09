import 'package:flutter/material.dart';

import '../../../models/face_match_result.dart';

class MatchResultCard extends StatelessWidget {
  final FaceMatchResult result;

  const MatchResultCard({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final matched = result.isMatch;

    final resultColor =
        matched ? const Color(0xFF63D6A5) : const Color(0xFFFF8B8B);

    final score = result.score.clamp(0, 100);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF171D29),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: resultColor.withOpacity(0.4),
        ),
      ),
      child: Column(
        children: [
          Icon(
            matched ? Icons.verified_user : Icons.gpp_bad_outlined,
            size: 40,
            color: resultColor,
          ),
          const SizedBox(height: 10),
          Text(
            matched ? 'Faces matched' : 'No match detected',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: resultColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '$score',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'Similarity score / 100',
            style: TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: score / 100,
            minHeight: 7,
            borderRadius: BorderRadius.circular(8),
            backgroundColor: Colors.white12,
            color: resultColor,
          ),
        ],
      ),
    );
  }
}
