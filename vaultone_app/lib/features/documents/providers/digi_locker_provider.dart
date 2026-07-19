import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/storage/module_storage_controller.dart';

import '../../../constants/app_colors.dart';
import '../../scanner/models/ocr_scan_result.dart';
import '../../scanner/providers/scanner_provider.dart';
import '../../scanner/repositories/ai_ocr_repository.dart';
import '../models/digi_document.dart';
import '../repositories/digi_locker_repository.dart';

const _documentsBoxName = 'digi_locker_documents';
const _foldersBoxName = 'digi_locker_folders';
const _cardsBoxName = 'digi_locker_custom_cards';

final digiSearchProvider = StateProvider<String>((ref) => '');
final selectedDigiTypeProvider = StateProvider<String>((ref) => 'All');
final selectedDigiFolderProvider = StateProvider<String?>((ref) => null);

final digiLockerProvider =
    StateNotifierProvider<DigiLockerController, DigiLockerState>(
      (ref) => DigiLockerController(
        ref.watch(digiLockerRepositoryProvider),
        ref.watch(aiOcrRepositoryProvider),
      ),
    );

class DigiLockerState {
  const DigiLockerState({
    this.documents = const [],
    this.folders = const [],
    this.customCards = const [],
    this.isLoading = true,
    this.error,
  });

  final List<DigiDocument> documents;
  final List<DigiFolder> folders;
  final List<DigiDocumentCard> customCards;
  final bool isLoading;
  final String? error;

  int get expiringCount =>
      documents.where((doc) => doc.isExpired || doc.isExpiringSoon).length;

  int get verifiedCount => documents.where((doc) => doc.isVerified).length;

