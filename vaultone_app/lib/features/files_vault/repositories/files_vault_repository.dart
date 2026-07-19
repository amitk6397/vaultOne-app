import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../constants/app_url.dart';
import '../../../data/base_api_service.dart';
import '../../../data/network_api_service.dart';
import '../models/vault_file.dart';

final filesVaultRepositoryProvider = Provider<FilesVaultRepository>((ref) {
  return FilesVaultRepository(
    ref.watch(apiServiceProvider),
    ref.watch(dioProvider),
  );
});

class FilesVaultRepository {
  const FilesVaultRepository(this._api, this._dio);

  final BaseApiService _api;
  final Dio _dio;

  Future<List<VaultFile>> fetchFiles(Directory vaultDirectory) async {
    final response = await _api.get(AppUrl.userFiles);
    final data = response is Map<String, dynamic> ? response['data'] : null;
    if (data is! List) return const [];

    final files = <VaultFile>[];
    for (final item in data.whereType<Map<String, dynamic>>()) {
      final remote = _fromApi(item);
      final localPath = await _downloadIfNeeded(remote, vaultDirectory);
      files.add(remote.copyWith(path: localPath, isSynced: true));
    }
    return files;
  }

  Future<VaultFile> uploadFile(VaultFile file) async {
    final path = file.path;
    if (path == null || path.isEmpty) return file;

    final response = await _api.post(
      AppUrl.userFiles,
      data: FormData.fromMap({
        'local_id': file.id,
        'file_type': file.type.name,
        'tags': file.tags.join(','),
        'is_private': file.isPrivate,
        'is_favorite': file.isFavorite,
        'file': await MultipartFile.fromFile(path, filename: file.name),
      }),
    );
    final data = response is Map<String, dynamic>
        ? response['data'] as Map<String, dynamic>? ?? response
        : <String, dynamic>{};
    final remote = _fromApi(data);
    return file.copyWith(
      remoteId: remote.remoteId,
      remoteUrl: remote.remoteUrl,
      isSynced: true,
    );
  }

  Future<void> updateMetadata(VaultFile file) async {
    final remoteId = file.remoteId;
    if (remoteId == null) return;
    await _api.patch(
      '${AppUrl.userFiles}/$remoteId',
      data: {
        'tags': file.tags,
        'is_favorite': file.isFavorite,
        'is_archived': file.isArchived,
        'is_private': file.isPrivate,
      },
    );
  }

  Future<void> deleteRemote(VaultFile file) async {
    final remoteId = file.remoteId;
    if (remoteId == null) return;
    await _api.delete('${AppUrl.userFiles}/$remoteId');
  }

  Future<String> _downloadIfNeeded(
    VaultFile file,
    Directory vaultDirectory,
  ) async {
    final existingPath = p.join(vaultDirectory.path, file.id);
    final existingFile = File(existingPath);
    if (await existingFile.exists()) return existingPath;

    final remoteUrl = file.remoteUrl;
    if (remoteUrl == null || remoteUrl.isEmpty) return existingPath;
    await _dio.download(remoteUrl, existingPath);
    return existingPath;
  }

  VaultFile _fromApi(Map<String, dynamic> json) {
    final id = json['id'] as int? ?? 0;
    final name = json['original_name']?.toString() ?? 'vault-file';
    final extension = json['extension']?.toString() ?? p.extension(name);
    final typeName = json['file_type']?.toString() ?? 'other';
    final remotePath = json['file_path']?.toString() ?? '';
    final createdAt = DateTime.tryParse(json['created_at']?.toString() ?? '');
    final updatedAt = DateTime.tryParse(json['updated_at']?.toString() ?? '');

    return VaultFile(
      id: 'remote-$id-$name',
      name: name,
      extension: extension,
      sizeBytes: json['size_bytes'] is int ? json['size_bytes'] as int : 0,
      type: VaultFileType.values.firstWhere(
        (item) => item.name == typeName,
        orElse: () => VaultFileType.other,
      ),
      addedAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt ?? DateTime.now(),
      tags:
          (json['tags'] as List?)?.map((item) => item.toString()).toList() ??
          const [],
      remoteId: id,
      remoteUrl: AppUrl.resolveResourceUrl(remotePath),
      isSynced: true,
      isFavorite: json['is_favorite'] == true,
      isArchived: json['is_archived'] == true,
      isEncrypted: json['is_encrypted'] != false,
      isPrivate: json['is_private'] == true,
    );
  }
}
