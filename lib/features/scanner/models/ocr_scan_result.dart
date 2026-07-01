enum OcrEntityType { email, phone, date, aadhaar, pan, amount, url }

class OcrEntity {
  const OcrEntity({required this.type, required this.value});

  final OcrEntityType type;
  final String value;

  String get label {
    return switch (type) {
      OcrEntityType.email => 'Email',
      OcrEntityType.phone => 'Phone',
      OcrEntityType.date => 'Date',
      OcrEntityType.aadhaar => 'Aadhaar',
      OcrEntityType.pan => 'PAN',
      OcrEntityType.amount => 'Amount',
      OcrEntityType.url => 'URL',
    };
  }

  Map<String, dynamic> toMap() {
    return {'type': type.name, 'value': value};
  }

  factory OcrEntity.fromMap(Map<dynamic, dynamic> map) {
    final typeName = map['type']?.toString() ?? 'url';
    return OcrEntity(
      type: OcrEntityType.values.firstWhere(
        (item) => item.name == typeName,
        orElse: () => OcrEntityType.url,
      ),
      value: map['value']?.toString() ?? '',
    );
  }
}

class OcrScanResult {
  const OcrScanResult({
    required this.id,
    required this.title,
    required this.imagePath,
    required this.rawText,
    required this.lines,
    required this.entities,
    required this.createdAt,
    this.documentType = 'General',
    this.isFavorite = false,
  });

  final String id;
  final String title;
  final String imagePath;
  final String rawText;
  final List<String> lines;
  final List<OcrEntity> entities;
  final String documentType;
  final bool isFavorite;
  final DateTime createdAt;

  bool get hasText => rawText.trim().isNotEmpty;

  OcrScanResult copyWith({
    String? title,
    String? documentType,
    bool? isFavorite,
  }) {
    return OcrScanResult(
      id: id,
      title: title ?? this.title,
      imagePath: imagePath,
      rawText: rawText,
      lines: lines,
      entities: entities,
      documentType: documentType ?? this.documentType,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'imagePath': imagePath,
      'rawText': rawText,
      'lines': lines,
      'entities': entities.map((item) => item.toMap()).toList(),
      'documentType': documentType,
      'isFavorite': isFavorite,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory OcrScanResult.fromMap(Map<dynamic, dynamic> map) {
    return OcrScanResult(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      imagePath: map['imagePath']?.toString() ?? '',
      rawText: map['rawText']?.toString() ?? '',
      lines:
          (map['lines'] as List?)?.map((item) => item.toString()).toList() ??
          const [],
      entities:
          (map['entities'] as List?)
              ?.whereType<Map>()
              .map(OcrEntity.fromMap)
              .where((item) => item.value.isNotEmpty)
              .toList() ??
          const [],
      documentType: map['documentType']?.toString() ?? 'General',
      isFavorite: map['isFavorite'] == true,
      createdAt:
          DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
