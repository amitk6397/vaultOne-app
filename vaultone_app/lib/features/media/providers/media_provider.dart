import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/legacy.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../constants/app_colors.dart';
import '../../../core/storage/module_storage_controller.dart';
import '../models/media_item.dart';
import '../repositories/media_repository.dart';

class MediaLibraryState {
  const MediaLibraryState({
    required this.items,
    required this.albums,
    required this.security,
    this.query = '',
    this.sort = MediaSort.dateNewest,
    this.viewMode = MediaViewMode.grid,
    this.selectedIds = const {},
    this.scannedKinds = const {},
    this.isLoading = false,
    this.permissionDenied = false,
    this.totalVideoCount = 0,
    this.videoFolders = const [],
    this.videoStorage,
    this.isUploadingVideo = false,
  });

  final List<MediaItem> items;
  final List<MediaAlbum> albums;
  final MediaSecuritySettings security;
  final String query;
  final MediaSort sort;
  final MediaViewMode viewMode;
  final Set<String> selectedIds;
  final Set<MediaKind> scannedKinds;
  final bool isLoading;
  final bool permissionDenied;
  final int totalVideoCount;
  final List<DeviceVideoFolder> videoFolders;
  final VideoStorage? videoStorage;
  final bool isUploadingVideo;

  MediaLibraryState copyWith({
    List<MediaItem>? items,
    List<MediaAlbum>? albums,
    MediaSecuritySettings? security,
    String? query,
    MediaSort? sort,
    MediaViewMode? viewMode,
    Set<String>? selectedIds,
    Set<MediaKind>? scannedKinds,
    bool? isLoading,
    bool? permissionDenied,
    int? totalVideoCount,
    List<DeviceVideoFolder>? videoFolders,
    VideoStorage? videoStorage,
    bool? isUploadingVideo,
  }) {
    return MediaLibraryState(
      items: items ?? this.items,
      albums: albums ?? this.albums,
      security: security ?? this.security,
      query: query ?? this.query,
      sort: sort ?? this.sort,
      viewMode: viewMode ?? this.viewMode,
      selectedIds: selectedIds ?? this.selectedIds,
      scannedKinds: scannedKinds ?? this.scannedKinds,
      isLoading: isLoading ?? this.isLoading,
      permissionDenied: permissionDenied ?? this.permissionDenied,
      totalVideoCount: totalVideoCount ?? this.totalVideoCount,
      videoFolders: videoFolders ?? this.videoFolders,
      videoStorage: videoStorage ?? this.videoStorage,
      isUploadingVideo: isUploadingVideo ?? this.isUploadingVideo,
    );
  }
}

class MediaLibraryController extends StateNotifier<MediaLibraryState> {
  static const privatePhotoLimit = 10;
  static const privateVideoLimitMb = 500.0;
  static const _videoSnapshotInitializedKey =
      'video_folder_snapshot_initialized';
  static const _videoSnapshotFolderIdsKey = 'video_folder_snapshot_folder_ids';
  static const _videoSnapshotFolderCountKey = 'video_folder_snapshot_count';

  MediaLibraryController(this._repository)
    : super(
        MediaLibraryState(
          items: const [],
          albums: const [],
          security: const MediaSecuritySettings(),
        ),
      ) {
    unawaited(_loadSecuritySettings());
  }

  final MediaRepository _repository;
  final Map<String, AssetPathEntity> _videoPaths = {};
  static const _videoStorageKey = 'private_video_storage';
  static const _privateVideosKey = 'private_video_items';
  static const _photoBiometricsKey = 'photo_biometrics_enabled';
  static const _videoBiometricsKey = 'video_biometrics_enabled';

