class FamilyMember {
  final String id;
  final String name;
  final String relation;
  final String avatarUrl;
  final String accessLevel;
  final String ageAndGender;
  bool shareVitals;
  bool shareLabReports;
  bool sharePrescriptions;
  bool emergencySosEnabled;

  FamilyMember({
    required this.id,
    required this.name,
    required this.relation,
    required this.avatarUrl,
    required this.accessLevel,
    required this.ageAndGender,
    this.shareVitals = true,
    this.shareLabReports = true,
    this.sharePrescriptions = true,
    this.emergencySosEnabled = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'relation': relation,
        'avatarUrl': avatarUrl,
        'accessLevel': accessLevel,
        'ageAndGender': ageAndGender,
        'shareVitals': shareVitals,
        'shareLabReports': shareLabReports,
        'sharePrescriptions': sharePrescriptions,
        'emergencySosEnabled': emergencySosEnabled,
      };

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'] as String,
      name: json['name'] as String,
      relation: json['relation'] as String? ?? 'Family',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      accessLevel: json['accessLevel'] as String? ?? 'Custom Access',
      ageAndGender: json['ageAndGender'] as String? ?? '',
      shareVitals: json['shareVitals'] as bool? ?? true,
      shareLabReports: json['shareLabReports'] as bool? ?? true,
      sharePrescriptions: json['sharePrescriptions'] as bool? ?? true,
      emergencySosEnabled: json['emergencySosEnabled'] as bool? ?? true,
    );
  }
}
