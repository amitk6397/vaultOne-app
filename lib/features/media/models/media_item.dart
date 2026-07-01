import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';

enum MediaKind { photo, video }

enum MediaVisibility { public, private }

enum MediaSort { dateNewest, dateOldest, name, sizeLargest }

enum MediaViewMode { grid, list }

class MediaItem {
  const MediaItem({
    required this.id,
    required this.title,
    required this.kind,
    required this.visibility,
    required this.albumId,
    required this.albumName,
    required this.folderName,
    required this.createdAt,
    required this.sizeMb,
    required this.accent,
    this.assetId,
    this.path,
    this.duration,
    this.isFavorite = false,
    this.isHidden = false,
    this.isDeleted = false,
    this.lastPosition,
  });

  final String id;
  final String title;
  final MediaKind kind;
  final MediaVisibility visibility;
  final String albumId;
  final String albumName;
  final String folderName;
  final DateTime createdAt;
  final double sizeMb;
  final Color accent;
  final String? assetId;
  final String? path;
  final Duration? duration;
  final bool isFavorite;
  final bool isHidden;
  final bool isDeleted;
  final Duration? lastPosition;

  bool get isPrivate => visibility == MediaVisibility.private;

  String get sizeLabel => '${sizeMb.toStringAsFixed(sizeMb >= 10 ? 0 : 1)} MB';

  String get dateLabel =>
      '${createdAt.day}/${createdAt.month}/${createdAt.year}';

  String get durationLabel {
    final value = duration;
    if (value == null) return '';
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (value.inHours > 0) {
      return '${value.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  MediaItem copyWith({
    String? title,
    MediaVisibility? visibility,
    String? albumId,
    String? albumName,
    String? folderName,
    bool? isFavorite,
    bool? isHidden,
    bool? isDeleted,
    Duration? lastPosition,
    String? assetId,
    String? path,
  }) {
    return MediaItem(
      id: id,
      title: title ?? this.title,
      kind: kind,
      visibility: visibility ?? this.visibility,
      albumId: albumId ?? this.albumId,
      albumName: albumName ?? this.albumName,
      folderName: folderName ?? this.folderName,
      createdAt: createdAt,
      sizeMb: sizeMb,
      accent: accent,
      assetId: assetId ?? this.assetId,
      path: path ?? this.path,
      duration: duration,
      isFavorite: isFavorite ?? this.isFavorite,
      isHidden: isHidden ?? this.isHidden,
      isDeleted: isDeleted ?? this.isDeleted,
      lastPosition: lastPosition ?? this.lastPosition,
    );
  }
}

class MediaAlbum {
  const MediaAlbum({
    required this.id,
    required this.name,
    required this.kind,
    required this.isPrivate,
    required this.accent,
  });

  final String id;
  final String name;
  final MediaKind kind;
  final bool isPrivate;
  final Color accent;

  MediaAlbum copyWith({String? name}) {
    return MediaAlbum(
      id: id,
      name: name ?? this.name,
      kind: kind,
      isPrivate: isPrivate,
      accent: accent,
    );
  }
}

class MediaSecuritySettings {
  const MediaSecuritySettings({
    this.pinEnabled = true,
    this.biometricsEnabled = true,
    this.encryptionEnabled = true,
    this.autoLockEnabled = true,
    this.screenshotProtectionEnabled = true,
    this.hiddenVaultEnabled = false,
  });

  final bool pinEnabled;
  final bool biometricsEnabled;
  final bool encryptionEnabled;
  final bool autoLockEnabled;
  final bool screenshotProtectionEnabled;
  final bool hiddenVaultEnabled;

  MediaSecuritySettings copyWith({
    bool? pinEnabled,
    bool? biometricsEnabled,
    bool? encryptionEnabled,
    bool? autoLockEnabled,
    bool? screenshotProtectionEnabled,
    bool? hiddenVaultEnabled,
  }) {
    return MediaSecuritySettings(
      pinEnabled: pinEnabled ?? this.pinEnabled,
      biometricsEnabled: biometricsEnabled ?? this.biometricsEnabled,
      encryptionEnabled: encryptionEnabled ?? this.encryptionEnabled,
      autoLockEnabled: autoLockEnabled ?? this.autoLockEnabled,
      screenshotProtectionEnabled:
          screenshotProtectionEnabled ?? this.screenshotProtectionEnabled,
      hiddenVaultEnabled: hiddenVaultEnabled ?? this.hiddenVaultEnabled,
    );
  }
}

Color mediaAccentForIndex(int index) {
  const colors = [
    AppColors.blue,
    AppColors.purple,
    AppColors.orange,
    AppColors.cyan,
    AppColors.success,
  ];
  return colors[index % colors.length];
}
