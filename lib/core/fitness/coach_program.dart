import 'fitness_goal.dart';

class CoachSession {
  const CoachSession({required this.title, required this.detail});

  final String title;
  final String detail;
}

class CoachProgram {
  const CoachProgram({
    required this.headline,
    required this.phase,
    required this.guardrails,
    required this.sessions,
  });

  final String headline;
  final String phase;
  final List<String> guardrails;
  final List<CoachSession> sessions;
}

int coachWeekNumber(String? startedIso, DateTime now) {
  final start = DateTime.tryParse(startedIso ?? '');
  if (start == null) return 1;
  final days = DateTime(now.year, now.month, now.day)
      .difference(DateTime(start.year, start.month, start.day))
      .inDays;
  if (days < 0) return 1;
  return (days ~/ 7) + 1;
}

int? weeksUntilRace(String? raceIso, DateTime now) {
  final race = DateTime.tryParse(raceIso ?? '');
  if (race == null) return null;
  final days = DateTime(race.year, race.month, race.day)
      .difference(DateTime(now.year, now.month, now.day))
      .inDays;
  return (days / 7).ceil();
}

String racePhase(int? weeks) {
  if (weeks == null) return 'Base';
  if (weeks < 0) return 'After the date you saved';
  if (weeks <= 2) return 'Taper';
  if (weeks <= 8) return 'Specific';
  if (weeks <= 16) return 'Build';
  return 'Base';
}

