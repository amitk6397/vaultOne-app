enum PasswordCategory {
  social,
  banking,
  work,
  shopping,
  email,
  entertainment,
  other,
}

class PasswordEntry {
  const PasswordEntry({
    required this.id,
    required this.title,
    required this.username,
    required this.password,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
    this.website = '',
    this.notes = '',
    this.isFavorite = false,
    this.isArchived = false,
  });

  final String id;
  final String title;
  final String username;
  final String password;
  final String website;
  final PasswordCategory category;
  final String notes;
  final bool isFavorite;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get categoryLabel {
    return switch (category) {
      PasswordCategory.social => 'Social',
      PasswordCategory.banking => 'Banking',
      PasswordCategory.work => 'Work',
      PasswordCategory.shopping => 'Shopping',
      PasswordCategory.email => 'Email',
      PasswordCategory.entertainment => 'Entertainment',
      PasswordCategory.other => 'Other',
    };
  }

  int get strengthScore => passwordStrengthScore(password);

  String get strengthLabel {
    return switch (strengthScore) {
      0 || 1 => 'Weak',
      2 => 'Fair',
      3 => 'Good',
      _ => 'Strong',
    };
  }

  bool get isWeak => strengthScore < 3;

  PasswordEntry copyWith({
    String? title,
    String? username,
    String? password,
    String? website,
    PasswordCategory? category,
    String? notes,
    bool? isFavorite,
    bool? isArchived,
    DateTime? updatedAt,
  }) {
    return PasswordEntry(
      id: id,
      title: title ?? this.title,
      username: username ?? this.username,
      password: password ?? this.password,
      website: website ?? this.website,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      isFavorite: isFavorite ?? this.isFavorite,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'username': username,
      'password': password,
      'website': website,
      'category': category.name,
      'notes': notes,
      'isFavorite': isFavorite,
      'isArchived': isArchived,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PasswordEntry.fromMap(Map<dynamic, dynamic> map) {
    final categoryName = map['category']?.toString() ?? 'other';
    return PasswordEntry(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      username: map['username']?.toString() ?? '',
      password: map['password']?.toString() ?? '',
      website: map['website']?.toString() ?? '',
      category: PasswordCategory.values.firstWhere(
        (item) => item.name == categoryName,
        orElse: () => PasswordCategory.other,
      ),
      notes: map['notes']?.toString() ?? '',
      isFavorite: map['isFavorite'] == true,
      isArchived: map['isArchived'] == true,
      createdAt:
          DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(map['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

int passwordStrengthScore(String password) {
  var score = 0;
  if (password.length >= 10) score++;
  if (RegExp('[A-Z]').hasMatch(password)) score++;
  if (RegExp('[0-9]').hasMatch(password)) score++;
  if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) score++;
  return score;
}
