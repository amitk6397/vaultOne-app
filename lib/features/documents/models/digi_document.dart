import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';

enum DigiDocumentType {
  aadhaarPan,
  passport,
  drivingLicence,
  insurance,
  medical,
  property,
  education,
  finance,
  other,
}

class DigiFolder {
  const DigiFolder({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.createdAt,
  });

  final String id;
  final String name;
  final int colorValue;
  final DateTime createdAt;

  Color get color => Color(colorValue);

  DigiFolder copyWith({String? name, int? colorValue}) {
    return DigiFolder(
      id: id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'colorValue': colorValue,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory DigiFolder.fromMap(Map<dynamic, dynamic> map) {
    return DigiFolder(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      colorValue: map['colorValue'] is int
          ? map['colorValue'] as int
          : AppColors.blue.toARGB32(),
      createdAt:
          DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class DigiDocument {
  const DigiDocument({
    required this.id,
    required this.title,
    required this.fileName,
    required this.extension,
    required this.sizeBytes,
    required this.type,
    required this.folderId,
    required this.addedAt,
    required this.updatedAt,
    this.filePath,
    this.ocrText = '',
    this.issuer = '',
    this.documentNumber = '',
    this.expiryDate,
    this.isFavorite = false,
    this.isVerified = false,
  });

  final String id;
  final String title;
  final String fileName;
  final String extension;
  final int sizeBytes;
  final DigiDocumentType type;
  final String folderId;
  final String? filePath;
  final String ocrText;
  final String issuer;
  final String documentNumber;
  final DateTime? expiryDate;
  final bool isFavorite;
  final bool isVerified;
  final DateTime addedAt;
  final DateTime updatedAt;

  String get typeLabel => digiDocumentTypeLabel(type);

  String get sizeLabel {
    if (sizeBytes <= 0) return 'Unknown';
    final kb = sizeBytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(0)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }

  String get expiryLabel {
    final expiry = expiryDate;
    if (expiry == null) return 'No expiry';
    final days = expiry.difference(DateTime.now()).inDays;
    if (days < 0) return 'Expired';
    if (days == 0) return 'Expires today';
    return 'In $days days';
  }

  bool get isExpired {
    final expiry = expiryDate;
    return expiry != null && expiry.isBefore(DateTime.now());
  }

  bool get isExpiringSoon {
    final expiry = expiryDate;
    if (expiry == null) return false;
    final days = expiry.difference(DateTime.now()).inDays;
    return days >= 0 && days <= 45;
  }

  IconData get icon {
    return switch (extension.toLowerCase()) {
      'pdf' => Icons.picture_as_pdf_rounded,
      'jpg' || 'jpeg' || 'png' => Icons.image_rounded,
      _ => Icons.description_rounded,
    };
  }

  DigiDocument copyWith({
    String? title,
    DigiDocumentType? type,
    String? folderId,
    String? ocrText,
    String? issuer,
    String? documentNumber,
    DateTime? expiryDate,
    bool? isFavorite,
    bool? isVerified,
    DateTime? updatedAt,
  }) {
    return DigiDocument(
      id: id,
      title: title ?? this.title,
      fileName: fileName,
      extension: extension,
      sizeBytes: sizeBytes,
      type: type ?? this.type,
      folderId: folderId ?? this.folderId,
      filePath: filePath,
      ocrText: ocrText ?? this.ocrText,
      issuer: issuer ?? this.issuer,
      documentNumber: documentNumber ?? this.documentNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      isFavorite: isFavorite ?? this.isFavorite,
      isVerified: isVerified ?? this.isVerified,
      addedAt: addedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'fileName': fileName,
      'extension': extension,
      'sizeBytes': sizeBytes,
      'type': type.name,
      'folderId': folderId,
      'filePath': filePath,
      'ocrText': ocrText,
      'issuer': issuer,
      'documentNumber': documentNumber,
      'expiryDate': expiryDate?.toIso8601String(),
      'isFavorite': isFavorite,
      'isVerified': isVerified,
      'addedAt': addedAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DigiDocument.fromMap(Map<dynamic, dynamic> map) {
    final typeName = map['type']?.toString() ?? 'other';
    return DigiDocument(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      fileName: map['fileName']?.toString() ?? '',
      extension: map['extension']?.toString() ?? '',
      sizeBytes: map['sizeBytes'] is int ? map['sizeBytes'] as int : 0,
      type: DigiDocumentType.values.firstWhere(
        (item) => item.name == typeName,
        orElse: () => DigiDocumentType.other,
      ),
      folderId: map['folderId']?.toString() ?? '',
      filePath: map['filePath']?.toString(),
      ocrText: map['ocrText']?.toString() ?? '',
      issuer: map['issuer']?.toString() ?? '',
      documentNumber: map['documentNumber']?.toString() ?? '',
      expiryDate: DateTime.tryParse(map['expiryDate']?.toString() ?? ''),
      isFavorite: map['isFavorite'] == true,
      isVerified: map['isVerified'] == true,
      addedAt:
          DateTime.tryParse(map['addedAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt:
          DateTime.tryParse(map['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

String digiDocumentTypeLabel(DigiDocumentType type) {
  return switch (type) {
    DigiDocumentType.aadhaarPan => 'Aadhaar / PAN',
    DigiDocumentType.passport => 'Passport',
    DigiDocumentType.drivingLicence => 'Driving Licence',
    DigiDocumentType.insurance => 'Insurance',
    DigiDocumentType.medical => 'Medical',
    DigiDocumentType.property => 'Property',
    DigiDocumentType.education => 'Education',
    DigiDocumentType.finance => 'Finance',
    DigiDocumentType.other => 'Other',
  };
}

DigiDocumentType digiDocumentTypeFromName(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('aadhaar') ||
      lower.contains('aadhar') ||
      lower.contains('pan')) {
    return DigiDocumentType.aadhaarPan;
  }
  if (lower.contains('passport')) return DigiDocumentType.passport;
  if (lower.contains('licence') ||
      lower.contains('license') ||
      lower.contains('dl')) {
    return DigiDocumentType.drivingLicence;
  }
  if (lower.contains('insurance') || lower.contains('policy')) {
    return DigiDocumentType.insurance;
  }
  if (lower.contains('medical') ||
      lower.contains('report') ||
      lower.contains('lab')) {
    return DigiDocumentType.medical;
  }
  if (lower.contains('property') || lower.contains('home')) {
    return DigiDocumentType.property;
  }
  if (lower.contains('mark') ||
      lower.contains('degree') ||
      lower.contains('school')) {
    return DigiDocumentType.education;
  }
  if (lower.contains('bank') || lower.contains('tax')) {
    return DigiDocumentType.finance;
  }
  return DigiDocumentType.other;
}
