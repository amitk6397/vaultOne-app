import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../constants/app_url.dart';
import '../../../data/base_api_service.dart';
import '../../../data/network_api_service.dart';
import '../models/connect_models.dart';

final connectRepositoryProvider = Provider<VaultConnectRepository>((ref) {
  return VaultConnectRepository(
    ref.watch(apiServiceProvider),
    ref.watch(dioProvider),
  );
});

class VaultConnectRepository {
  const VaultConnectRepository(this._api, this._dio);
  final BaseApiService _api;
  final Dio _dio;

  Map<String, dynamic> _data(dynamic response) => Map<String, dynamic>.from(
    response is Map && response['data'] is Map
        ? response['data'] as Map
        : const {},
  );

  Future<List<ConnectUser>> discover(List<String> phones) async {
    final response = await _api.post(
      AppUrl.connectContactsDiscover,
      data: {'phones': phones},
    );
    return (_data(response)['matches'] as List? ?? const [])
        .whereType<Map>()
        .map((x) => ConnectUser.fromJson(Map<String, dynamic>.from(x)))
        .toList();
  }

  Future<ConnectConversation> createDirect(int userId) async {
    final response = await _api.post(
      AppUrl.connectDirectConversation,
      data: {'user_id': userId},
    );
    return ConnectConversation.fromJson(_data(response));
  }

  Future<ConnectConversation> conversation(String id) async {
    final response = await _api.get(AppUrl.connectConversation(id));
    return ConnectConversation.fromJson(_data(response));
  }

  Future<({List<ConnectConversation> items, String? cursor})> conversations({
    String? cursor,
  }) async {
    final response = await _api.get(
      AppUrl.connectConversations,
      queryParameters: {'cursor': ?cursor, 'limit': 30},
    );
    final data = _data(response);
    return (
      items: (data['items'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (x) => ConnectConversation.fromJson(Map<String, dynamic>.from(x)),
          )
          .toList(),
      cursor: data['next_cursor']?.toString(),
    );
  }

  Future<({List<ConnectMessage> items, String? cursor})> messages(
    String conversationId, {
    String? cursor,
  }) async {
    final response = await _api.get(
      AppUrl.connectConversationMessages(conversationId),
      queryParameters: {'cursor': ?cursor, 'limit': 50},
    );
    final data = _data(response);
    return (
      items: (data['items'] as List? ?? const [])
          .whereType<Map>()
          .map((x) => ConnectMessage.fromJson(Map<String, dynamic>.from(x)))
          .toList(),
      cursor: data['next_cursor']?.toString(),
    );
  }

  Future<ConnectMessage> send({
    required String conversationId,
    required String clientMessageId,
    String messageType = 'text',
    String? content,
    List<String> attachmentIds = const [],
  }) async {
    final response = await _api.post(
      AppUrl.connectMessages,
      data: {
        'conversation_id': conversationId,
        'client_message_id': clientMessageId,
        'message_type': messageType,
        'content': content,
        'attachment_ids': attachmentIds,
      },
    );
    return ConnectMessage.fromJson(_data(response));
  }

  Future<void> delivered(String id) async {
    await _api.post(AppUrl.connectMessageDelivered(id));
  }

  Future<void> read(String id) async {
    await _api.post(AppUrl.connectMessageRead(id));
  }

  Future<void> deleteMessage(String id, {required bool everyone}) async {
    await _api.delete(AppUrl.connectDeleteMessage(id, everyone: everyone));
  }

  Future<void> clear(String id) async {
    await _api.delete(AppUrl.connectClearConversation(id));
  }

  Future<void> disappearing(String id, int seconds) async {
    await _api.patch(
      AppUrl.connectDisappearingMessages(id),
      data: {'duration_seconds': seconds},
    );
  }

  Future<void> block(int id) async {
    await _api.post(AppUrl.connectBlockUser(id));
  }

  Future<void> unblock(int id) async {
    await _api.delete(AppUrl.connectBlockUser(id));
  }

  Future<List<Map<String, dynamic>>> blockedUsers() async {
    final response = await _api.get(AppUrl.connectBlockedUsers);
    final value = response is Map ? response['data'] : null;
    return (value as List? ?? const [])
        .whereType<Map>()
        .map((x) => Map<String, dynamic>.from(x))
        .toList();
  }

  Future<void> report({
    required int userId,
    String? conversationId,
    String? messageId,
    String? attachmentId,
    required String category,
    String description = '',
  }) async {
    await _api.post(
      AppUrl.connectReports,
      data: {
        'reported_user_id': userId,
        'conversation_id': conversationId,
        'message_id': messageId,
        'attachment_id': attachmentId,
        'category': category,
        'description': description,
      },
    );
  }

  Future<ConnectAttachment> upload(
    String conversationId,
    File file,
    String kind,
    String mime, {
    void Function(double progress)? onProgress,
  }) async {
    final size = await file.length();
    final checksum = (await sha256.bind(file.openRead()).first).toString();
    final initialized = await _api.post(
      AppUrl.connectInitUpload,
      data: {
        'conversation_id': conversationId,
        'file_name': p.basename(file.path),
        'mime_type': mime,
        'file_size': size,
        'file_type': kind,
        'checksum': checksum,
      },
    );
    final initialData = _data(initialized);
    final id = initialData['id']?.toString() ?? '';
    try {
      final form = FormData.fromMap({
        'upload': await MultipartFile.fromFile(
          file.path,
          filename: p.basename(file.path),
        ),
      });
      await _dio.put(
        AppUrl.connectAttachmentContent(id),
        data: form,
        onSendProgress: (sent, total) =>
            onProgress?.call(total == 0 ? 0 : sent / total),
      );
      final completed = await _api.post(
        AppUrl.connectAttachmentComplete(id),
        data: {'checksum': checksum},
      );
      return ConnectAttachment.fromJson(_data(completed));
    } catch (_) {
      await _api.post(AppUrl.connectAttachmentCancel(id));
      rethrow;
    }
  }

  Future<String> download(
    ConnectAttachment attachment,
    String targetPath, {
    void Function(double progress)? onProgress,
  }) async {
    final response = await _api.get(
      AppUrl.connectAttachmentDownloadUrl(attachment.id),
    );
    final relative = _data(response)['url']?.toString() ?? '';
    final url = AppUrl.resolveResourceUrl(relative);
    await _dio.download(
      url,
      targetPath,
      options: Options(extra: {'skip_auth_refresh': true}),
      onReceiveProgress: (received, total) {
        onProgress?.call(total <= 0 ? 0 : received / total);
      },
    );
    final actual = (await sha256.bind(File(targetPath).openRead()).first)
        .toString();
    if (attachment.checksum != null &&
        actual.toLowerCase() != attachment.checksum!.toLowerCase()) {
      await File(targetPath).delete();
      throw StateError('Downloaded file checksum did not match');
    }
    return targetPath;
  }
}
