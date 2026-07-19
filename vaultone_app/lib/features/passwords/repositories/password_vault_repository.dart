import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants/app_url.dart';
import '../../../data/base_api_service.dart';
import '../../../data/network_api_service.dart';
import '../models/password_entry.dart';
import '../models/secure_note.dart';

final passwordVaultRepositoryProvider = Provider<PasswordVaultRepository>((
  ref,
) {
  return PasswordVaultRepository(ref.watch(apiServiceProvider));
});

class PasswordVaultRepository {
  const PasswordVaultRepository(this._api);

  final BaseApiService _api;

  Future<List<PasswordEntry>> fetchPasswords() async {
    final response = await _api.get(AppUrl.userPasswords);
    final data = response is Map<String, dynamic> ? response['data'] : null;
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(_passwordFromApi)
        .where((entry) => entry.id.isNotEmpty)
        .toList();
  }

  Future<void> syncPassword(PasswordEntry entry) async {
    await _api.put('${AppUrl.userPasswords}/${entry.id}', data: entry.toMap());
  }

  Future<void> deletePassword(String localId) async {
    await _api.delete('${AppUrl.userPasswords}/$localId');
  }

  Future<List<SecureNote>> fetchNotes() async {
    final response = await _api.get(AppUrl.userSecureNotes);
    final data = response is Map<String, dynamic> ? response['data'] : null;
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(_noteFromApi)
        .where((note) => note.id.isNotEmpty)
        .toList();
  }

  Future<void> syncNote(SecureNote note) async {
    await _api.put('${AppUrl.userSecureNotes}/${note.id}', data: note.toMap());
  }

  Future<void> deleteNote(String localId) async {
    await _api.delete('${AppUrl.userSecureNotes}/$localId');
  }

  PasswordEntry _passwordFromApi(Map<String, dynamic> json) {
    return PasswordEntry.fromMap({
      'id': json['local_id'],
      'title': json['title'],
      'username': json['username'],
      'password': json['password'],
      'website': json['website'],
      'category': json['category'],
      'notes': json['notes'],
      'isFavorite': json['is_favorite'],
      'isArchived': json['is_archived'],
      'createdAt': json['client_created_at'] ?? json['created_at'],
      'updatedAt': json['client_updated_at'] ?? json['updated_at'],
    });
  }

  SecureNote _noteFromApi(Map<String, dynamic> json) {
    return SecureNote.fromMap({
      'id': json['local_id'],
      'title': json['title'],
      'body': json['body'],
      'isPinned': json['is_pinned'],
      'createdAt': json['client_created_at'] ?? json['created_at'],
      'updatedAt': json['client_updated_at'] ?? json['updated_at'],
    });
  }
}
