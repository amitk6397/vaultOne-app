import 'package:flutter_test/flutter_test.dart';
import 'package:vaultone_app/features/vault_connect/models/connect_models.dart';
import 'package:vaultone_app/features/vault_connect/providers/connect_provider.dart';
import 'package:vaultone_app/features/vault_connect/repositories/connect_repository.dart';
import 'package:vaultone_app/features/vault_connect/services/connect_socket.dart';
import 'package:vaultone_app/features/vault_connect/views/chat_detail_page.dart';
import 'package:vaultone_app/features/vault_connect/views/connect_management_pages.dart';
import 'package:vaultone_app/features/vault_connect/views/contacts_pages.dart';
import 'package:vaultone_app/features/vault_connect/views/vault_connect_home_page.dart';

void main() {
  test('Vault Connect models parse API contracts', () {
    final message = ConnectMessage.fromJson({
      'id': 'message-id',
      'client_message_id': 'client-message-id',
      'conversation_id': 'conversation-id',
      'sender_user_id': 1,
      'message_type': 'text',
      'content': 'hello',
      'created_at': '2026-07-18T00:00:00Z',
      'status': 'SENT',
      'attachments': <Object>[],
    });
    expect(message.id, 'message-id');
    expect(message.status, ConnectMessageStatus.sent);
    expect(VaultConnectSocket.instance.connected, isFalse);
    expect(vaultConnectProvider, isNotNull);
    expect(connectRepositoryProvider, isNotNull);
    expect(VaultConnectHomePage, isNotNull);
    expect(ContactPermissionInfoPage, isNotNull);
    expect(ChatDetailPage, isNotNull);
    expect(AttachmentPreviewPage, isNotNull);
  });
}
