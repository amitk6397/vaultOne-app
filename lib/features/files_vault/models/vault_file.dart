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
    this.isFavorite = false,
    this.isArchived = false,
    this.isEncrypted = true,
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
  final bool isFavorite;
  final bool isArchived;
  final bool isEncrypted;

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
    bool? isFavorite,
    bool? isArchived,
    bool? isEncrypted,
    DateTime? updatedAt,
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
      path: path,
      isFavorite: isFavorite ?? this.isFavorite,
      isArchived: isArchived ?? this.isArchived,
      isEncrypted: isEncrypted ?? this.isEncrypted,
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
      'isFavorite': isFavorite,
      'isArchived': isArchived,
      'isEncrypted': isEncrypted,
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
      isFavorite: map['isFavorite'] == true,
      isArchived: map['isArchived'] == true,
      isEncrypted: map['isEncrypted'] != false,
    );
  }
}
