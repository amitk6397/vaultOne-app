import 'dart:io';

import 'package:flutter_riverpod/legacy.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../constants/app_colors.dart';
import '../models/media_item.dart';

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
    );
  }
}

class MediaLibraryController extends StateNotifier<MediaLibraryState> {
  static const privatePhotoLimit = 10;
  static const privateVideoLimitMb = 500.0;

  MediaLibraryController()
    : super(
        MediaLibraryState(
          items: _seedItems(),
          albums: const [
            MediaAlbum(
              id: 'travel',
              name: 'Travel',
              kind: MediaKind.photo,
              isPrivate: false,
              accent: AppColors.blue,
            ),
            MediaAlbum(
              id: 'family',
              name: 'Family',
              kind: MediaKind.photo,
              isPrivate: true,
              accent: AppColors.purple,
            ),
            MediaAlbum(
              id: 'work',
              name: 'Work Videos',
              kind: MediaKind.video,
              isPrivate: false,
              accent: AppColors.orange,
            ),
            MediaAlbum(
              id: 'vault',
              name: 'Private Vault',
              kind: MediaKind.video,
              isPrivate: true,
              accent: AppColors.cyan,
            ),
          ],
          security: const MediaSecuritySettings(),
        ),
      );

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
    if (item.kind == MediaKind.photo && privatePhotoCount >= privatePhotoLimit) {
      return 'Private photos limit is $privatePhotoLimit. Remove one first.';
    }
    if (item.kind == MediaKind.video &&
        privateVideoUsedMb + item.sizeMb > privateVideoLimitMb) {
      final left = (privateVideoLimitMb - privateVideoUsedMb).clamp(0, privateVideoLimitMb);
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
        final file = await asset.file;
        final sizeMb = await _sizeMb(file);
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
            sizeMb: sizeMb,
            accent: previous?.accent ?? mediaAccentForIndex(scanned.length),
            path: file?.path,
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

  void toggleFavorite(String id) =>
      _updateItem(id, (item) => item.copyWith(isFavorite: !item.isFavorite));

  void toggleHidden(String id) =>
      _updateItem(id, (item) => item.copyWith(isHidden: !item.isHidden));

  String? moveVisibility(String id, MediaVisibility visibility) {
    final item = itemById(id);
    if (item == null) return 'Media not found';
    if (visibility == MediaVisibility.private) {
      final reason = privateMoveBlockReason(item);
      if (reason != null) return reason;
    }
    _updateItem(id, (item) => item.copyWith(visibility: visibility));
    return null;
  }

  void moveSelectedTo(MediaVisibility visibility) {
    final selected = state.selectedIds;
    state = state.copyWith(
      items: state.items
          .map(
            (item) => selected.contains(item.id)
                ? item.copyWith(visibility: visibility)
                : item,
          )
          .toList(),
      selectedIds: {},
    );
  }

  void moveToAlbum(String id, MediaAlbum album) {
    _updateItem(
      id,
      (item) => item.copyWith(albumId: album.id, albumName: album.name),
    );
  }

  void deleteItem(String id) {
    _updateItem(id, (item) => item.copyWith(isDeleted: true));
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
    return true;
  }

  void restoreItem(String id) {
    _updateItem(id, (item) => item.copyWith(isDeleted: false));
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
  }

  void deleteAlbum(String id) {
    state = state.copyWith(
      albums: state.albums.where((album) => album.id != id).toList(),
      items: state.items
          .map(
            (item) => item.albumId == id
                ? item.copyWith(
                    albumId: 'uncategorized',
                    albumName: 'Uncategorized',
                  )
                : item,
          )
          .toList(),
    );
  }

  Future<int> importPhotos() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(imageQuality: 88);
    if (images.isEmpty) return 0;
    final additions = images.asMap().entries.map((entry) {
      final index = entry.key;
      final image = entry.value;
      return MediaItem(
        id: 'photo-${DateTime.now().microsecondsSinceEpoch}-$index',
        title: image.name,
        kind: MediaKind.photo,
        visibility: MediaVisibility.public,
        albumId: 'travel',
        albumName: 'Travel',
        folderName: 'Camera Imports',
        createdAt: DateTime.now(),
        sizeMb: 2.8,
        accent: mediaAccentForIndex(index),
        path: image.path,
      );
    }).toList();
    state = state.copyWith(items: [...additions, ...state.items]);
    return additions.length;
  }

