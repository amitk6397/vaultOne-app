import 'response/policy_page_response.dart';

class AppContent {
  const AppContent({
    required this.title,
    required this.subtitle,
    required this.sections,
  });
  final String title;
  final String subtitle;
  final List<PolicySectionResponse> sections;
  factory AppContent.fromJson(Map<String, dynamic> json) => AppContent(
    title: json['title']?.toString() ?? '',
    subtitle: json['subtitle']?.toString() ?? '',
    sections: (json['sections'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map(
          (x) => PolicySectionResponse.fromJson(Map<String, dynamic>.from(x)),
        )
        .toList(),
  );
}

class SupportChatMessage {
  const SupportChatMessage({
    required this.id,
    required this.senderType,
    required this.message,
    required this.createdAt,
  });
  final int id;
  final String senderType;
  final String message;
  final DateTime createdAt;
  bool get fromUser => senderType == 'user';
  factory SupportChatMessage.fromJson(Map<String, dynamic> json) =>
      SupportChatMessage(
        id: (json['id'] as num).toInt(),
        senderType: json['sender_type']?.toString() ?? 'user',
        message: json['message']?.toString() ?? '',
        createdAt:
            DateTime.tryParse(json['created_at']?.toString() ?? '') ??
            DateTime.now(),
      );
}
