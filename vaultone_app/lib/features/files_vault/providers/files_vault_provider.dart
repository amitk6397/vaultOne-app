import 'dart:io';
import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/storage/module_storage_controller.dart';

import '../models/vault_file.dart';
import '../repositories/files_vault_repository.dart';

const _vaultFilesBoxName = 'files_vault_items';
const _vaultFoldersBoxName = 'files_vault_folders';

final filesVaultGridProvider = StateProvider<bool>((ref) => true);
final filesVaultSearchProvider = StateProvider<String>((ref) => '');
final filesVaultTagProvider = StateProvider<String>((ref) => 'All');
final filesVaultPrivateProvider = StateProvider<bool>((ref) => false);
final filesVaultSortProvider = StateProvider<VaultFileSort>(
  (ref) => VaultFileSort.newest,
);

enum VaultFileSort { newest, oldest, name, sizeLargest }

final filesVaultProvider =
    StateNotifierProvider<FilesVaultController, FilesVaultState>(
      (ref) => FilesVaultController(ref.watch(filesVaultRepositoryProvider)),
    );

class FilesVaultState {
  const FilesVaultState({
    this.files = const [],
    this.isLoading = true,
    this.error,
    this.isUploading = false,
    this.uploadingFileName,
    this.folders = const [],
  });

  final List<VaultFile> files;
  final bool isLoading;
  final String? error;
  final bool isUploading;
  final String? uploadingFileName;
  final List<VaultFolder> folders;

  int get activeCount => files.where((file) => !file.isArchived).length;
  int get publicCount =>
      files.where((file) => !file.isArchived && !file.isPrivate).length;
  int get privateCount =>
      files.where((file) => !file.isArchived && file.isPrivate).length;
  int get encryptedCount => files.where((file) => file.isEncrypted).length;
  int get favoriteCount => files.where((file) => file.isFavorite).length;
  int get totalBytes => files.fold(0, (sum, file) => sum + file.sizeBytes);

  FilesVaultState copyWith({
    List<VaultFile>? files,
    bool? isLoading,
    String? error,
    bool? isUploading,
    String? uploadingFileName,
    List<VaultFolder>? folders,
  }) {
    return FilesVaultState(
      files: files ?? this.files,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isUploading: isUploading ?? this.isUploading,
      uploadingFileName: uploadingFileName ?? this.uploadingFileName,
      folders: folders ?? this.folders,
    );
  }
}

class FilesVaultController extends StateNotifier<FilesVaultState> {
  FilesVaultController(this._repository) : super(const FilesVaultState()) {
    _load();
  }

  final FilesVaultRepository _repository;
  Box<dynamic>? _box;
  Box<dynamic>? _foldersBox;
  Directory? _vaultDirectory;