  Future<void> _loadSecuritySettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      security: state.security.copyWith(
        photoBiometricsEnabled: prefs.getBool(_photoBiometricsKey) ?? true,
        videoBiometricsEnabled: prefs.getBool(_videoBiometricsKey) ?? true,
      ),
    );
  }

  Future<void> loadVideoStorage() async {
    final value = (await SharedPreferences.getInstance()).getString(
      _videoStorageKey,
    );
    if (value == null) return;
    state = state.copyWith(
      videoStorage: value == VideoStorage.database.name
          ? VideoStorage.database
          : VideoStorage.local,
    );
  }

  Future<void> setVideoStorage(VideoStorage storage) async {
    await (await SharedPreferences.getInstance()).setString(
      _videoStorageKey,
      storage.name,
    );
    state = state.copyWith(videoStorage: storage);
  }

  Future<void> loadPrivateVideos() async {
    final raw = (await SharedPreferences.getInstance()).getString(
      _privateVideosKey,
    );
    if (raw == null) return;
    final restored = <MediaItem>[];
    for (final value
        in (jsonDecode(raw) as List).cast<Map<String, dynamic>>()) {
      final path = value['path'] as String;
      if (!await File(path).exists()) continue;
      restored.add(
        MediaItem(
          id: value['id'] as String,
          title: value['title'] as String,
          kind: MediaKind.video,
          visibility: MediaVisibility.private,
          albumId: 'private-videos',
          albumName: 'Private Videos',
          folderName: 'Private Vault',
          createdAt: DateTime.parse(value['createdAt'] as String),
          sizeMb: (value['sizeMb'] as num).toDouble(),
          accent: AppColors.purple,
          path: path,
          isFavorite: value['isFavorite'] == true,
          isDeleted: value['isDeleted'] == true,
        ),
      );
    }
    state = state.copyWith(
      items: [
        ...restored,
        ...state.items.where((item) => item.kind != MediaKind.video),
      ],
    );
  }

  Future<void> loadVideoCount() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.hasAccess) {
      state = state.copyWith(permissionDenied: true);
      return;
    }
    final all = await PhotoManager.getAssetPathList(
      type: RequestType.video,
      onlyAll: true,
    );
    final count = all.isEmpty ? 0 : await all.first.assetCountAsync;
    state = state.copyWith(totalVideoCount: count, permissionDenied: false);
  }

  Future<void> loadVideoFolders({bool force = false}) async {
    if (!force && state.videoFolders.isNotEmpty) return;
    state = state.copyWith(isLoading: true, permissionDenied: false);
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.hasAccess) {
      state = state.copyWith(isLoading: false, permissionDenied: true);
      return;
    }
    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.video,
      onlyAll: false,
    );
    final prefs = await SharedPreferences.getInstance();
    final snapshotInitialized =
        prefs.getBool(_videoSnapshotInitializedKey) ?? false;
    _videoPaths.clear();
    final folders = <DeviceVideoFolder>[];
    var total = state.totalVideoCount;
    for (final path in paths) {
      final count = await path.assetCountAsync;
      if (path.isAll) {
        total = count;
        continue;
      }
      if (count == 0) continue;
      if (path.name.trim().toLowerCase() == 'recent' && count == total) {
        continue;
      }
      final savedCount = prefs.getInt(_videoFolderCountKey(path.id));
      final newVideoCount = snapshotInitialized && savedCount != null
          ? (count - savedCount).clamp(0, count).toInt()
          : 0;
      final isNewFolder = snapshotInitialized && savedCount == null;
      _videoPaths[path.id] = path;
      folders.add(
        DeviceVideoFolder(
          id: path.id,
          name: path.name,
          videoCount: count,
          newVideoCount: isNewFolder ? count : newVideoCount,
          isNew: isNewFolder,
        ),
      );
    }
    folders.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    if (!snapshotInitialized) {
      await _saveVideoFolderSnapshot(folders);
    }
    state = state.copyWith(
      videoFolders: folders,
      totalVideoCount: total,
      isLoading: false,
    );
  }

  Future<void> loadVideoFolder(String folderId) async {
    var path = _videoPaths[folderId];
    if (path == null) {
      await loadVideoFolders(force: true);
      path = _videoPaths[folderId];
    }
    if (path == null) return;
    state = state.copyWith(isLoading: true);
    final count = await path.assetCountAsync;
    final assets = await path.getAssetListPaged(page: 0, size: count);
    final items = <MediaItem>[
      for (var index = 0; index < assets.length; index++)
        MediaItem(
          id: 'video-${assets[index].id}',
          assetId: assets[index].id,
          title: assets[index].title ?? 'video-${assets[index].id}',
          kind: MediaKind.video,
          visibility: MediaVisibility.public,
          albumId: path.id,
          albumName: path.name,
          folderName: path.name,
          createdAt: assets[index].createDateTime,
          sizeMb: 0,
          accent: mediaAccentForIndex(index),
          assetEntity: assets[index],
          duration: assets[index].videoDuration,
        ),
    ];
    state = state.copyWith(
      items: [
        ...state.items.where(
          (item) =>
              item.kind != MediaKind.video ||
              item.visibility == MediaVisibility.private,
        ),
        ...items,
      ],
      isLoading: false,
    );
  }

  Future<void> markVideoFolderSeen(String folderId) async {
    final folder = state.videoFolders.where((item) => item.id == folderId);
    if (folder.isEmpty) return;
    final current = folder.first;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_videoSnapshotInitializedKey, true);
    await prefs.setInt(_videoFolderCountKey(folderId), current.videoCount);
    await prefs.setStringList(
      _videoSnapshotFolderIdsKey,
      {...?prefs.getStringList(_videoSnapshotFolderIdsKey), folderId}.toList(),
    );
    state = state.copyWith(
      videoFolders: [
        for (final item in state.videoFolders)
          if (item.id == folderId)
            DeviceVideoFolder(
              id: item.id,
              name: item.name,
              videoCount: item.videoCount,
            )
          else
            item,
      ],
    );
  }

  List<MediaItem> visibleItems({
    MediaKind? kind,
    MediaVisibility? visibility,
    String? albumId,
    String? folderName,
    bool includeDeleted = false,
  }) {
    final query = state.query.trim().toLowerCase();
    final filtered = state.items.where((item) {
      if (!includeDeleted && item.isDeleted) return false;
      if (includeDeleted && !item.isDeleted) return false;
      if (kind != null && item.kind != kind) return false;
      if (visibility != null && item.visibility != visibility) return false;
      if (albumId != null && item.albumId != albumId) return false;
      if (folderName != null && item.folderName != folderName) return false;
      if (query.isEmpty) return true;
      return item.title.toLowerCase().contains(query) ||
          item.albumName.toLowerCase().contains(query) ||
          item.folderName.toLowerCase().contains(query);
    }).toList();

    filtered.sort((a, b) {
      return switch (state.sort) {
        MediaSort.dateNewest => b.createdAt.compareTo(a.createdAt),
        MediaSort.dateOldest => a.createdAt.compareTo(b.createdAt),
        MediaSort.name => a.title.compareTo(b.title),
        MediaSort.sizeLargest => b.sizeMb.compareTo(a.sizeMb),
      };
    });
    return filtered;
  }

  MediaItem? itemById(String id) {
    for (final item in state.items) {
      if (item.id == id) return item;
    }
    return null;
  }

  MediaAlbum? albumById(String id) {
    for (final album in state.albums) {
      if (album.id == id) return album;
    }
    return null;
  }

  List<String> videoFolders() {
    final folders =
        state.items
            .where((item) => item.kind == MediaKind.video && !item.isDeleted)
            .map((item) => item.folderName)
            .toSet()
            .toList()
          ..sort();
    return folders;
  }

  List<MediaFolderSummary> mediaFolders({MediaKind? kind}) {
    final grouped = <String, List<MediaItem>>{};
    for (final item in visibleItems(kind: kind)) {
      grouped.putIfAbsent(item.folderName, () => <MediaItem>[]).add(item);
    }
    final folders =
        grouped.entries
            .map(
              (entry) =>
                  MediaFolderSummary(name: entry.key, items: entry.value),
            )
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    return folders;
  }

  List<String> photoFolders() {
    final folders =
        state.items
            .where((item) => item.kind == MediaKind.photo && !item.isDeleted)
            .map((item) => item.folderName)
            .toSet()
            .toList()
          ..sort();
    return folders;
  }

  int get privatePhotoCount => state.items
      .where(
        (item) =>
            item.kind == MediaKind.photo &&
            item.visibility == MediaVisibility.private &&
            !item.isDeleted,
      )
      .length;

  double get privateVideoUsedMb => state.items
      .where(
        (item) =>
            item.kind == MediaKind.video &&
            item.visibility == MediaVisibility.private &&
            !item.isDeleted,
      )
      .fold<double>(0, (total, item) => total + item.sizeMb);

  String? privateMoveBlockReason(MediaItem item) {
    if (item.visibility == MediaVisibility.private) return null;
    if (item.kind == MediaKind.photo &&
        privatePhotoCount >= privatePhotoLimit) {
      return 'Private photos limit is $privatePhotoLimit. Remove one first.';
    }
    if (item.kind == MediaKind.video &&
        privateVideoUsedMb + item.sizeMb > privateVideoLimitMb) {
      final left = (privateVideoLimitMb - privateVideoUsedMb).clamp(
        0,
        privateVideoLimitMb,
      );
      return 'Private videos limit is ${privateVideoLimitMb.toStringAsFixed(0)} MB. ${left.toStringAsFixed(0)} MB left.';
    }
    return null;
  }

  void setQuery(String value) => state = state.copyWith(query: value);

  void setSort(MediaSort value) => state = state.copyWith(sort: value);

  Future<void> scanDeviceMedia(MediaKind kind, {bool force = false}) async {
    if (!force && state.scannedKinds.contains(kind)) return;
    state = state.copyWith(isLoading: true, permissionDenied: false);

    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.hasAccess) {
      state = state.copyWith(isLoading: false, permissionDenied: true);
      return;
    }

    final requestType = kind == MediaKind.photo
        ? RequestType.image
        : RequestType.video;
    final paths = await PhotoManager.getAssetPathList(
      type: requestType,
      onlyAll: false,
      filterOption: FilterOptionGroup(
        orders: [
          const OrderOption(type: OrderOptionType.createDate, asc: false),
        ],
      ),
    );

    final existingByAssetId = {
      for (final item in state.items)
        if (item.assetId != null) item.assetId!: item,
    };
    final scanned = <MediaItem>[];
    final scannedAlbums = <MediaAlbum>[];
    var colorIndex = 0;

    for (final path in paths) {
      final count = await path.assetCountAsync;
      if (count == 0) continue;
      final assets = await path.getAssetListPaged(page: 0, size: count);
      final folderId = path.id;
      final folderName = path.name.isEmpty ? 'Recent' : path.name;

      scannedAlbums.add(
        MediaAlbum(
          id: folderId,
          name: folderName,
          kind: kind,
          isPrivate: false,
          accent: mediaAccentForIndex(colorIndex++),
        ),
      );

      for (final asset in assets) {
        final previous = existingByAssetId[asset.id];
        scanned.add(
          MediaItem(
            id: previous?.id ?? '${kind.name}-${asset.id}',
            assetId: asset.id,
            title: asset.title ?? '${kind.name}-${asset.id}',
            kind: kind,
            visibility: previous?.visibility ?? MediaVisibility.public,
            albumId: folderId,
            albumName: folderName,
            folderName: folderName,
            createdAt: asset.createDateTime,
            sizeMb: previous?.sizeMb ?? 0,
            accent: previous?.accent ?? mediaAccentForIndex(scanned.length),
            assetEntity: asset,
            path: previous?.path,
            duration: kind == MediaKind.video ? asset.videoDuration : null,
            isFavorite: previous?.isFavorite ?? false,
            isHidden: previous?.isHidden ?? false,
            isDeleted: previous?.isDeleted ?? false,
            lastPosition: previous?.lastPosition,
          ),
        );
      }
    }

    final nonScanned = state.items
        .where((item) => item.kind != kind || item.assetId == null)
        .toList();
    final otherAlbums = state.albums
        .where((album) => album.kind != kind || album.isPrivate)
        .toList();
    state = state.copyWith(
      items: [...scanned, ...nonScanned],
      albums: [...scannedAlbums, ...otherAlbums],
      scannedKinds: {...state.scannedKinds, kind},
      isLoading: false,
    );
  }

  Future<void> scanAllDeviceMedia({bool force = false}) async {
    await scanDeviceMedia(MediaKind.photo, force: force);
    await scanDeviceMedia(MediaKind.video, force: force);
  }

  Future<String?> resolveFilePath(String id) async {
    final item = itemById(id);
    if (item == null) return null;
    final existingPath = item.path;
    if (existingPath != null && existingPath.isNotEmpty) return existingPath;
    final entity = item.assetEntity;
    if (entity == null) return null;
    final file = await entity.file;
    final path = file?.path;
    if (path == null || path.isEmpty) return null;
    final sizeMb = await _sizeMb(file);
    final updated = _updateItem(id, (item) {
      return item.copyWith(path: path, sizeMb: sizeMb);
    });
    if (updated != null) unawaited(_syncRemote(updated));
    return path;
  }

  void toggleView() {
    state = state.copyWith(
      viewMode: state.viewMode == MediaViewMode.grid
          ? MediaViewMode.list
          : MediaViewMode.grid,
    );
  }

  void toggleSelection(String id) {
    final selected = {...state.selectedIds};
    selected.contains(id) ? selected.remove(id) : selected.add(id);
    state = state.copyWith(selectedIds: selected);
  }

  void clearSelection() => state = state.copyWith(selectedIds: {});

  void toggleFavorite(String id) {
    final updated = _updateItem(
      id,
      (item) => item.copyWith(isFavorite: !item.isFavorite),
    );
    if (updated != null) unawaited(_updateRemote(updated));
  }

  void toggleHidden(String id) {
    final updated = _updateItem(
      id,
      (item) => item.copyWith(isHidden: !item.isHidden),
    );
    if (updated != null) unawaited(_updateRemote(updated));
  }

  String? moveVisibility(String id, MediaVisibility visibility) {
    final item = itemById(id);
    if (item == null) return 'Media not found';
    if (visibility == MediaVisibility.private) {
      final reason = privateMoveBlockReason(item);
      if (reason != null) return reason;
    }
    final updated = _updateItem(
      id,
      (item) => item.copyWith(visibility: visibility),
    );
    if (updated != null) unawaited(_updateRemote(updated));
    return null;
  }

  void moveSelectedTo(MediaVisibility visibility) {
    final selected = state.selectedIds;
    final updatedItems = <MediaItem>[];
    state = state.copyWith(
      items: state.items.map((item) {
        if (!selected.contains(item.id)) return item;
        final updated = item.copyWith(visibility: visibility);
        updatedItems.add(updated);
        return updated;
      }).toList(),
      selectedIds: {},
    );
    for (final item in updatedItems) {
      unawaited(_updateRemote(item));
    }
  }

  void moveToAlbum(String id, MediaAlbum album) {
    final updated = _updateItem(
      id,
      (item) => item.copyWith(albumId: album.id, albumName: album.name),
    );
    if (updated != null) unawaited(_updateRemote(updated));
  }

  void moveSelectedToAlbum(MediaAlbum album, MediaKind kind) {
    final selected = state.selectedIds;
    final updatedItems = <MediaItem>[];
    state = state.copyWith(
      items: state.items.map((item) {
        if (!selected.contains(item.id) || item.kind != kind) return item;
        final updated = item.copyWith(
          albumId: album.id,
          albumName: album.name,
          folderName: album.name,
        );
        updatedItems.add(updated);
        return updated;
      }).toList(),
      selectedIds: {},
    );
    for (final item in updatedItems) {
      unawaited(_updateRemote(item));
    }
    unawaited(_persistPrivateVideos());
  }

  void copySelectedToAlbum(MediaAlbum album, MediaKind kind) {
    final selected = state.selectedIds;
    final now = DateTime.now();
    final copies = state.items
        .where((item) => selected.contains(item.id) && item.kind == kind)
        .map(
          (item) => MediaItem(
            id: '${item.id}-copy-${now.microsecondsSinceEpoch}-${item.id.hashCode}',
            title: item.title,
            kind: item.kind,
            visibility: item.visibility,
            albumId: album.id,
            albumName: album.name,
            folderName: album.name,
            createdAt: now,
            sizeMb: item.sizeMb,
            accent: item.accent,
            assetId: item.assetId,
            assetEntity: item.assetEntity,
            path: item.path,
            duration: item.duration,
            isFavorite: item.isFavorite,
          ),
        )
        .toList();
    state = state.copyWith(items: [...copies, ...state.items], selectedIds: {});
    unawaited(_persistPrivateVideos());
  }

  void deleteItem(String id) {
    final updated = _updateItem(id, (item) => item.copyWith(isDeleted: true));
    if (updated != null) unawaited(_updateRemote(updated));
    unawaited(_persistPrivateVideos());
  }

  void removeItem(String id) {
    state = state.copyWith(
      items: state.items.where((item) => item.id != id).toList(),
      selectedIds: {...state.selectedIds}..remove(id),
    );
    unawaited(_deleteRemote(id));
    unawaited(_persistPrivateVideos());
  }

  Future<bool> permanentlyDeleteItem(String id) async {
    final item = itemById(id);
    if (item == null) return false;
    if (item.assetId != null) {
      final deletedIds = await PhotoManager.editor.deleteWithIds([
        item.assetId!,
      ]);
      if (!deletedIds.contains(item.assetId)) return false;
    }
    state = state.copyWith(
      items: state.items.where((item) => item.id != id).toList(),
      selectedIds: {...state.selectedIds}..remove(id),
    );
    unawaited(_deleteRemote(id));
    unawaited(_persistPrivateVideos());
    return true;
  }

  void restoreItem(String id) {
    final updated = _updateItem(id, (item) => item.copyWith(isDeleted: false));
    if (updated != null) unawaited(_updateRemote(updated));
  }

  void createAlbum(String name, MediaKind kind, {bool isPrivate = false}) {
    final album = MediaAlbum(
      id: '${name.toLowerCase().replaceAll(' ', '-')}-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      kind: kind,
      isPrivate: isPrivate,
      accent: mediaAccentForIndex(state.albums.length),
    );
    state = state.copyWith(albums: [...state.albums, album]);
  }

  void renameAlbum(String id, String name) {
    final album = albumById(id);
    if (album == null) return;
    state = state.copyWith(
      albums: state.albums
          .map((item) => item.id == id ? item.copyWith(name: name) : item)
          .toList(),
      items: state.items
          .map(
            (item) =>
                item.albumId == id ? item.copyWith(albumName: name) : item,
          )
          .toList(),
    );
    for (final item in state.items.where((item) => item.albumId == id)) {
      unawaited(_updateRemote(item));
    }
  }

  void deleteAlbum(String id) {
    final updatedItems = <MediaItem>[];
    state = state.copyWith(
      albums: state.albums.where((album) => album.id != id).toList(),
      items: state.items.map((item) {
        if (item.albumId != id) return item;
        final updated = item.copyWith(
          albumId: 'uncategorized',
          albumName: 'Uncategorized',
        );
        updatedItems.add(updated);
        return updated;
      }).toList(),
    );
    for (final item in updatedItems) {
      unawaited(_updateRemote(item));
    }
  }

  Future<int> importPhotos({
    MediaVisibility visibility = MediaVisibility.private,
    ModuleStorageTarget storage = ModuleStorageTarget.local,
  }) async {
    if (visibility == MediaVisibility.private &&
        privatePhotoCount >= privatePhotoLimit) {
      return 0;
    }

    final picker = ImagePicker();
    final images = await picker.pickMultiImage(imageQuality: 88);
    if (images.isEmpty) return 0;

    final allowedImages = visibility == MediaVisibility.private
        ? images.take(privatePhotoLimit - privatePhotoCount)
        : images;
    final additions = <MediaItem>[];
    var index = 0;
    for (final image in allowedImages) {
      final sizeMb = await _sizeMb(File(image.path));
      additions.add(
        MediaItem(
          id: 'photo-${DateTime.now().microsecondsSinceEpoch}-$index',
          title: image.name,
          kind: MediaKind.photo,
          visibility: visibility,
          albumId: visibility == MediaVisibility.private
              ? 'private-photos'
              : 'imports',
          albumName: visibility == MediaVisibility.private
              ? 'Private Photos'
              : 'Imports',
          folderName: visibility == MediaVisibility.private
              ? 'Private Vault'
              : 'Imports',
          createdAt: DateTime.now(),
          sizeMb: sizeMb,
          accent: mediaAccentForIndex(index),
          path: image.path,
        ),
      );
      index++;
    }

    if (additions.isEmpty) return 0;
    state = state.copyWith(items: [...additions, ...state.items]);
    if (storage == ModuleStorageTarget.database) {
      for (final item in additions) {
        unawaited(_syncRemote(item));
      }
    }
    return additions.length;
  }

  Future<void> importReceivedMedia({
    required String sourcePath,
    required String fileName,
    required MediaKind kind,
  }) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw StateError('Received secure file is unavailable');
    }
    final folder = kind == MediaKind.photo
        ? 'private_photos'
        : 'private_videos';
    final directory = Directory(
      p.join((await getApplicationSupportDirectory()).path, folder),
    );
    await directory.create(recursive: true);
    final stored = await source.copy(
      p.join(
        directory.path,
        '${DateTime.now().microsecondsSinceEpoch}${p.extension(fileName)}',
      ),
    );
    final item = MediaItem(
      id: '${kind.name}-received-${DateTime.now().microsecondsSinceEpoch}',
      title: fileName,
      kind: kind,
      visibility: MediaVisibility.private,
      albumId: kind == MediaKind.photo ? 'private-photos' : 'private-videos',
      albumName: kind == MediaKind.photo ? 'Private Photos' : 'Private Videos',
      folderName: 'Private Vault',
      createdAt: DateTime.now(),
      sizeMb: await _sizeMb(stored),
      accent: kind == MediaKind.photo ? AppColors.blue : AppColors.purple,
      path: stored.path,
    );
    state = state.copyWith(items: [item, ...state.items]);
    if (kind == MediaKind.video) {
      await _persistPrivateVideos();
    }
    final storage = await savedStorageTarget(
      kind == MediaKind.photo ? StorageModule.photos : StorageModule.videos,
    );
    if (storage == ModuleStorageTarget.database) {
      unawaited(_syncRemote(item));
    }
  }

  Future<String?> importVideos(VideoStorage storage) async {
    final result = await FilePicker.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );
    final selectedPath = result?.files.single.path;
    if (selectedPath == null) return '';
    final source = File(selectedPath);
    final sizeMb = await _sizeMb(source);
    if (sizeMb >= 100) return 'video_upload_size_limit';
    state = state.copyWith(isUploadingVideo: true);
    final directory = Directory(
      p.join((await getApplicationSupportDirectory()).path, 'private_videos'),
    );
    await directory.create(recursive: true);
    final storedPath = p.join(
      directory.path,
      '${DateTime.now().microsecondsSinceEpoch}${p.extension(selectedPath)}',
    );
    final stored = await source.copy(storedPath);
    final item = MediaItem(
      id: 'video-${DateTime.now().microsecondsSinceEpoch}',
      title: result!.files.single.name,
      kind: MediaKind.video,
      visibility: MediaVisibility.private,
      albumId: 'private-videos',
      albumName: 'Private Videos',
      folderName: 'Private Vault',
      createdAt: DateTime.now(),
      sizeMb: sizeMb,
      accent: AppColors.purple,
      path: stored.path,
    );
    state = state.copyWith(items: [item, ...state.items]);
    if (storage == VideoStorage.database) await _syncRemote(item);
    await _persistPrivateVideos();
    state = state.copyWith(isUploadingVideo: false);
    return null;
  }

  Future<void> _persistPrivateVideos() async {
    final values = state.items
        .where(
          (item) =>
              item.kind == MediaKind.video &&
              item.isPrivate &&
              item.path != null,
        )
        .map(
          (item) => {
            'id': item.id,
            'title': item.title,
            'path': item.path,
            'createdAt': item.createdAt.toIso8601String(),
            'sizeMb': item.sizeMb,
            'isFavorite': item.isFavorite,
            'isDeleted': item.isDeleted,
          },
        )
        .toList();
    await (await SharedPreferences.getInstance()).setString(
      _privateVideosKey,
      jsonEncode(values),
    );
  }

  void savePlaybackPosition(String id, Duration position) {
    final updated = _updateItem(
      id,
      (item) => item.copyWith(lastPosition: position),
    );
    if (updated != null) unawaited(_updateRemote(updated));
  }

  Future<void> _saveVideoFolderSnapshot(List<DeviceVideoFolder> folders) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_videoSnapshotInitializedKey, true);
    await prefs.setStringList(
      _videoSnapshotFolderIdsKey,
      folders.map((folder) => folder.id).toList(),
    );
    await prefs.setInt(
      _videoSnapshotFolderCountKey,
      folders.fold<int>(0, (total, folder) => total + folder.videoCount),
    );
    for (final folder in folders) {
      await prefs.setInt(_videoFolderCountKey(folder.id), folder.videoCount);
    }
  }

  String _videoFolderCountKey(String folderId) =>
      'video_folder_snapshot_count_$folderId';

  Future<void> updateSecurity(MediaSecuritySettings settings) async {
    state = state.copyWith(security: settings);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_photoBiometricsKey, settings.photoBiometricsEnabled);
    await prefs.setBool(_videoBiometricsKey, settings.videoBiometricsEnabled);
  }

  MediaItem? _updateItem(String id, MediaItem Function(MediaItem item) update) {
    MediaItem? updatedItem;
    state = state.copyWith(
      items: state.items.map((item) {
        if (item.id != id) return item;
        updatedItem = update(item);
        return updatedItem!;
      }).toList(),
    );
    return updatedItem;
  }

  Future<void> _syncRemote(MediaItem item) async {
    try {
      await _repository.syncMedia(item);
    } catch (_) {}
  }

  Future<void> _updateRemote(MediaItem item) async {
    try {
      await _repository.updateMedia(item);
    } catch (_) {
      await _syncRemote(item);
    }
  }

  Future<void> _deleteRemote(String id) async {
    try {
      await _repository.deleteMedia(id);
    } catch (_) {}
  }
}

Future<double> _sizeMb(File? file) async {
  if (file == null) return 0;
  try {
    final bytes = await file.length();
    return bytes / (1024 * 1024);
  } catch (_) {
    return 0;
  }
}

final mediaLibraryProvider =
    StateNotifierProvider<MediaLibraryController, MediaLibraryState>(
      (ref) => MediaLibraryController(ref.watch(mediaRepositoryProvider)),
    );
