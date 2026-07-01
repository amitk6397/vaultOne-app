import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';

enum VaultFileType { pdf, image, video, archive, document, presentation, other }

class VaultFile {
  const VaultFile({
    required this.id,
    required this.name,
    required this.extension,
    required this.sizeLabel,
    required this.type,
    required this.addedAt,
    required this.tags,
    this.path,
  });

  final String id;
  final String name;
  final String extension;
  final String sizeLabel;
  final VaultFileType type;
  final DateTime addedAt;
  final List<String> tags;
  final String? path;

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
}
