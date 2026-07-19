import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';

enum VaultFileType { pdf, image, video, archive, document, presentation, other }

class VaultFile {
  const VaultFile({
    required this.id,
    required this.name,
    required this.extension,
    required this.sizeBytes,
    required this.type,
    required this.addedAt,
    required this.updatedAt,
    required this.tags,
    this.path,
    this.remoteId,
    this.remoteUrl,
    this.isSynced = false,
    this.isFavorite = false,
    this.isArchived = false,
    this.isEncrypted = true,
    this.isPrivate = false,
    this.folderId,
  });

  final String id;
  final String name;
  final String extension;
  final int sizeBytes;
  final VaultFileType type;
  final DateTime addedAt;
  final DateTime updatedAt;
  final List<String> tags;
  final String? path;
  final int? remoteId;
  final String? remoteUrl;
  final bool isSynced;
  final bool isFavorite;
  final bool isArchived;
  final bool isEncrypted;
  final bool isPrivate;
  final String? folderId;

  String get sizeLabel {
    if (sizeBytes <= 0) return 'Unknown size';
    final kb = sizeBytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(0)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }

  IconData get icon {
    return switch (type) {
      VaultFileType.pdf => Icons.picture_as_pdf_rounded,
      VaultFileType.image => Icons.image_rounded,
      VaultFileType.video => Icons.play_circle_rounded,
      VaultFileType.archive => Icons.archive_rounded,
      VaultFileType.document => Icons.description_rounded,
      VaultFileType.presentation => Icons.slideshow_rounded,
      VaultFileType.other => Icons.insert_drive_file_rounded,
    };
  }

  Color get color {
    return switch (type) {
      VaultFileType.pdf => AppColors.danger,
      VaultFileType.image => AppColors.cyan,
      VaultFileType.video => AppColors.purple,
      VaultFileType.archive => AppColors.orange,
      VaultFileType.document => AppColors.blue,
      VaultFileType.presentation => AppColors.success,
      VaultFileType.other => AppColors.textMuted,
    };
  }

  String get typeLabel {
    return switch (type) {
      VaultFileType.pdf => 'PDF',
      VaultFileType.image => 'Image',
      VaultFileType.video => 'Video',
      VaultFileType.archive => 'Archive',
      VaultFileType.document => 'Document',
      VaultFileType.presentation => 'PPT',
      VaultFileType.other => 'File',
    };
  }

  VaultFile copyWith({
    String? name,
    List<String>? tags,
    String? path,
    int? remoteId,
    String? remoteUrl,
    bool? isSynced,
    bool? isFavorite,
    bool? isArchived,
    bool? isEncrypted,
    bool? isPrivate,
    DateTime? updatedAt,
    String? folderId,
    bool clearFolder = false,
  }) {
    return VaultFile(
      id: id,
      name: name ?? this.name,
      extension: extension,
      sizeBytes: sizeBytes,
      type: type,
      addedAt: addedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      path: path ?? this.path,
      remoteId: remoteId ?? this.remoteId,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      isSynced: isSynced ?? this.isSynced,
      isFavorite: isFavorite ?? this.isFavorite,
      isArchived: isArchived ?? this.isArchived,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      isPrivate: isPrivate ?? this.isPrivate,
      folderId: clearFolder ? null : folderId ?? this.folderId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'extension': extension,
      'sizeBytes': sizeBytes,
      'type': type.name,
      'addedAt': addedAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'tags': tags,
      'path': path,
      'remoteId': remoteId,
      'remoteUrl': remoteUrl,
      'isSynced': isSynced,
      'isFavorite': isFavorite,
      'isArchived': isArchived,
      'isEncrypted': isEncrypted,
      'isPrivate': isPrivate,
      'folderId': folderId,
    };
  }

  factory VaultFile.fromMap(Map<dynamic, dynamic> map) {
    final typeName = map['type']?.toString() ?? 'other';
    return VaultFile(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      extension: map['extension']?.toString() ?? '',
      sizeBytes: map['sizeBytes'] is int ? map['sizeBytes'] as int : 0,
      type: VaultFileType.values.firstWhere(
        (item) => item.name == typeName,
        orElse: () => VaultFileType.other,
      ),
      addedAt:
          DateTime.tryParse(map['addedAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt:
          DateTime.tryParse(map['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
      tags:
          (map['tags'] as List?)?.map((item) => item.toString()).toList() ??
          const [],
      path: map['path']?.toString(),
      remoteId: map['remoteId'] is int ? map['remoteId'] as int : null,
      remoteUrl: map['remoteUrl']?.toString(),
      isSynced: map['isSynced'] == true,
      isFavorite: map['isFavorite'] == true,
      isArchived: map['isArchived'] == true,
      isEncrypted: map['isEncrypted'] != false,
      isPrivate: map['isPrivate'] == true,
      folderId: map['folderId']?.toString(),
    );
  }
}

class VaultFolder {
  const VaultFolder({
    required this.id,
    required this.name,
    required this.createdAt,
  });
  final String id;
  final String name;
  final DateTime createdAt;
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
  };
  factory VaultFolder.fromMap(Map<dynamic, dynamic> map) => VaultFolder(
    id: map['id']?.toString() ?? '',
    name: map['name']?.toString() ?? '',
    createdAt:
        DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
  );
}
