import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';

enum DigiDocumentType {
  aadhaarPan,
  aadhaarCard,
  panCard,
  voterId,
  passport,
  drivingLicence,
  vehicleRc,
  insurance,
  medical,
  property,
  education,
  class10Marksheet,
  class12Marksheet,
  finance,
  other,
}

const defaultDigiDocumentCards = [
  DigiDocumentCard(
    id: 'class-10',
    title: '10th Marksheet',
    subtitle: 'Board result and school record',
    type: DigiDocumentType.class10Marksheet,
    icon: Icons.school_rounded,
    colorValue: 0xFF2F86FF,
  ),
  DigiDocumentCard(
    id: 'class-12',
    title: '12th Marksheet',
    subtitle: 'Senior secondary marksheet',
    type: DigiDocumentType.class12Marksheet,
    icon: Icons.workspace_premium_rounded,
    colorValue: 0xFF7C3DFF,
  ),
  DigiDocumentCard(
    id: 'aadhaar',
    title: 'Aadhaar Card',
    subtitle: 'UIDAI identity proof',
    type: DigiDocumentType.aadhaarCard,
    icon: Icons.fingerprint_rounded,
    colorValue: 0xFF20A9C8,
  ),
  DigiDocumentCard(
    id: 'pan',
    title: 'PAN Card',
    subtitle: 'Income tax identity',
    type: DigiDocumentType.panCard,
    icon: Icons.credit_card_rounded,
    colorValue: 0xFF39C978,
  ),
  DigiDocumentCard(
    id: 'voter',
    title: 'Voter ID',
    subtitle: 'Election photo identity',
    type: DigiDocumentType.voterId,
    icon: Icons.how_to_vote_rounded,
    colorValue: 0xFFE84A5F,
  ),
  DigiDocumentCard(
    id: 'driving',
    title: 'Driving Licence',
    subtitle: 'DL number and validity',
    type: DigiDocumentType.drivingLicence,
    icon: Icons.badge_rounded,
    colorValue: 0xFFFF8B22,
  ),
  DigiDocumentCard(
    id: 'vehicle-rc',
    title: 'Vehicle RC',
    subtitle: 'Registration certificate',
    type: DigiDocumentType.vehicleRc,
    icon: Icons.directions_car_rounded,
    colorValue: 0xFF29A8FF,
  ),
  DigiDocumentCard(
    id: 'insurance',
    title: 'Insurance',
    subtitle: 'Policy and premium documents',
    type: DigiDocumentType.insurance,
    icon: Icons.health_and_safety_rounded,
    colorValue: 0xFF9B7CFF,
  ),
];

class DigiDocumentCard {
  const DigiDocumentCard({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.icon,
    required this.colorValue,
    this.isCustom = false,
    this.createdAt,
  });

  final String id;
  final String title;
  final String subtitle;
  final DigiDocumentType type;
  final IconData icon;
  final int colorValue;
  final bool isCustom;
  final DateTime? createdAt;

