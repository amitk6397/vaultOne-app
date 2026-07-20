import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/legacy.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/password_entry.dart';
import '../models/secure_note.dart';
import '../repositories/password_vault_repository.dart';

const _passwordBoxName = 'password_entries';
const _notesBoxName = 'secure_notes';

final passwordSearchProvider = StateProvider<String>((ref) => '');
final selectedPasswordCategoryProvider = StateProvider<String>((ref) => 'All');
final passwordLengthProvider = StateProvider<double>((ref) => 18);
final includeSymbolsProvider = StateProvider<bool>((ref) => true);
final includeNumbersProvider = StateProvider<bool>((ref) => true);
final includeUppercaseProvider = StateProvider<bool>((ref) => true);

final generatedPasswordProvider = StateProvider<String>((ref) {
  return generatePassword(
    length: ref.watch(passwordLengthProvider).round(),
    includeSymbols: ref.watch(includeSymbolsProvider),
    includeNumbers: ref.watch(includeNumbersProvider),
    includeUppercase: ref.watch(includeUppercaseProvider),
  );
});

final passwordVaultProvider =
    StateNotifierProvider<PasswordVaultController, PasswordVaultState>(
      (ref) =>
          PasswordVaultController(ref.watch(passwordVaultRepositoryProvider)),
    );

class PasswordVaultState {
  const PasswordVaultState({
    this.entries = const [],
    this.notes = const [],
    this.isLoading = true,
    this.error,
  });

  final List<PasswordEntry> entries;
  final List<SecureNote> notes;
  final bool isLoading;
  final String? error;

  int get totalPasswords => entries.where((item) => !item.isArchived).length;
  int get weakPasswords =>
      entries.where((item) => !item.isArchived && item.isWeak).length;
  int get reusedPasswords {
    final counts = <String, int>{};
    for (final entry in entries.where((item) => !item.isArchived)) {
      counts.update(entry.password, (value) => value + 1, ifAbsent: () => 1);
    }
    return counts.values.where((count) => count > 1).length;
  }

