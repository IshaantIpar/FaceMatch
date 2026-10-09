import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/face_match_result.dart';

class FaceMatchApi {
  Future<FaceMatchResult> compareFaces({
    required File selfie,
    required File reference,
  }) async {
    final uri = Uri.parse(AppConfig.matchEndpoint);

    final request = http.MultipartRequest('POST', uri)
      ..files.add(
        await http.MultipartFile.fromPath('selfie', selfie.path),
      )
      ..files.add(
        await http.MultipartFile.fromPath('reference', reference.path),
      );

    try {
      final streamedResponse =
          await request.send().timeout(AppConfig.requestTimeout);

      final response = await http.Response.fromStream(streamedResponse);

      final dynamic decoded;

      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        throw Exception('The server returned an invalid response.');
      }

      if (decoded is! Map<String, dynamic>) {
        throw Exception('The server returned an invalid response.');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return FaceMatchResult.fromJson(decoded);
      }

      final detail = decoded['detail'];

      if (detail is Map<String, dynamic>) {
        throw Exception(
          detail['message']?.toString() ?? 'Unable to compare these images.',
        );
      }

      if (detail is String) {
        throw Exception(detail);
      }

      throw Exception(
        'Face comparison failed (${response.statusCode}).',
      );
    } on SocketException {
      throw Exception(
        'Cannot reach the server. Check the backend and network.',
      );
    } on HttpException {
      throw Exception(
        'A network error occurred while uploading photos.',
      );
    }
  }
}
