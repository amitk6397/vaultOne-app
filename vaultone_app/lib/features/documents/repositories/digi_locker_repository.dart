import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants/app_url.dart';
import '../../../data/base_api_service.dart';
import '../../../data/network_api_service.dart';
import '../models/digi_document.dart';

final digiLockerRepositoryProvider = Provider<DigiLockerRepository>((ref) {
  return DigiLockerRepository(ref.watch(apiServiceProvider));
});

class DigiLockerRepository {
  const DigiLockerRepository(this._api);

  final BaseApiService _api;

  Future<List<DigiDocument>> fetchDocuments() async {
    final response = await _api.get(AppUrl.userDocuments);
    final data = response is Map<String, dynamic> ? response['data'] : null;
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(_documentFromApi)
        .where((document) => document.id.isNotEmpty)
        .toList();
  }

  Future<void> syncDocument(DigiDocument document) async {
    final filePath = document.filePath;
    if (filePath != null &&
        filePath.trim().isNotEmpty &&
        !AppUrl.isNetworkResourceUrl(filePath)) {
      final formData = FormData.fromMap({
        'local_id': document.id,
        'metadata': jsonEncode(_documentToApi(document)),
        'file': await MultipartFile.fromFile(
          filePath,
          filename: document.fileName,
        ),
      });
      await _api.post(AppUrl.userDocuments, data: formData);
      return;
    }

    await _api.put(
      '${AppUrl.userDocuments}/${document.id}',
      data: _documentToApi(document),
    );
  }

  Future<void> deleteDocument(String localId) async {
    await _api.delete('${AppUrl.userDocuments}/$localId');
  }

  Map<String, dynamic> _documentToApi(DigiDocument document) {
    return {
      'title': document.title,
      'file_name': document.fileName,
      'extension': document.extension,
      'size_bytes': document.sizeBytes,
      'document_type': document.type.name,
      'folder_id': document.folderId,
      'ocr_text': document.ocrText,
      'issuer': document.issuer,
      'document_number': document.documentNumber,
      'extracted_fields': document.extractedFields,
      'expiry_date': document.expiryDate?.toIso8601String(),
      'is_favorite': document.isFavorite,
      'is_verified': document.isVerified,
      'client_added_at': document.addedAt.toIso8601String(),
      'client_updated_at': document.updatedAt.toIso8601String(),
    };
  }

  DigiDocument _documentFromApi(Map<String, dynamic> json) {
    return DigiDocument.fromMap({
      'id': json['local_id'],
      'title': json['title'],
      'fileName': json['file_name'],
      'extension': json['extension'],
      'sizeBytes': json['size_bytes'],
      'type': json['document_type'],
      'folderId': json['folder_id'],
      'filePath': AppUrl.resolveResourceUrl(json['file_path']?.toString()),
      'ocrText': json['ocr_text'],
      'issuer': json['issuer'],
      'documentNumber': json['document_number'],
      'extractedFields': json['extracted_fields'],
      'expiryDate': json['expiry_date'],
      'isFavorite': json['is_favorite'],
      'isVerified': json['is_verified'],
      'addedAt': json['client_added_at'] ?? json['created_at'],
      'updatedAt': json['client_updated_at'] ?? json['updated_at'],
    });
  }
}
