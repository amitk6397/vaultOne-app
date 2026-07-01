import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../constants/app_colors.dart';
import '../models/digi_document.dart';

const _documentsBoxName = 'digi_locker_documents';
const _foldersBoxName = 'digi_locker_folders';

final digiSearchProvider = StateProvider<String>((ref) => '');
final selectedDigiTypeProvider = StateProvider<String>((ref) => 'All');
final selectedDigiFolderProvider = StateProvider<String?>((ref) => null);

final digiLockerProvider =
    StateNotifierProvider<DigiLockerController, DigiLockerState>(
      (ref) => DigiLockerController(),
    );

class DigiLockerState {
  const DigiLockerState({
    this.documents = const [],
    this.folders = const [],
    this.isLoading = true,
    this.error,
  });

  final List<DigiDocument> documents;
  final List<DigiFolder> folders;
  final bool isLoading;
  final String? error;

  int get expiringCount =>
      documents.where((doc) => doc.isExpired || doc.isExpiringSoon).length;

  int get verifiedCount => documents.where((doc) => doc.isVerified).length;

  DigiLockerState copyWith({
    List<DigiDocument>? documents,
    List<DigiFolder>? folders,
    bool? isLoading,
    String? error,
  }) {
    return DigiLockerState(
      documents: documents ?? this.documents,
      folders: folders ?? this.folders,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class DigiLockerController extends StateNotifier<DigiLockerState> {
  DigiLockerController() : super(const DigiLockerState()) {
    _load();
  }

  Box<dynamic>? _documentsBox;
  Box<dynamic>? _foldersBox;

  Future<void> _load() async {
    try {
      _documentsBox = await Hive.openBox<dynamic>(_documentsBoxName);
      _foldersBox = await Hive.openBox<dynamic>(_foldersBoxName);
      if ((_foldersBox?.isEmpty ?? true)) {
        await _seedFolders();
      }
      state = state.copyWith(
        documents: _readDocuments(),
        folders: _readFolders(),
        isLoading: false,
      );
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

  Future<void> importFiles(List<PlatformFile> files, String folderId) async {
    final now = DateTime.now();
    final documents = files.map((file) {
      final extension = (file.extension ?? _extension(file.name)).toLowerCase();
      final title = _nameWithoutExtension(file.name);
      return DigiDocument(
        id: '${file.name}-${now.microsecondsSinceEpoch}',
        title: title,
        fileName: file.name,
        extension: extension,
        sizeBytes: file.size,
        type: digiDocumentTypeFromName(file.name),
        folderId: folderId,
        filePath: file.path,
        ocrText:
            '$title ${digiDocumentTypeLabel(digiDocumentTypeFromName(file.name))}',
        issuer: _issuerFromType(digiDocumentTypeFromName(file.name)),
        documentNumber: '',
        addedAt: now,
        updatedAt: now,
      );
    }).toList();
    for (final doc in documents) {
      await _documentsBox?.put(doc.id, doc.toMap());
    }
    state = state.copyWith(documents: _readDocuments());
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
      documentNumber: '',
      isVerified: false,
      addedAt: now,
      updatedAt: now,
    );
    await _documentsBox?.put(doc.id, doc.toMap());
    state = state.copyWith(documents: _readDocuments());
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
  }

  Future<void> deleteDocument(String id) async {
    await _documentsBox?.delete(id);
    state = state.copyWith(documents: _readDocuments());
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
    DigiDocumentType.passport => 'Passport Office',
    DigiDocumentType.drivingLicence => 'Transport Authority',
    DigiDocumentType.insurance => 'Insurance Provider',
    DigiDocumentType.medical => 'Medical Provider',
    DigiDocumentType.property => 'Property Registry',
    DigiDocumentType.education => 'Education Board',
    DigiDocumentType.finance => 'Financial Institution',
    DigiDocumentType.other => '',
  };
}
