import 'dart:convert';

class UserAccount {
  final String id;
  final String fullName;
  final String email;
  final String passwordHash;
  final String bloodType;
  final String? avatarPath;
  final DateTime createdAt;

  const UserAccount({
    required this.id,
    required this.fullName,
    required this.email,
    required this.passwordHash,
    this.bloodType = 'Unknown',
    this.avatarPath,
    required this.createdAt,
  });

  String get firstName {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? 'there' : parts.first;
  }

  UserAccount copyWith({
    String? fullName,
    String? bloodType,
    String? avatarPath,
  }) {
    return UserAccount(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email,
      passwordHash: passwordHash,
      bloodType: bloodType ?? this.bloodType,
      avatarPath: avatarPath ?? this.avatarPath,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        'passwordHash': passwordHash,
        'bloodType': bloodType,
        'avatarPath': avatarPath,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserAccount.fromJson(Map<String, dynamic> json) {
    return UserAccount(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: (json['email'] as String).toLowerCase(),
      passwordHash: json['passwordHash'] as String,
      bloodType: (json['bloodType'] as String?) ?? 'Unknown',
      avatarPath: json['avatarPath'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  static List<UserAccount> listFromJsonString(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => UserAccount.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static String listToJsonString(List<UserAccount> users) {
    return jsonEncode(users.map((u) => u.toJson()).toList());
  }
}