CoachProgram buildCoachProgram({
  required String aim,
  required String event,
  required String? raceDateIso,
  required String? startedIso,
  required int weeklyHours,
  required String? readiness,
  required bool gentle,
  required bool bloodPressureMedicine,
  required bool hasHeartRateZones,
  required bool hasBodySize,
  required bool hasSleep,
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();
  final week = coachWeekNumber(startedIso, clock);
  final until = weeksUntilRace(raceDateIso, clock);
  final phase = FitnessAim.raceAims.contains(aim) ? racePhase(until) : 'Training';
  final hours = weeklyHours.clamp(2, 14);
  final taper = phase == 'Taper';
  final minutes = ((taper ? hours * 0.6 : hours) * 60).round();
  final eventLabel = FitnessAim.eventLabel(aim, event);
  final aimLabel = FitnessAim.labelFor(aim);

  final guardrails = <String>[
    'Week $week. This is a training outline, not medical clearance and not a promise of a result.',
    if (gentle)
      'Hard efforts are left out because recovery or a GLP-1 note on file calls for an easy day.',
    if (bloodPressureMedicine)
      'Blood-pressure medicine is on file. No breath-holding and no all-out efforts. Stop if you feel dizzy.',
    if ((readiness ?? '').trim().isEmpty)
      'No recovery score is on file, so this week is not adjusted for recovery.',
    if (!hasSleep) 'No sleep length is on file, so this week is not adjusted for sleep.',
    if (!hasHeartRateZones)
      'Heart-rate zones stay off until a date of birth and a measured resting heart rate are both saved.',
    if (!hasBodySize)
      'A calorie goal stays off until height, weight, sex, and date of birth are all saved. Meals you log are still kept.',
    if (taper) 'The race date is close, so this week is shorter. Keep what you do easy.',
    if (phase == 'After the date you saved')
      'The date you saved is in the past. Pick a new date when you have one.',
  ];

  final sessions = switch (aim) {
    'ironman' => _ironman(minutes, gentle, eventLabel),
    'hyrox' => _hyrox(minutes, gentle, eventLabel),
    'running' => _running(minutes, gentle, eventLabel),
    _ => _body(minutes, gentle, aim),
  };

  final when = until == null
      ? 'No race date saved.'
      : until < 0
          ? 'The saved date has passed.'
          : '$until week${until == 1 ? '' : 's'} until the date you saved.';

  return CoachProgram(
    headline: eventLabel.isEmpty ? aimLabel : '$aimLabel · $eventLabel',
    phase: FitnessAim.raceAims.contains(aim) ? '$phase. $when' : phase,
    guardrails: guardrails,
    sessions: sessions,
  );
}

int _part(int minutes, double share) => (minutes * share).round().clamp(15, 240);

List<CoachSession> _ironman(int minutes, bool gentle, String event) {
  final effort = gentle ? 'Easy enough to talk the whole time.' : 'Steady. You should still be able to speak a sentence.';
  return [
    CoachSession(
      title: 'Swim · ${_part(minutes, 0.18)} min',
      detail: 'Easy swimming and a few lengths focused on breathing. ${event.isEmpty ? 'Choose 70.3 or full so the race distance is named.' : event} $effort',
    ),
    CoachSession(
      title: 'Bike · ${_part(minutes, 0.42)} min',
      detail: 'Continuous riding. $effort No power target is shown because no power meter reading is on file.',
    ),
    CoachSession(
      title: 'Run · ${_part(minutes, 0.25)} min',
      detail: 'Easy running or a brisk walk if running is not available. $effort No pace is shown because no run pace is on file.',
    ),
    if (!gentle && minutes >= 300)
      CoachSession(
        title: 'Brick · ${_part(minutes, 0.15)} min',
        detail: 'A short ride and then a short run, so the legs change from one to the other. Keep the run easier than the ride felt.',
      )
    else
      CoachSession(
        title: 'Strength · ${_part(minutes, 0.15)} min',
        detail: 'A squat, a hip hinge, and a carry. Stop a set while you could still do two more. ${gentle ? 'Keep the load light.' : ''}',
      ),
  ];
}

List<CoachSession> _hyrox(int minutes, bool gentle, String event) {
  const stations =
      'The race order is SkiErg, sled push, sled pull, burpee broad jumps, rowing, farmers carry, sandbag lunges, then wall balls, each after a 1 km run. Station weights depend on the division. This plan does not assign a weight.';
  return [
    CoachSession(
      title: 'Easy run · ${_part(minutes, 0.30)} min',
      detail: 'Comfortable running. ${event.isEmpty ? '' : '$event. '}No finish time is estimated.',
    ),
    CoachSession(
      title: 'Stations · ${_part(minutes, 0.35)} min',
      detail: stations,
    ),
    CoachSession(
      title: gentle ? 'Easy repeat · ${_part(minutes, 0.20)} min' : 'Compromised run · ${_part(minutes, 0.20)} min',
      detail: gentle
          ? 'Another easy run or walk. Hard station work waits for a day that is not marked for rest.'
          : 'Short runs with a station you can set up between them. Skip any station you do not have equipment for.',
    ),
    CoachSession(
      title: 'Strength · ${_part(minutes, 0.15)} min',
      detail: 'Lunges, a carry, and a squat. Leave a couple of repeats in reserve.',
    ),
  ];
}

List<CoachSession> _running(int minutes, bool gentle, String event) {
  final named = event.isEmpty ? 'Pick a distance so the week has a race in mind.' : event;
  final faster = !gentle && minutes >= 240;
  return [
    CoachSession(
      title: 'Easy run · ${_part(minutes, faster ? 0.22 : 0.30)} min',
      detail: '$named. Easy enough to talk. No pace is assigned.',
    ),
    CoachSession(
      title: 'Easy run · ${_part(minutes, faster ? 0.22 : 0.30)} min',
      detail: 'Same easy effort. Walk breaks are part of the session if you need them.',
    ),
    CoachSession(
      title: 'Longer run · ${_part(minutes, 0.36)} min',
      detail: 'The longest session of this week, still easy. Make it longer next week only if this one felt repeatable.',
    ),
    CoachSession(
      title: faster ? 'Strides · ${_part(minutes, 0.20)} min' : 'Extra easy · ${_part(minutes, 0.20)} min',
      detail: faster
          ? 'Mostly easy running, with 4 short faster efforts of about 20 seconds and full rest between them.'
          : 'Keep this easy. Faster work is left out on a short week or a rest-marked day.',
    ),
  ];
}

List<CoachSession> _body(int minutes, bool gentle, String aim) {
  final focus = switch (aim) {
    'lose' => 'The walk matters as much as the lifting. No step goal is invented if the watch did not send steps.',
    'gain' => 'Add a repeat only when last time felt repeatable. Do not jump the load from a formula.',
    'recomp' => 'Lift, and keep the easy walk. Fat loss and muscle gain together are slow, and this outline does not predict either.',
    _ => 'Keep the same sessions most weeks. Change the load only when the last session felt repeatable.',
  };
  final lift = gentle ? 'Light load. Stop well before failure.' : 'Stop each set with about two repeats left.';
  return [
    CoachSession(title: 'Lift · ${_part(minutes, 0.30)} min', detail: 'Squat and a push. $lift'),
    CoachSession(title: 'Lift · ${_part(minutes, 0.30)} min', detail: 'Hip hinge and a carry. $lift'),
    CoachSession(title: 'Lift · ${_part(minutes, 0.20)} min', detail: 'A short mix of the same patterns. $lift'),
    CoachSession(
      title: 'Walk · ${_part(minutes, 0.20)} min',
      detail: focus,
    ),
  ];
}