  DigiLockerState copyWith({
    List<DigiDocument>? documents,
    List<DigiFolder>? folders,
    List<DigiDocumentCard>? customCards,
    bool? isLoading,
    String? error,
  }) {
    return DigiLockerState(
      documents: documents ?? this.documents,
      folders: folders ?? this.folders,
      customCards: customCards ?? this.customCards,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class DigiImportAnalysis {
  const DigiImportAnalysis({
    required this.file,
    required this.folderId,
    required this.expectedCard,
    required this.extension,
    required this.fileTitle,
    required this.ocrText,
    required this.detectedType,
    required this.suggestedTitle,
    required this.extractedFields,
  });

  final PlatformFile file;
  final String folderId;
  final DigiDocumentCard expectedCard;
  final String extension;
  final String fileTitle;
  final String ocrText;
  final DigiDocumentType detectedType;
  final String suggestedTitle;
  final Map<String, String> extractedFields;

  bool get hasOcrText => ocrText.trim().isNotEmpty;

  bool get supportsImageOcr =>
      extension == 'jpg' || extension == 'jpeg' || extension == 'png';

  bool get isMismatch {
    if (expectedCard.isCustom) {
      final expected = expectedCard.title.trim().toLowerCase();
      final detected = suggestedTitle.trim().toLowerCase();
      return detected.isNotEmpty &&
          detected != 'document' &&
          detected != 'other' &&
          detected != expected;
    }
    if (detectedType == DigiDocumentType.other) return false;
    if (expectedCard.type == DigiDocumentType.education) {
      return false;
    }
    return detectedType != expectedCard.type;
  }

  String get mismatchMessage {
    if (!isMismatch) return '';
    if (expectedCard.isCustom) {
      return 'Selected card "${expectedCard.title}" looks like "$suggestedTitle".';
    }
    return 'Selected ${expectedCard.title}, but scan looks like ${digiDocumentTypeLabel(detectedType)}.';
  }
}

class DigiLockerController extends StateNotifier<DigiLockerState> {
  DigiLockerController(this._repository, this._aiOcr)
    : super(const DigiLockerState()) {
    _load();
  }

  final DigiLockerRepository _repository;
  final AiOcrRepository _aiOcr;
  Box<dynamic>? _documentsBox;
  Box<dynamic>? _foldersBox;
  Box<dynamic>? _cardsBox;

  Future<void> _load() async {
    try {
      _documentsBox = await Hive.openBox<dynamic>(_documentsBoxName);
      _foldersBox = await Hive.openBox<dynamic>(_foldersBoxName);
      _cardsBox = await Hive.openBox<dynamic>(_cardsBoxName);
      if ((_foldersBox?.isEmpty ?? true)) {
        await _seedFolders();
      }
      state = state.copyWith(
        documents: _readDocuments(),
        folders: _readFolders(),
        customCards: _readCards(),
        isLoading: false,
      );
      unawaited(_syncFromApi());
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  List<DigiDocument> filteredDocuments({
    required String query,
    required String type,
    required String? folderId,
  }) {
    final cleanQuery = query.trim().toLowerCase();
    final docs = state.documents.where((doc) {
      final matchesType = type == 'All' || doc.typeLabel == type;
      final matchesFolder = folderId == null || doc.folderId == folderId;
      final matchesQuery =
          cleanQuery.isEmpty ||
          doc.title.toLowerCase().contains(cleanQuery) ||
          doc.fileName.toLowerCase().contains(cleanQuery) ||
          doc.typeLabel.toLowerCase().contains(cleanQuery) ||
          doc.issuer.toLowerCase().contains(cleanQuery) ||
          doc.documentNumber.toLowerCase().contains(cleanQuery) ||
          doc.ocrText.toLowerCase().contains(cleanQuery);
      return matchesType && matchesFolder && matchesQuery;
    }).toList();
    docs.sort((a, b) {
      if (a.isFavorite != b.isFavorite) return a.isFavorite ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return docs;
  }

  DigiFolder? folderById(String id) {
    for (final folder in state.folders) {
      if (folder.id == id) return folder;
    }
    return null;
  }

  int documentCountForFolder(String id) {
    return state.documents.where((doc) => doc.folderId == id).length;
  }

  List<DigiDocument> documentsForCard(DigiDocumentCard card) {
    final docs = state.documents.where((doc) {
      if (card.isCustom) {
        return doc.type == DigiDocumentType.other && doc.title == card.title;
      }
      return doc.type == card.type;
    }).toList();
    docs.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return docs;
  }

  Future<List<DigiDocument>> importFiles(
    List<PlatformFile> files,
    String folderId, {
    DigiDocumentType? preferredType,
    String? preferredTitle,
  }) async {
    final documents = <DigiDocument>[];
    for (final file in files) {
      final fallbackCard = DigiDocumentCard(
        id: 'legacy-import',
        title: preferredTitle?.trim().isNotEmpty == true
            ? preferredTitle!.trim()
            : _nameWithoutExtension(file.name),
        subtitle: 'Imported document',
        type: preferredType ?? DigiDocumentType.other,
        icon: Icons.description_rounded,
        colorValue: AppColors.blue.toARGB32(),
      );
      final analysis = await analyzeImportFile(
        file,
        folderId: folderId,
        card: fallbackCard,
      );
      documents.add(await saveAnalyzedImport(analysis));
    }
    return documents;
  }

  Future<DigiImportAnalysis> analyzeImportFile(
    PlatformFile file, {
    required String folderId,
    required DigiDocumentCard card,
  }) async {
    final extension = (file.extension ?? _extension(file.name)).toLowerCase();
    final fileTitle = _nameWithoutExtension(file.name);
    final ocrText = await _extractText(file.path, extension);
    final sourceText = '${card.title} $fileTitle ${file.name} $ocrText';
    final detectedType = digiDocumentTypeFromName(
      '$fileTitle ${file.name} $ocrText',
    );
    final effectiveType = detectedType == DigiDocumentType.other
        ? card.type
        : detectedType;
    return DigiImportAnalysis(
      file: file,
      folderId: folderId,
      expectedCard: card,
      extension: extension,
      fileTitle: fileTitle,
      ocrText: ocrText,
      detectedType: detectedType,
      suggestedTitle: digiDocumentSuggestedTitle(
        '$fileTitle ${file.name} $ocrText',
        fallback: fileTitle,
      ),
      extractedFields: _importantFields(sourceText, effectiveType),
    );
  }

  Future<DigiDocument> saveAnalyzedImport(
    DigiImportAnalysis analysis, {
    String? titleOverride,
    DigiDocumentType? typeOverride,
  }) async {
    final storage =
        await savedStorageTarget(StorageModule.digiLocker) ??
        ModuleStorageTarget.local;
    final now = DateTime.now();
    final type =
        typeOverride ??
        (analysis.detectedType == DigiDocumentType.other
            ? analysis.expectedCard.type
            : analysis.detectedType);
    final title = titleOverride?.trim().isNotEmpty == true
        ? titleOverride!.trim()
        : analysis.expectedCard.isCustom
        ? analysis.expectedCard.title
        : analysis.expectedCard.title;
    final doc = DigiDocument(
      id: '${analysis.file.name}-${now.microsecondsSinceEpoch}',
      title: title,
      fileName: analysis.file.name,
      extension: analysis.extension,
      sizeBytes: analysis.file.size,
      type: type,
      folderId: analysis.folderId,
      filePath: analysis.file.path,
      ocrText: analysis.ocrText.isEmpty
          ? '${analysis.fileTitle} ${digiDocumentTypeLabel(type)}'
          : analysis.ocrText,
      issuer: _issuerFromType(type),
      documentNumber: analysis.extractedFields['Number'] ?? '',
      extractedFields: analysis.extractedFields,
      addedAt: now,
      updatedAt: now,
    );
    await _documentsBox?.put(doc.id, doc.toMap());
    state = state.copyWith(documents: _readDocuments());
    if (storage == ModuleStorageTarget.database) {
      unawaited(_syncDocument(doc));
    }
    return doc;
  }

  Future<DigiDocumentCard?> renameCustomCard(String id, String title) async {
    final card = state.customCards.where((item) => item.id == id).firstOrNull;
    if (card == null) return null;
    final updated = DigiDocumentCard(
      id: card.id,
      title: title,
      subtitle: card.subtitle,
      type: card.type,
      icon: card.icon,
      colorValue: card.colorValue,
      isCustom: card.isCustom,
      createdAt: card.createdAt,
    );
    await _cardsBox?.put(id, updated.toMap());
    state = state.copyWith(customCards: _readCards());
    return updated;
  }

  Future<void> addScannedDocument({
    required String title,
    required String imagePath,
    required String ocrText,
    required String documentType,
  }) async {
    final now = DateTime.now();
    final folderId = state.folders.isEmpty
        ? 'identity'
        : state.folders.first.id;
    final type = digiDocumentTypeFromName('$title $documentType $ocrText');
    final fields = _importantFields('$title $documentType $ocrText', type);
    final doc = DigiDocument(
      id: 'scan-${now.microsecondsSinceEpoch}',
      title: title,
      fileName: '$title.jpg',
      extension: 'jpg',
      sizeBytes: 0,
      type: type,
      folderId: folderId,
      filePath: imagePath,
      ocrText: ocrText,
      issuer: _issuerFromType(type),
      documentNumber: fields['Number'] ?? '',
      extractedFields: fields,
      isVerified: false,
      addedAt: now,
      updatedAt: now,
    );
    await _documentsBox?.put(doc.id, doc.toMap());
    state = state.copyWith(documents: _readDocuments());
    unawaited(_syncDocument(doc));
  }

  Future<DigiDocumentCard> createCustomCard(String title) async {
    final now = DateTime.now();
    final card = DigiDocumentCard(
      id: 'card-${now.microsecondsSinceEpoch}',
      title: title,
      subtitle: 'Custom document',
      type: DigiDocumentType.other,
      icon: Icons.note_add_rounded,
      colorValue: AppColors.cyan.toARGB32(),
      isCustom: true,
      createdAt: now,
    );
    await _cardsBox?.put(card.id, card.toMap());
    state = state.copyWith(customCards: _readCards());
    return card;
  }

  Future<void> createFolder(String name, int colorValue) async {
    final now = DateTime.now();
    final folder = DigiFolder(
      id: 'folder-${now.microsecondsSinceEpoch}',
      name: name,
      colorValue: colorValue,
      createdAt: now,
    );
    await _foldersBox?.put(folder.id, folder.toMap());
    state = state.copyWith(folders: _readFolders());
  }

  Future<void> renameFolder(String id, String name) async {
    final folder = folderById(id);
    if (folder == null) return;
    final updated = folder.copyWith(name: name);
    await _foldersBox?.put(id, updated.toMap());
    state = state.copyWith(folders: _readFolders());
  }

  Future<void> moveDocument(String id, String folderId) async {
    final doc = _documentById(id);
    if (doc == null) return;
    final updated = doc.copyWith(folderId: folderId, updatedAt: DateTime.now());
    await _documentsBox?.put(id, updated.toMap());
    state = state.copyWith(documents: _readDocuments());
    unawaited(_syncDocument(updated));
  }

  Future<void> updateExpiry(String id, DateTime expiryDate) async {
    final doc = _documentById(id);
    if (doc == null) return;
    final updated = doc.copyWith(
      expiryDate: expiryDate,
      updatedAt: DateTime.now(),
    );
    await _documentsBox?.put(id, updated.toMap());
    state = state.copyWith(documents: _readDocuments());
    unawaited(_syncDocument(updated));
  }

  Future<void> updateMetadata({
    required String id,
    required String title,
    required DigiDocumentType type,
    required String issuer,
    required String documentNumber,
    required String ocrText,
    required bool isVerified,
  }) async {
    final doc = _documentById(id);
    if (doc == null) return;
    final updated = doc.copyWith(
      title: title,
      type: type,
      issuer: issuer,
      documentNumber: documentNumber,
      ocrText: ocrText,
      isVerified: isVerified,
      updatedAt: DateTime.now(),
    );
    await _documentsBox?.put(id, updated.toMap());
    state = state.copyWith(documents: _readDocuments());
    unawaited(_syncDocument(updated));
  }

  Future<void> toggleFavorite(String id) async {
    final doc = _documentById(id);
    if (doc == null) return;
    final updated = doc.copyWith(
      isFavorite: !doc.isFavorite,
      updatedAt: DateTime.now(),
    );
    await _documentsBox?.put(id, updated.toMap());
    state = state.copyWith(documents: _readDocuments());
    unawaited(_syncDocument(updated));
  }

  Future<void> deleteDocument(String id) async {
    await _documentsBox?.delete(id);
    state = state.copyWith(documents: _readDocuments());
    unawaited(_deleteRemoteDocument(id));
  }

  Future<void> _syncFromApi() async {
    try {
      final remoteDocuments = await _repository.fetchDocuments();
      for (final remote in remoteDocuments) {
        final local = _documentById(remote.id);
        if (local == null || remote.updatedAt.isAfter(local.updatedAt)) {
          await _documentsBox?.put(remote.id, remote.toMap());
        }
      }
      state = state.copyWith(documents: _readDocuments());
      unawaited(_syncLocalSnapshot());
    } catch (_) {
      // Digi Locker remains local-first when the API is unavailable.
    }
  }

  Future<void> _syncLocalSnapshot() async {
    final documents = List<DigiDocument>.of(state.documents);
    for (final document in documents) {
      await _syncDocument(document);
    }
  }

  Future<void> _syncDocument(DigiDocument document) async {
    try {
      await _repository.syncDocument(document);
    } catch (_) {
      // Local copy is kept; the next load/edit can retry sync.
    }
  }

  Future<void> _deleteRemoteDocument(String id) async {
    try {
      await _repository.deleteDocument(id);
    } catch (_) {}
  }

  DigiDocument? _documentById(String id) {
    for (final doc in state.documents) {
      if (doc.id == id) return doc;
    }
    return null;
  }

  List<DigiDocument> _readDocuments() {
    final box = _documentsBox;
    if (box == null) return const [];
    return box.values
        .whereType<Map>()
        .map(DigiDocument.fromMap)
        .where((doc) => doc.id.isNotEmpty)
        .toList();
  }

  List<DigiFolder> _readFolders() {
    final box = _foldersBox;
    if (box == null) return const [];
    final folders = box.values
        .whereType<Map>()
        .map(DigiFolder.fromMap)
        .where((folder) => folder.id.isNotEmpty)
        .toList();
    folders.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return folders;
  }

  List<DigiDocumentCard> _readCards() {
    final box = _cardsBox;
    if (box == null) return const [];
    final cards = box.values
        .whereType<Map>()
        .map(DigiDocumentCard.fromMap)
        .where((card) => card.id.isNotEmpty && card.title.isNotEmpty)
        .toList();
    cards.sort((a, b) {
      final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return left.compareTo(right);
    });
    return cards;
  }

  Future<String> _extractText(String? path, String extension) async {
    if (path == null || !_isImageExtension(extension)) return '';
    try {
      return (await _aiOcr.extract(path)).rawText.trim();
    } catch (_) {
      return '';
    }
  }

  bool _isImageExtension(String extension) {
    return extension == 'jpg' || extension == 'jpeg' || extension == 'png';
  }

  Future<void> _seedFolders() async {
    final now = DateTime.now();
    final folders = [
      DigiFolder(
        id: 'identity',
        name: 'Identity',
        colorValue: AppColors.blue.toARGB32(),
        createdAt: now,
      ),
      DigiFolder(
        id: 'finance',
        name: 'Finance',
        colorValue: AppColors.purple.toARGB32(),
        createdAt: now.add(const Duration(milliseconds: 1)),
      ),
      DigiFolder(
        id: 'family',
        name: 'Family',
        colorValue: AppColors.success.toARGB32(),
        createdAt: now.add(const Duration(milliseconds: 2)),
      ),
      DigiFolder(
        id: 'property',
        name: 'Property',
        colorValue: AppColors.orange.toARGB32(),
        createdAt: now.add(const Duration(milliseconds: 3)),
      ),
    ];
    for (final folder in folders) {
      await _foldersBox?.put(folder.id, folder.toMap());
    }
  }
}

String _extension(String name) {
  final index = name.lastIndexOf('.');
  if (index == -1 || index == name.length - 1) return '';
  return name.substring(index + 1);
}

String _nameWithoutExtension(String name) {
  final index = name.lastIndexOf('.');
  if (index == -1) return name;
  return name.substring(0, index);
}

String _issuerFromType(DigiDocumentType type) {
  return switch (type) {
    DigiDocumentType.aadhaarPan => 'Government ID',
    DigiDocumentType.aadhaarCard => 'UIDAI',
    DigiDocumentType.panCard => 'Income Tax Department',
    DigiDocumentType.voterId => 'Election Commission',
    DigiDocumentType.passport => 'Passport Office',
    DigiDocumentType.drivingLicence => 'Transport Authority',
    DigiDocumentType.vehicleRc => 'Transport Authority',
    DigiDocumentType.insurance => 'Insurance Provider',
    DigiDocumentType.medical => 'Medical Provider',
    DigiDocumentType.property => 'Property Registry',
    DigiDocumentType.education ||
    DigiDocumentType.class10Marksheet ||
    DigiDocumentType.class12Marksheet => 'Education Board',
    DigiDocumentType.finance => 'Financial Institution',
    DigiDocumentType.other => '',
  };
}

Map<String, String> _importantFields(String text, DigiDocumentType type) {
  final fields = <String, String>{};
  final clean = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  final entities = extractEntities(text);
  for (final entity in entities) {
    switch (entity.type) {
      case OcrEntityType.aadhaar:
      case OcrEntityType.pan:
        fields['Number'] = entity.value;
      case OcrEntityType.date:
        fields.putIfAbsent('DOB / Date', () => entity.value);
      case OcrEntityType.phone:
        fields.putIfAbsent('Phone', () => entity.value);
      case OcrEntityType.email:
        fields.putIfAbsent('Email', () => entity.value);
      case OcrEntityType.amount:
        fields.putIfAbsent('Amount', () => entity.value);
      case OcrEntityType.url:
        fields.putIfAbsent('Website', () => entity.value);
    }
  }

  final nameMatch = RegExp(
    r'(?:name|student name|candidate name)\s*[:\-]?\s*([A-Z][A-Za-z ]{2,40})',
    caseSensitive: false,
  ).firstMatch(clean);
  if (nameMatch != null) {
    fields['Name'] = nameMatch.group(1)!.trim();
  }

  final dobMatch = RegExp(
    r'(?:dob|date of birth|birth)\s*[:\-]?\s*(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})',
    caseSensitive: false,
  ).firstMatch(clean);
  if (dobMatch != null) {
    fields['DOB'] = dobMatch.group(1)!.trim();
  }

  final rollMatch = RegExp(
    r'(?:roll no|roll number|enrolment|registration no)\s*[:\-]?\s*([A-Z0-9/-]{4,24})',
    caseSensitive: false,
  ).firstMatch(clean);
  if (rollMatch != null) {
    fields['Roll / Registration'] = rollMatch.group(1)!.trim();
  }

  final vehicleMatch = RegExp(
    r'\b[A-Z]{2}\s?\d{1,2}\s?[A-Z]{1,3}\s?\d{4}\b',
  ).firstMatch(text.toUpperCase());
  if (vehicleMatch != null && type == DigiDocumentType.vehicleRc) {
    fields['Vehicle Number'] = vehicleMatch.group(0)!.trim();
  }

  return fields;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