  Future<void> _load() async {
    try {
      _box = await Hive.openBox<dynamic>(_vaultFilesBoxName);
      _foldersBox = await Hive.openBox<dynamic>(_vaultFoldersBoxName);
      _vaultDirectory = await _ensureVaultDirectory();
      state = state.copyWith(
        files: _readFiles(),
        folders: _readFolders(),
        isLoading: false,
      );
      unawaited(_restoreRemoteFiles());
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  List<VaultFile> filteredFiles({
    required String query,
    required String tag,
    required bool privateOnly,
  }) {
    final cleanQuery = query.trim().toLowerCase();
    final files = state.files.where((file) {
      if (file.isArchived) return false;
      if (privateOnly != file.isPrivate) return false;
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

  Future<VaultFolder?> createFolder(String name) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty ||
        state.folders.any(
          (folder) => folder.name.toLowerCase() == cleanName.toLowerCase(),
        )) {
      return null;
    }
    final folder = VaultFolder(
      id: 'folder-${DateTime.now().microsecondsSinceEpoch}',
      name: cleanName,
      createdAt: DateTime.now(),
    );
    await _foldersBox?.put(folder.id, folder.toMap());
    state = state.copyWith(folders: _readFolders());
    return folder;
  }

  Future<void> moveFilesToFolder(Set<String> ids, String? folderId) async {
    for (final id in ids) {
      final file = fileById(id);
      if (file == null) continue;
      final updated = file.copyWith(
        folderId: folderId,
        clearFolder: folderId == null,
        updatedAt: DateTime.now(),
      );
      await _box?.put(id, updated.toMap());
      unawaited(_repository.updateMetadata(updated));
    }
    state = state.copyWith(files: _readFiles());
  }

  Future<void> copyFilesToFolder(Set<String> ids, String? folderId) async {
    for (final id in ids) {
      final source = fileById(id);
      if (source == null) continue;
      final now = DateTime.now();
      final copiedPath = source.path == null
          ? null
          : await _copyToVaultDirectory(
              sourcePath: source.path,
              fileName: source.name,
            );
      final copy = VaultFile(
        id: '${source.id}-copy-${now.microsecondsSinceEpoch}',
        name: source.name,
        extension: source.extension,
        sizeBytes: source.sizeBytes,
        type: source.type,
        addedAt: now,
        updatedAt: now,
        tags: [...source.tags],
        path: copiedPath ?? source.path,
        isFavorite: source.isFavorite,
        isEncrypted: source.isEncrypted,
        isPrivate: source.isPrivate,
        folderId: folderId,
      );
      await _box?.put(copy.id, copy.toMap());
    }
    state = state.copyWith(files: _readFiles());
  }

  Future<void> importPlatformFiles(List<PlatformFile> files) async {
    final storage =
        await savedStorageTarget(StorageModule.fileVault) ??
        ModuleStorageTarget.local;
    final now = DateTime.now();
    for (final file in files) {
      final extension = (file.extension ?? _extension(file.name)).toLowerCase();
      final type = _typeFromExtension(extension);
      final localPath = await _copyToVaultDirectory(
        sourcePath: file.path,
        fileName: file.name,
      );
      final vaultFile = VaultFile(
        id: '${file.name}-${now.microsecondsSinceEpoch}',
        name: file.name,
        extension: extension,
        sizeBytes: file.size,
        type: type,
        addedAt: now,
        updatedAt: now,
        tags: [_tagFromType(type), extension.toUpperCase()],
        path: localPath ?? file.path,
      );
      await _box?.put(vaultFile.id, vaultFile.toMap());
      if (storage == ModuleStorageTarget.database) {
        unawaited(_syncUpload(vaultFile));
      }
    }
    state = state.copyWith(files: _readFiles());
  }

  Future<void> addImage({
    required String name,
    required String path,
    required int sizeBytes,
  }) async {
    final storage =
        await savedStorageTarget(StorageModule.fileVault) ??
        ModuleStorageTarget.local;
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
      path:
          await _copyToVaultDirectory(sourcePath: path, fileName: name) ?? path,
    );
    await _box?.put(file.id, file.toMap());
    state = state.copyWith(files: _readFiles());
    if (storage == ModuleStorageTarget.database) {
      unawaited(_syncUpload(file));
    }
  }

  Future<void> updateTags(String id, List<String> tags) async {
    final file = fileById(id);
    if (file == null) return;
    final updated = file.copyWith(tags: tags, updatedAt: DateTime.now());
    await _box?.put(id, updated.toMap());
    state = state.copyWith(files: _readFiles());
    unawaited(_repository.updateMetadata(updated));
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
    unawaited(_repository.updateMetadata(updated));
  }

  Future<void> togglePrivate(String id) async {
    final file = fileById(id);
    if (file == null) return;
    final updated = file.copyWith(
      isPrivate: !file.isPrivate,
      updatedAt: DateTime.now(),
    );
    await _box?.put(id, updated.toMap());
    state = state.copyWith(files: _readFiles());
    unawaited(_repository.updateMetadata(updated));
  }

  Future<void> archiveFile(String id) async {
    final file = fileById(id);
    if (file == null) return;
    final updated = file.copyWith(isArchived: true, updatedAt: DateTime.now());
    await _box?.put(id, updated.toMap());
    state = state.copyWith(files: _readFiles());
    unawaited(_repository.updateMetadata(updated));
  }

  Future<void> deleteFile(String id) async {
    final file = fileById(id);
    await _box?.delete(id);
    if (file?.path != null) {
      final localFile = File(file!.path!);
      if (await localFile.exists()) await localFile.delete();
    }
    state = state.copyWith(files: _readFiles());
    if (file != null) unawaited(_repository.deleteRemote(file));
  }

  Future<String?> downloadFile(String id) async {
    final file = fileById(id);
    final path = file?.path;
    if (file == null || path == null || path.isEmpty) return null;
    final source = File(path);
    if (!await source.exists()) return null;
    final bytes = await source.readAsBytes();
    return FilePicker.saveFile(
      dialogTitle: 'Save ${file.name}',
      fileName: file.name,
      bytes: bytes,
    );
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

  List<VaultFolder> _readFolders() {
    final box = _foldersBox;
    if (box == null) return const [];
    final folders = box.values
        .whereType<Map>()
        .map(VaultFolder.fromMap)
        .where((folder) => folder.id.isNotEmpty)
        .toList();
    folders.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return folders;
  }

  Future<void> clearLocalCache() async {
    await _box?.clear();
    await _foldersBox?.clear();
    final directory = _vaultDirectory ?? await _ensureVaultDirectory();
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
    _vaultDirectory = await _ensureVaultDirectory();
    state = state.copyWith(files: const [], folders: const []);
  }

  Future<void> _syncUpload(VaultFile file) async {
    state = state.copyWith(isUploading: true, uploadingFileName: file.name);
    try {
      final synced = await _repository.uploadFile(file);
      await _box?.put(file.id, synced.toMap());
      state = state.copyWith(files: _readFiles());
    } catch (_) {
      await _box?.put(file.id, file.copyWith(isSynced: false).toMap());
    } finally {
      state = state.copyWith(isUploading: false, uploadingFileName: '');
    }
  }

  Future<void> _restoreRemoteFiles() async {
    final directory = _vaultDirectory ?? await _ensureVaultDirectory();
    try {
      final remoteFiles = await _repository.fetchFiles(directory);
      for (final file in remoteFiles) {
        await _box?.put(file.id, file.toMap());
      }
      state = state.copyWith(files: _readFiles());
    } catch (_) {
      // Offline or logged-out users keep the local Hive cache.
    }
  }

  Future<String?> _copyToVaultDirectory({
    required String? sourcePath,
    required String fileName,
  }) async {
    if (sourcePath == null || sourcePath.isEmpty) return null;
    final source = File(sourcePath);
    if (!await source.exists()) return null;
    final directory = _vaultDirectory ?? await _ensureVaultDirectory();
    final safeName = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final targetPath = p.join(
      directory.path,
      '${DateTime.now().microsecondsSinceEpoch}_$safeName',
    );
    return (await source.copy(targetPath)).path;
  }

  Future<Directory> _ensureVaultDirectory() async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(documents.path, 'vaultone_file_vault'));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
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