  Color get color => Color(colorValue);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'type': type.name,
      'icon': icon.codePoint,
      'colorValue': colorValue,
      'isCustom': isCustom,
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
    };
  }

  factory DigiDocumentCard.fromMap(Map<dynamic, dynamic> map) {
    final typeName = map['type']?.toString() ?? 'other';
    return DigiDocumentCard(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      subtitle: map['subtitle']?.toString() ?? 'Custom document',
      type: DigiDocumentType.values.firstWhere(
        (item) => item.name == typeName,
        orElse: () => DigiDocumentType.other,
      ),
      icon: digiDocumentIconFromCodePoint(map['icon']),
      colorValue: map['colorValue'] is int
          ? map['colorValue'] as int
          : AppColors.blue.toARGB32(),
      isCustom: map['isCustom'] == true,
      createdAt:
          DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

IconData digiDocumentIconFromCodePoint(Object? value) {
  final codePoint = value is int ? value : Icons.description_rounded.codePoint;
  return _digiDocumentIconMap[codePoint] ?? Icons.description_rounded;
}

final Map<int, IconData> _digiDocumentIconMap = {
  Icons.school_rounded.codePoint: Icons.school_rounded,
  Icons.workspace_premium_rounded.codePoint: Icons.workspace_premium_rounded,
  Icons.fingerprint_rounded.codePoint: Icons.fingerprint_rounded,
  Icons.credit_card_rounded.codePoint: Icons.credit_card_rounded,
  Icons.how_to_vote_rounded.codePoint: Icons.how_to_vote_rounded,
  Icons.badge_rounded.codePoint: Icons.badge_rounded,
  Icons.directions_car_rounded.codePoint: Icons.directions_car_rounded,
  Icons.health_and_safety_rounded.codePoint: Icons.health_and_safety_rounded,
  Icons.note_add_rounded.codePoint: Icons.note_add_rounded,
  Icons.description_rounded.codePoint: Icons.description_rounded,
};

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
    this.extractedFields = const {},
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
  final Map<String, String> extractedFields;
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
    Map<String, String>? extractedFields,
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
      extractedFields: extractedFields ?? this.extractedFields,
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
      'extractedFields': extractedFields,
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
      extractedFields:
          (map['extractedFields'] as Map?)?.map(
            (key, value) => MapEntry(key.toString(), value.toString()),
          ) ??
          const {},
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
    DigiDocumentType.aadhaarCard => 'Aadhaar Card',
    DigiDocumentType.panCard => 'PAN Card',
    DigiDocumentType.voterId => 'Voter ID',
    DigiDocumentType.passport => 'Passport',
    DigiDocumentType.drivingLicence => 'Driving Licence',
    DigiDocumentType.vehicleRc => 'Vehicle RC',
    DigiDocumentType.insurance => 'Insurance',
    DigiDocumentType.medical => 'Medical',
    DigiDocumentType.property => 'Property',
    DigiDocumentType.education => 'Education',
    DigiDocumentType.class10Marksheet => '10th Marksheet',
    DigiDocumentType.class12Marksheet => '12th Marksheet',
    DigiDocumentType.finance => 'Finance',
    DigiDocumentType.other => 'Other',
  };
}

DigiDocumentType digiDocumentTypeFromName(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('aadhaar') ||
      lower.contains('aadhar') ||
      lower.contains('uidai')) {
    return DigiDocumentType.aadhaarCard;
  }
  if (lower.contains('pan') ||
      RegExp(r'\b[A-Z]{5}[0-9]{4}[A-Z]\b').hasMatch(name)) {
    return DigiDocumentType.panCard;
  }
  if (lower.contains('voter') || lower.contains('election')) {
    return DigiDocumentType.voterId;
  }
  if (lower.contains('passport')) return DigiDocumentType.passport;
  if (lower.contains('licence') ||
      lower.contains('license') ||
      lower.contains('dl')) {
    return DigiDocumentType.drivingLicence;
  }
  if (lower.contains('vehicle') ||
      lower.contains('registration') ||
      lower.contains(' rc') ||
      lower.contains('rc ')) {
    return DigiDocumentType.vehicleRc;
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
  if (lower.contains('10th') || lower.contains('class 10')) {
    return DigiDocumentType.class10Marksheet;
  }
  if (lower.contains('xth') || lower.contains('class x')) {
    return DigiDocumentType.class10Marksheet;
  }
  if (lower.contains('12th') ||
      lower.contains('class 12') ||
      lower.contains('senior secondary')) {
    return DigiDocumentType.class12Marksheet;
  }
  if (lower.contains('xiith') || lower.contains('class xii')) {
    return DigiDocumentType.class12Marksheet;
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

String digiDocumentSuggestedTitle(String text, {String fallback = 'Document'}) {
  final lower = text.toLowerCase();
  if (lower.contains('resume') ||
      lower.contains('curriculum vitae') ||
      lower.contains('work experience')) {
    return 'Resume';
  }
  if (lower.contains('income certificate') ||
      lower.contains('annual income') ||
      lower.contains('family income')) {
    return 'Income Certificate';
  }
  if (lower.contains('birth certificate')) return 'Birth Certificate';
  if (lower.contains('domicile certificate')) return 'Domicile Certificate';
  if (lower.contains('caste certificate')) return 'Caste Certificate';
  if (lower.contains('bonafide certificate')) return 'Bonafide Certificate';
  final detected = digiDocumentTypeFromName(text);
  if (detected != DigiDocumentType.other) {
    return digiDocumentTypeLabel(detected);
  }
  return fallback.trim().isEmpty ? 'Document' : fallback.trim();
}