  PasswordVaultState copyWith({
    List<PasswordEntry>? entries,
    List<SecureNote>? notes,
    bool? isLoading,
    String? error,
  }) {
    return PasswordVaultState(
      entries: entries ?? this.entries,
      notes: notes ?? this.notes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class PasswordVaultController extends StateNotifier<PasswordVaultState> {
  PasswordVaultController(this._repository)
    : super(const PasswordVaultState()) {
    _load();
  }

  final PasswordVaultRepository _repository;
  Box<dynamic>? _passwordBox;
  Box<dynamic>? _notesBox;

  Future<void> _load() async {
    try {
      _passwordBox = await Hive.openBox<dynamic>(_passwordBoxName);
      _notesBox = await Hive.openBox<dynamic>(_notesBoxName);
      state = state.copyWith(
        entries: _readPasswords(),
        notes: _readNotes(),
        isLoading: false,
      );
      unawaited(_syncFromApi());
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  List<PasswordEntry> filteredEntries({
    required String query,
    required String category,
  }) {
    final cleanQuery = query.trim().toLowerCase();
    final items = state.entries.where((entry) {
      if (entry.isArchived) return false;
      final matchesCategory =
          category == 'All' || entry.categoryLabel == category;
      final matchesSearch =
          cleanQuery.isEmpty ||
          entry.title.toLowerCase().contains(cleanQuery) ||
          entry.username.toLowerCase().contains(cleanQuery) ||
          entry.website.toLowerCase().contains(cleanQuery) ||
          entry.categoryLabel.toLowerCase().contains(cleanQuery);
      return matchesCategory && matchesSearch;
    }).toList();
    items.sort((a, b) {
      if (a.isFavorite != b.isFavorite) return a.isFavorite ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return items;
  }

  PasswordEntry? entryById(String id) {
    for (final entry in state.entries) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  Future<void> saveEntry({
    String? id,
    required String title,
    required String username,
    required String password,
    String website = '',
    required PasswordCategory category,
    String notes = '',
  }) async {
    final now = DateTime.now();
    final existing = id == null ? null : entryById(id);
    final entry = existing == null
        ? PasswordEntry(
            id: now.microsecondsSinceEpoch.toString(),
            title: title,
            username: username,
            password: password,
            website: website,
            category: category,
            notes: notes,
            createdAt: now,
            updatedAt: now,
          )
        : existing.copyWith(
            title: title,
            username: username,
            password: password,
            website: website,
            category: category,
            notes: notes,
            updatedAt: now,
          );
    await _passwordBox?.put(entry.id, entry.toMap());
    state = state.copyWith(entries: _readPasswords());
    unawaited(_syncPassword(entry));
  }

  Future<void> deleteEntry(String id) async {
    await _passwordBox?.delete(id);
    state = state.copyWith(entries: _readPasswords());
    unawaited(_deletePassword(id));
  }

  Future<void> toggleFavorite(String id) async {
    final entry = entryById(id);
    if (entry == null) return;
    final updated = entry.copyWith(
      isFavorite: !entry.isFavorite,
      updatedAt: DateTime.now(),
    );
    await _passwordBox?.put(id, updated.toMap());
    state = state.copyWith(entries: _readPasswords());
    unawaited(_syncPassword(updated));
  }

  Future<void> toggleArchive(String id) async {
    final entry = entryById(id);
    if (entry == null) return;
    final updated = entry.copyWith(
      isArchived: !entry.isArchived,
      updatedAt: DateTime.now(),
    );
    await _passwordBox?.put(id, updated.toMap());
    state = state.copyWith(entries: _readPasswords());
    unawaited(_syncPassword(updated));
  }

  Future<void> saveNote({
    String? id,
    required String title,
    required String body,
  }) async {
    final now = DateTime.now();
    final existing = id == null
        ? null
        : state.notes.where((note) => note.id == id).firstOrNull;
    final note = existing == null
        ? SecureNote(
            id: now.microsecondsSinceEpoch.toString(),
            title: title,
            body: body,
            createdAt: now,
            updatedAt: now,
          )
        : existing.copyWith(title: title, body: body, updatedAt: now);
    await _notesBox?.put(note.id, note.toMap());
    state = state.copyWith(notes: _readNotes());
    unawaited(_syncNote(note));
  }

  Future<void> deleteNote(String id) async {
    await _notesBox?.delete(id);
    state = state.copyWith(notes: _readNotes());
    unawaited(_deleteNote(id));
  }

  Future<void> _syncFromApi() async {
    try {
      final remotePasswords = await _repository.fetchPasswords();
      for (final remote in remotePasswords) {
        final local = entryById(remote.id);
        if (local == null || remote.updatedAt.isAfter(local.updatedAt)) {
          await _passwordBox?.put(remote.id, remote.toMap());
        }
      }

      final remoteNotes = await _repository.fetchNotes();
      for (final remote in remoteNotes) {
        final local = state.notes
            .where((note) => note.id == remote.id)
            .firstOrNull;
        if (local == null || remote.updatedAt.isAfter(local.updatedAt)) {
          await _notesBox?.put(remote.id, remote.toMap());
        }
      }

      state = state.copyWith(entries: _readPasswords(), notes: _readNotes());
      unawaited(_syncLocalSnapshot());
    } catch (_) {
      // Local-first vault should remain usable when the network is unavailable.
    }
  }

  Future<void> _syncLocalSnapshot() async {
    final entries = List<PasswordEntry>.of(state.entries);
    final notes = List<SecureNote>.of(state.notes);
    for (final entry in entries) {
      await _syncPassword(entry);
    }
    for (final note in notes) {
      await _syncNote(note);
    }
  }

  Future<int> syncAllToDatabase() async {
    var synced = 0;
    for (final entry in List<PasswordEntry>.of(state.entries)) {
      await _repository.syncPassword(entry);
      synced++;
    }
    for (final note in List<SecureNote>.of(state.notes)) {
      await _repository.syncNote(note);
      synced++;
    }
    return synced;
  }

  Future<void> clearLocalCache() async {
    await _passwordBox?.clear();
    await _notesBox?.clear();
    state = state.copyWith(entries: const [], notes: const []);
  }

  Future<void> _syncPassword(PasswordEntry entry) async {
    try {
      await _repository.syncPassword(entry);
    } catch (_) {
      // Kept local; next edit/app load can sync again.
    }
  }

  Future<void> _deletePassword(String id) async {
    try {
      await _repository.deletePassword(id);
    } catch (_) {}
  }

  Future<void> _syncNote(SecureNote note) async {
    try {
      await _repository.syncNote(note);
    } catch (_) {}
  }

  Future<void> _deleteNote(String id) async {
    try {
      await _repository.deleteNote(id);
    } catch (_) {}
  }

  List<PasswordEntry> _readPasswords() {
    final box = _passwordBox;
    if (box == null) return const [];
    return box.values
        .whereType<Map>()
        .map(PasswordEntry.fromMap)
        .where((entry) => entry.id.isNotEmpty)
        .toList();
  }

  List<SecureNote> _readNotes() {
    final box = _notesBox;
    if (box == null) return const [];
    final notes = box.values
        .whereType<Map>()
        .map(SecureNote.fromMap)
        .where((note) => note.id.isNotEmpty)
        .toList();
    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return notes;
  }
}

String generatePassword({
  required int length,
  required bool includeSymbols,
  required bool includeNumbers,
  required bool includeUppercase,
}) {
  const lower = 'abcdefghijklmnopqrstuvwxyz';
  const upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  const numbers = '0123456789';
  const symbols = r'!@#$%^&*()-_=+[]{};:,.?';
  final pool = StringBuffer(lower);
  if (includeUppercase) pool.write(upper);
  if (includeNumbers) pool.write(numbers);
  if (includeSymbols) pool.write(symbols);
  final chars = pool.toString();
  final random = Random.secure();
  return List.generate(
    length,
    (_) => chars[random.nextInt(chars.length)],
  ).join();
}

extension _IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
