enum ConnectMessageStatus {
  pending,
  uploading,
  sent,
  delivered,
  read,
  failed,
  deleted,
  expired,
}

class ConnectUser {
  const ConnectUser({
    required this.id,
    required this.fullName,
    required this.phone,
    this.localName,
  });
  final int id;
  final String fullName;
  final String phone;
  final String? localName;
  String get displayName =>
      localName?.trim().isNotEmpty == true ? localName! : fullName;
  factory ConnectUser.fromJson(
    Map<String, dynamic> json, {
    String? localName,
  }) => ConnectUser(
    id: (json['id'] as num?)?.toInt() ?? 0,
    fullName: json['full_name']?.toString() ?? 'VaultOne user',
    phone: json['phone']?.toString() ?? '',
    localName: localName,
  );
}

class ConnectAttachment {
  const ConnectAttachment({
    required this.id,
    required this.fileName,
    required this.mimeType,
    required this.fileSize,
    required this.fileType,
    this.checksum,
    this.uploadStatus = 'complete',
    this.progress = 1,
    this.localPath,
  });
  final String id;
  final String fileName;
  final String mimeType;
  final int fileSize;
  final String fileType;
  final String? checksum;
  final String uploadStatus;
  final double progress;
  final String? localPath;
  factory ConnectAttachment.fromJson(Map<String, dynamic> json) =>
      ConnectAttachment(
        id: json['id']?.toString() ?? '',
        fileName: json['file_name']?.toString() ?? 'Secure file',
        mimeType: json['mime_type']?.toString() ?? 'application/octet-stream',
        fileSize: (json['file_size'] as num?)?.toInt() ?? 0,
        fileType: json['file_type']?.toString() ?? 'document',
        checksum: json['checksum']?.toString(),
        uploadStatus: json['upload_status']?.toString() ?? 'complete',
      );
}

class ConnectMessage {
  const ConnectMessage({
    required this.id,
    required this.clientMessageId,
    required this.conversationId,
    required this.senderUserId,
    required this.messageType,
    required this.createdAt,
    this.content,
    this.replyToMessageId,
    this.attachments = const [],
    this.status = ConnectMessageStatus.sent,
    this.expiresAt,
  });
  final String id;
  final String clientMessageId;
  final String conversationId;
  final int senderUserId;
  final String messageType;
  final String? content;
  final String? replyToMessageId;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final List<ConnectAttachment> attachments;
  final ConnectMessageStatus status;

  ConnectMessage copyWith({
    String? id,
    ConnectMessageStatus? status,
    List<ConnectAttachment>? attachments,
  }) => ConnectMessage(
    id: id ?? this.id,
    clientMessageId: clientMessageId,
    conversationId: conversationId,
    senderUserId: senderUserId,
    messageType: messageType,
    content: content,
    replyToMessageId: replyToMessageId,
    createdAt: createdAt,
    expiresAt: expiresAt,
    attachments: attachments ?? this.attachments,
    status: status ?? this.status,
  );

  factory ConnectMessage.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status']?.toString().toLowerCase() ?? 'sent';
    return ConnectMessage(
      id: json['id']?.toString() ?? '',
      clientMessageId: json['client_message_id']?.toString() ?? '',
      conversationId: json['conversation_id']?.toString() ?? '',
      senderUserId: (json['sender_user_id'] as num?)?.toInt() ?? 0,
      messageType: json['message_type']?.toString() ?? 'text',
      content: json['content']?.toString(),
      replyToMessageId: json['reply_to_message_id']?.toString(),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      expiresAt: DateTime.tryParse(
        json['expires_at']?.toString() ?? '',
      )?.toLocal(),
      attachments: (json['attachments'] as List? ?? const [])
          .whereType<Map>()
          .map((x) => ConnectAttachment.fromJson(Map<String, dynamic>.from(x)))
          .toList(),
      status: ConnectMessageStatus.values.firstWhere(
        (x) => x.name == rawStatus,
        orElse: () => ConnectMessageStatus.sent,
      ),
    );
  }
}

class ConnectConversation {
  const ConnectConversation({
    required this.id,
    required this.participant,
    required this.createdAt,
    this.lastMessage,
    this.lastMessageAt,
    this.disappearingSeconds = 0,
    this.isBlocked = false,
    this.blockedByMe = false,
    this.isMuted = false,
    this.unreadCount = 0,
  });
  final String id;
  final ConnectUser participant;
  final ConnectMessage? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final int disappearingSeconds;
  final bool isBlocked;
  final bool blockedByMe;
  final bool isMuted;
  final int unreadCount;

  ConnectConversation copyWith({bool? isBlocked, bool? blockedByMe}) =>
      ConnectConversation(
        id: id,
        participant: participant,
        createdAt: createdAt,
        lastMessage: lastMessage,
        lastMessageAt: lastMessageAt,
        disappearingSeconds: disappearingSeconds,
        isBlocked: isBlocked ?? this.isBlocked,
        blockedByMe: blockedByMe ?? this.blockedByMe,
        isMuted: isMuted,
        unreadCount: unreadCount,
      );

  factory ConnectConversation.fromJson(Map<String, dynamic> json) =>
      ConnectConversation(
        id: json['id']?.toString() ?? '',
        participant: ConnectUser.fromJson(
          Map<String, dynamic>.from(json['participant'] as Map? ?? const {}),
        ),
        lastMessage: json['last_message'] is Map
            ? ConnectMessage.fromJson(
                Map<String, dynamic>.from(json['last_message'] as Map),
              )
            : null,
        lastMessageAt: DateTime.tryParse(
          json['last_message_at']?.toString() ?? '',
        )?.toLocal(),
        createdAt:
            DateTime.tryParse(
              json['created_at']?.toString() ?? '',
            )?.toLocal() ??
            DateTime.now(),
        disappearingSeconds:
            (json['disappearing_duration_seconds'] as num?)?.toInt() ?? 0,
        isBlocked: json['is_blocked'] == true,
        blockedByMe: json['blocked_by_me'] == true,
        isMuted: json['is_muted'] == true,
        unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      );
}
