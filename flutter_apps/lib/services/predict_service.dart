import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class PredictService {
  PredictService({required this.baseUrl});

  final String baseUrl;

  /// Send an image to /predict and return the list of detections.
  /// Each detection map contains: label, score, bbox_xyxy, image_width, image_height.
  Future<List<Map<String, dynamic>>> predict(XFile imageFile) async {
    final bytes = await imageFile.readAsBytes();

    String filename = imageFile.name;
    final hasExtension = filename.contains('.');
    final ext = hasExtension ? filename.split('.').last.toLowerCase() : 'jpg';
    final mimeSubtype = (ext == 'png') ? 'png' : 'jpeg';
    if (!hasExtension) {
      filename = '$filename.jpg';
    }

    final req = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/predict'),
    );
    req.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: MediaType('image', mimeSubtype),
      ),
    );

    final streamed = await req.send().timeout(
      const Duration(seconds: 60),
      onTimeout: () => throw Exception(
        'Server tidak merespons dalam 60 detik. '
        'Pastikan backend berjalan dan model sudah dimuat.',
      ),
    );

    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode != 200) {
      throw Exception('Predict gagal (${streamed.statusCode}): $body');
    }

    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Response predict tidak valid: $body');
    }

    final data = decoded;
    final detections = (data['detections'] as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    // Attach image dimensions to each detection for overlay rendering
    final imgW = data['image_width'];
    final imgH = data['image_height'];
    if (imgW != null && imgH != null) {
      for (final det in detections) {
        det['image_width'] = imgW;
        det['image_height'] = imgH;
      }
    }
    return detections;
  }
}
