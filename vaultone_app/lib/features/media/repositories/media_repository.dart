import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants/app_url.dart';
import '../../../data/base_api_service.dart';
import '../../../data/network_api_service.dart';
import '../models/media_item.dart';

final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  return MediaRepository(ref.watch(apiServiceProvider));
});

class MediaRepository {
  const MediaRepository(this._api);

  final BaseApiService _api;

  Future<List<Map<String, dynamic>>> fetchMedia() async {
    final response = await _api.get(AppUrl.userMedia);
    final data = response is Map ? response['data'] : null;
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> syncMedia(MediaItem item) async {
    final filePath = item.path;
    final file = filePath == null ? null : File(filePath);
    final hasFile = file != null && await file.exists();
    await _api.post(
      AppUrl.userMedia,
      data: FormData.fromMap({
        'local_id': item.id,
        'title': item.title,
        'kind': item.kind.name,
        'visibility': item.visibility.name,
        'album_id': item.albumId,
        'album_name': item.albumName,
        'folder_name': item.folderName,
        'size_mb': item.sizeMb,
        'duration_seconds': item.duration?.inSeconds,
        'last_position_seconds': item.lastPosition?.inSeconds,
        'is_favorite': item.isFavorite,
        'is_hidden': item.isHidden,
        'is_deleted': item.isDeleted,
        'client_created_at': item.createdAt.toIso8601String(),
        if (hasFile)
          'file': await MultipartFile.fromFile(
            filePath ?? '',
            filename: item.title,
          ),
      }),
    );
  }

  Future<void> updateMedia(MediaItem item) async {
    await _api.patch(
      '${AppUrl.userMedia}/${item.id}',
      data: {
        'title': item.title,
        'visibility': item.visibility.name,
        'albumId': item.albumId,
        'albumName': item.albumName,
        'folderName': item.folderName,
        'sizeMb': item.sizeMb,
        'durationSeconds': item.duration?.inSeconds,
        'lastPositionSeconds': item.lastPosition?.inSeconds,
        'isFavorite': item.isFavorite,
        'isHidden': item.isHidden,
        'isDeleted': item.isDeleted,
      },
    );
  }

  Future<void> deleteMedia(String localId) async {
    await _api.delete('${AppUrl.userMedia}/$localId');
  }
}
