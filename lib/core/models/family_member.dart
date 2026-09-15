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
}
