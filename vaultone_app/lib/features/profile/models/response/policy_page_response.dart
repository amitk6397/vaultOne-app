class PolicyPageResponse {
  const PolicyPageResponse({
    required this.id,
    required this.policyType,
    required this.title,
    required this.sections,
  });

  final int id;
  final String policyType;
  final String title;
  final List<PolicySectionResponse> sections;

  factory PolicyPageResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map<String, dynamic>) {
      return PolicyPageResponse.fromJson(data);
    }
    if (json.containsKey('data') && data == null) {
      return PolicyPageResponse.empty();
    }
    final rawSections = json['sections'] as List<dynamic>? ?? const [];
    return PolicyPageResponse(
      id: json['id'] as int? ?? 0,
      policyType: json['policy_type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      sections: rawSections
          .map(
            (item) =>
                PolicySectionResponse.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  factory PolicyPageResponse.empty() {
    return const PolicyPageResponse(
      id: 0,
      policyType: '',
      title: 'Policy',
      sections: [],
    );
  }
}

class PolicySectionResponse {
  const PolicySectionResponse({required this.title, required this.body});

  final String title;
  final String body;

  factory PolicySectionResponse.fromJson(Map<String, dynamic> json) {
    return PolicySectionResponse(
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }
}
