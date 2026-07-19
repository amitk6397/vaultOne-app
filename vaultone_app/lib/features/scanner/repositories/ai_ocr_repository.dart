import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/app_url.dart';
import '../../../data/base_api_service.dart';
import '../../../data/network_api_service.dart';

final aiOcrRepositoryProvider = Provider<AiOcrRepository>(
  (ref) => AiOcrRepository(ref.watch(apiServiceProvider)),
);

class AiOcrResult {
  const AiOcrResult({
    required this.rawText,
    required this.title,
    required this.documentType,
    required this.fields,
  });
  final String rawText;
  final String title;
  final String documentType;
  final Map<String, String> fields;
}

class AiOcrRepository {
  const AiOcrRepository(this._api);
  final BaseApiService _api;
  Future<AiOcrResult> extract(String path, {String target = 'document'}) async {
    final bytes = await File(path).readAsBytes();
    if (bytes.length > 8 * 1024 * 1024) {
      throw Exception('Use an image below 8 MB');
    }
    final ext = path.split('.').last.toLowerCase();
    final mime = ext == 'pdf'
        ? 'application/pdf'
        : ext == 'png'
        ? 'image/png'
        : ext == 'webp'
        ? 'image/webp'
        : 'image/jpeg';
    final response = await _api.post(
      AppUrl.userAiOcr,
      data: {
        'image_base64': base64Encode(bytes),
        'mime_type': mime,
        'target': target,
      },
    );
    final data = response is Map<String, dynamic>
        ? response['data'] as Map<String, dynamic>?
        : null;
    if (data == null) throw Exception('AI OCR returned no data');
    final fields = <String, String>{};
    if (data['fields'] is Map) {
      (data['fields'] as Map).forEach(
        (k, v) => fields[k.toString()] = v.toString(),
      );
    }
    return AiOcrResult(
      rawText: data['raw_text']?.toString() ?? '',
      title: data['title']?.toString() ?? 'Scanned image',
      documentType: data['document_type']?.toString() ?? 'Other',
      fields: fields,
    );
  }
}
