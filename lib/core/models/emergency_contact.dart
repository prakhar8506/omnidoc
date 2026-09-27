class EmergencyContact {
  final String id;
  final String name;
  final String phone;
  final String relation;

  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    this.relation = 'Contact',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'relation': relation,
      };

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      relation: json['relation'] as String? ?? 'Contact',
    );
  }
}