  Future<int> importVideos() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.gallery);
    if (video == null) return 0;
    final item = MediaItem(
      id: 'video-${DateTime.now().microsecondsSinceEpoch}',
      title: video.name,
      kind: MediaKind.video,
      visibility: MediaVisibility.public,
      albumId: 'work',
      albumName: 'Work Videos',
      folderName: 'Imports',
      createdAt: DateTime.now(),
      sizeMb: 38,
      accent: AppColors.purple,
      path: video.path,
      duration: const Duration(minutes: 4, seconds: 24),
    );
    state = state.copyWith(items: [item, ...state.items]);
    return 1;
  }

  void savePlaybackPosition(String id, Duration position) {
    _updateItem(id, (item) => item.copyWith(lastPosition: position));
  }

  void updateSecurity(MediaSecuritySettings settings) {
    state = state.copyWith(security: settings);
  }

  void _updateItem(String id, MediaItem Function(MediaItem item) update) {
    state = state.copyWith(
      items: state.items
          .map((item) => item.id == id ? update(item) : item)
          .toList(),
    );
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
      (ref) => MediaLibraryController(),
    );

List<MediaItem> _seedItems() {
  final now = DateTime.now();
  return [
    MediaItem(
      id: 'p1',
      title: 'Goa Sunset',
      kind: MediaKind.photo,
      visibility: MediaVisibility.public,
      albumId: 'travel',
      albumName: 'Travel',
      folderName: 'Camera',
      createdAt: now.subtract(const Duration(days: 1)),
      sizeMb: 3.4,
      accent: AppColors.orange,
      isFavorite: true,
    ),
    MediaItem(
      id: 'p2',
      title: 'Family Dinner',
      kind: MediaKind.photo,
      visibility: MediaVisibility.private,
      albumId: 'family',
      albumName: 'Family',
      folderName: 'Private Vault',
      createdAt: now.subtract(const Duration(days: 4)),
      sizeMb: 2.7,
      accent: AppColors.purple,
    ),
    MediaItem(
      id: 'p3',
      title: 'Office Whiteboard',
      kind: MediaKind.photo,
      visibility: MediaVisibility.public,
      albumId: 'uncategorized',
      albumName: 'Uncategorized',
      folderName: 'Screenshots',
      createdAt: now.subtract(const Duration(days: 8)),
      sizeMb: 1.6,
      accent: AppColors.cyan,
      isHidden: true,
    ),
    MediaItem(
      id: 'v1',
      title: 'Project Walkthrough',
      kind: MediaKind.video,
      visibility: MediaVisibility.public,
      albumId: 'work',
      albumName: 'Work Videos',
      folderName: 'Work',
      createdAt: now.subtract(const Duration(hours: 12)),
      sizeMb: 64,
      accent: AppColors.blue,
      duration: const Duration(minutes: 12, seconds: 32),
      lastPosition: const Duration(minutes: 3, seconds: 20),
    ),
    MediaItem(
      id: 'v2',
      title: 'Private Memory',
      kind: MediaKind.video,
      visibility: MediaVisibility.private,
      albumId: 'vault',
      albumName: 'Private Vault',
      folderName: 'Private Vault',
      createdAt: now.subtract(const Duration(days: 3)),
      sizeMb: 118,
      accent: AppColors.purple,
      duration: const Duration(minutes: 7, seconds: 8),
      isFavorite: true,
    ),
    MediaItem(
      id: 'v3',
      title: 'Landscape Timelapse',
      kind: MediaKind.video,
      visibility: MediaVisibility.public,
      albumId: 'travel',
      albumName: 'Travel',
      folderName: 'Travel',
      createdAt: now.subtract(const Duration(days: 10)),
      sizeMb: 92,
      accent: AppColors.success,
      duration: const Duration(minutes: 2, seconds: 46),
    ),
  ];
}
