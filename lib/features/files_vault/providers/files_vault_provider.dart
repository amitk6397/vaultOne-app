import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/vault_file.dart';

const _vaultFilesBoxName = 'files_vault_items';

final filesVaultGridProvider = StateProvider<bool>((ref) => true);
final filesVaultSearchProvider = StateProvider<String>((ref) => '');
final filesVaultTagProvider = StateProvider<String>((ref) => 'All');
final filesVaultSortProvider = StateProvider<VaultFileSort>(
  (ref) => VaultFileSort.newest,
);

enum VaultFileSort { newest, oldest, name, sizeLargest }

final filesVaultProvider =
    StateNotifierProvider<FilesVaultController, FilesVaultState>(
      (ref) => FilesVaultController(),
    );

class FilesVaultState {
  const FilesVaultState({
    this.files = const [],
    this.isLoading = true,
    this.error,
  });

  final List<VaultFile> files;
  final bool isLoading;
  final String? error;

  int get activeCount => files.where((file) => !file.isArchived).length;
  int get encryptedCount => files.where((file) => file.isEncrypted).length;
  int get favoriteCount => files.where((file) => file.isFavorite).length;
  int get totalBytes => files.fold(0, (sum, file) => sum + file.sizeBytes);

  FilesVaultState copyWith({
    List<VaultFile>? files,
    bool? isLoading,
    String? error,
  }) {
    return FilesVaultState(
      files: files ?? this.files,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class FilesVaultController extends StateNotifier<FilesVaultState> {
  FilesVaultController() : super(const FilesVaultState()) {
    _load();
  }

  Box<dynamic>? _box;

  Future<void> _load() async {
    try {
      _box = await Hive.openBox<dynamic>(_vaultFilesBoxName);
      state = state.copyWith(files: _readFiles(), isLoading: false);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  List<VaultFile> filteredFiles({required String query, required String tag}) {
    final cleanQuery = query.trim().toLowerCase();
    final files = state.files.where((file) {
      if (file.isArchived) return false;
      final matchesTag = tag == 'All' || file.tags.contains(tag);
      final matchesQuery =
          cleanQuery.isEmpty ||
          file.name.toLowerCase().contains(cleanQuery) ||
          file.extension.toLowerCase().contains(cleanQuery) ||
          file.typeLabel.toLowerCase().contains(cleanQuery) ||
          file.tags.any((item) => item.toLowerCase().contains(cleanQuery));
      return matchesTag && matchesQuery;
    }).toList();
    return files;
  }

  List<VaultFile> sortedFiles(List<VaultFile> files, VaultFileSort sort) {
    final items = [...files];
    items.sort((a, b) {
      if (a.isFavorite != b.isFavorite) return a.isFavorite ? -1 : 1;
      return switch (sort) {
        VaultFileSort.newest => b.updatedAt.compareTo(a.updatedAt),
        VaultFileSort.oldest => a.updatedAt.compareTo(b.updatedAt),
        VaultFileSort.name => a.name.toLowerCase().compareTo(
          b.name.toLowerCase(),
        ),
        VaultFileSort.sizeLargest => b.sizeBytes.compareTo(a.sizeBytes),
      };
    });
    return items;
  }

  VaultFile? fileById(String id) {
    for (final file in state.files) {
      if (file.id == id) return file;
    }
    return null;
  }

  Future<void> importPlatformFiles(List<PlatformFile> files) async {
    final now = DateTime.now();
    for (final file in files) {
      final extension = (file.extension ?? _extension(file.name)).toLowerCase();
      final type = _typeFromExtension(extension);
      final vaultFile = VaultFile(
        id: '${file.name}-${now.microsecondsSinceEpoch}',
        name: file.name,
        extension: extension,
        sizeBytes: file.size,
        type: type,
        addedAt: now,
        updatedAt: now,
        tags: [_tagFromType(type), extension.toUpperCase()],
        path: file.path,
      );
      await _box?.put(vaultFile.id, vaultFile.toMap());
    }
    state = state.copyWith(files: _readFiles());
  }

  Future<void> addImage({
    required String name,
    required String path,
    required int sizeBytes,
  }) async {
    final now = DateTime.now();
    final extension = _extension(name).toLowerCase();
    final file = VaultFile(
      id: '$name-${now.microsecondsSinceEpoch}',
      name: name,
      extension: extension,
      sizeBytes: sizeBytes,
      type: VaultFileType.image,
      addedAt: now,
      updatedAt: now,
      tags: const ['Image', 'Camera'],
      path: path,
    );
    await _box?.put(file.id, file.toMap());
    state = state.copyWith(files: _readFiles());
  }

  Future<void> updateTags(String id, List<String> tags) async {
    final file = fileById(id);
    if (file == null) return;
    final updated = file.copyWith(tags: tags, updatedAt: DateTime.now());
    await _box?.put(id, updated.toMap());
    state = state.copyWith(files: _readFiles());
  }

  Future<void> toggleFavorite(String id) async {
    final file = fileById(id);
    if (file == null) return;
    final updated = file.copyWith(
      isFavorite: !file.isFavorite,
      updatedAt: DateTime.now(),
    );
    await _box?.put(id, updated.toMap());
    state = state.copyWith(files: _readFiles());
  }

  Future<void> archiveFile(String id) async {
    final file = fileById(id);
    if (file == null) return;
    final updated = file.copyWith(isArchived: true, updatedAt: DateTime.now());
    await _box?.put(id, updated.toMap());
    state = state.copyWith(files: _readFiles());
  }

  Future<void> deleteFile(String id) async {
    await _box?.delete(id);
    state = state.copyWith(files: _readFiles());
  }

  List<String> tags() {
    final tags =
        state.files
            .where((file) => !file.isArchived)
            .expand((file) => file.tags)
            .toSet()
            .toList()
          ..sort();
    return ['All', ...tags];
  }

  List<VaultFile> _readFiles() {
    final box = _box;
    if (box == null) return const [];
    return box.values
        .whereType<Map>()
        .map(VaultFile.fromMap)
        .where((file) => file.id.isNotEmpty)
        .toList();
  }
}

String _extension(String name) {
  final index = name.lastIndexOf('.');
  if (index == -1 || index == name.length - 1) return '';
  return name.substring(index + 1);
}

VaultFileType _typeFromExtension(String extension) {
  return switch (extension) {
    'pdf' => VaultFileType.pdf,
    'jpg' || 'jpeg' || 'png' => VaultFileType.image,
    'mp4' || 'mov' => VaultFileType.video,
    'zip' || 'rar' || '7z' => VaultFileType.archive,
    'doc' || 'docx' || 'xls' || 'xlsx' => VaultFileType.document,
    'ppt' || 'pptx' => VaultFileType.presentation,
    _ => VaultFileType.other,
  };
}

String _tagFromType(VaultFileType type) {
  return switch (type) {
    VaultFileType.pdf => 'PDF',
    VaultFileType.image => 'Image',
    VaultFileType.video => 'Video',
    VaultFileType.archive => 'Archive',
    VaultFileType.document => 'Document',
    VaultFileType.presentation => 'Presentation',
    VaultFileType.other => 'Other',
  };
}
