/// A collaborated human coach. Not a doctor and not the in-app AI.
class TrainerOffer {
  const TrainerOffer({
    required this.id,
    required this.name,
    required this.city,
    required this.tracks,
    required this.monthlyRateInr,
    required this.bio,
  });

  final String id;
  final String name;
  final String city;
  final List<String> tracks;
  final int monthlyRateInr;
  final String bio;

  /// Share of the monthly rate that stays with Cura.
  static const int commissionPercent = 20;

  int get curaKeepsInr => (monthlyRateInr * commissionPercent) ~/ 100;

  int get trainerReceivesInr => monthlyRateInr - curaKeepsInr;

  bool covers(Iterable<String> wanted) {
    if (wanted.isEmpty) return true;
    return tracks.any(wanted.contains);
  }

  factory TrainerOffer.fromJson(Map<String, dynamic> json) {
    final rawTracks = json['tracks'];
    return TrainerOffer(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? json['display_name'] ?? 'Trainer').toString(),
      city: (json['city'] ?? '').toString(),
      tracks: rawTracks is List ? rawTracks.map((e) => e.toString()).toList() : const [],
      monthlyRateInr: (json['monthly_rate_inr'] as num?)?.toInt() ?? 0,
      bio: (json['bio'] ?? '').toString(),
    );
  }
}

/// Opening roster used when the trainer desk is offline.
/// The cloud function is the source of truth once it is deployed.
const List<TrainerOffer> openingTrainerRoster = [
  TrainerOffer(
    id: 'gym-blr',
    name: 'Gym coach, Bengaluru',
    city: 'Bengaluru',
    tracks: ['gym'],
    monthlyRateInr: 8000,
    bio: 'Strength sessions and a weekly plan you can do in a gym. Not medical care.',
  ),
  TrainerOffer(
    id: 'diet-bom',
    name: 'Meal coach, Mumbai',
    city: 'Mumbai',
    tracks: ['diet'],
    monthlyRateInr: 6000,
    bio: 'A practical meal plan from what you already eat. Not a diagnosis and not a prescription.',
  ),
  TrainerOffer(
    id: 'habit-del',
    name: 'Habit assistant, Delhi',
    city: 'Delhi',
    tracks: ['assist'],
    monthlyRateInr: 5000,
    bio: 'Check-ins for training days, meals, and sleep. Day-to-day help, not clinical treatment.',
  ),
  TrainerOffer(
    id: 'both-hyd',
    name: 'Strength and meals, Hyderabad',
    city: 'Hyderabad',
    tracks: ['gym', 'diet'],
    monthlyRateInr: 10000,
    bio: 'Gym sessions plus a meal plan. The coach does not replace your doctor.',
  ),
];

String rupees(int amount) {
  final digits = amount.abs().toString();
  final buf = StringBuffer(amount < 0 ? '-' : '');
  buf.write('₹');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return buf.toString();
}

String trackLabel(String id) {
  switch (id) {
    case 'gym':
      return 'Gym';
    case 'diet':
      return 'Diet';
    case 'assist':
      return 'Personal assistance';
    default:
      return id;
  }
}
