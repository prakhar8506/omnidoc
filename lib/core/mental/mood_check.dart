/// A short mood check. It is not a diagnosis of depression.
class MoodQuestion {
  final String prompt;
  final bool safety;

  const MoodQuestion(this.prompt, {this.safety = false});
}

class MoodAnswer {
  final int choice;
  final int millis;

  const MoodAnswer({required this.choice, required this.millis});
}

class MoodCheckResult {
  final int answerScore;
  final int checkScore;
  final String quality;
  final String pace;
  final bool seeDoctor;
  final bool urgent;
  final String summary;

  const MoodCheckResult({
    required this.answerScore,
    required this.checkScore,
    required this.quality,
    required this.pace,
    required this.seeDoctor,
    required this.urgent,
    required this.summary,
  });

  Map<String, dynamic> toJson() => {
        'answerScore': answerScore,
        'checkScore': checkScore,
        'quality': quality,
        'pace': pace,
        'seeDoctor': seeDoctor,
        'urgent': urgent,
        'summary': summary,
        'at': DateTime.now().toIso8601String(),
      };
}

const moodChoices = [
  'Not at all',
  'A few days',
  'More than half the days',
  'Nearly every day',
];

const moodQuestions = <MoodQuestion>[
  MoodQuestion('Over the last two weeks, how often did things you usually enjoy feel flat or uninteresting?'),
  MoodQuestion('How often did you feel low, empty, or without hope?'),
  MoodQuestion('How often was sleep a struggle — hard to fall asleep, waking often, or sleeping far more than usual?'),
  MoodQuestion('How often did your body feel heavy or short on energy?'),
  MoodQuestion('How often was it hard to keep your mind on a conversation, a page, or a simple task?'),
  MoodQuestion('How often did you feel down on yourself, or that you were letting people down?'),
  MoodQuestion('How often did you feel slowed down, or the opposite — restless and unable to sit still?'),
  MoodQuestion(
    'How often did you have thoughts that life was not worth continuing, or of hurting yourself?',
    safety: true,
  ),
];

MoodCheckResult scoreMoodCheck(List<MoodAnswer> answers) {
  final count = moodQuestions.length;
  final used = answers.length >= count ? answers.sublist(0, count) : answers;
  var answerScore = 0;
  var slowBonus = 0;
  var rushed = 0;
  var safetyChoice = 0;
  for (var i = 0; i < used.length; i++) {
    final choice = used[i].choice.clamp(0, 3);
    answerScore += choice;
    if (moodQuestions[i].safety) safetyChoice = choice;
    if (used[i].millis < 1200) rushed++;
    if (used[i].millis >= 25000 && choice >= 1) slowBonus++;
  }
  slowBonus = slowBonus.clamp(0, 3);
  final rushPenalty = rushed >= 4 ? 2 : 0;
  final checkScore = (answerScore + slowBonus - rushPenalty).clamp(0, 27);

  final pace = rushed >= 4
      ? 'Rushed'
      : slowBonus >= 2
          ? 'Slow'
          : 'Steady';

  final quality = checkScore >= 15
      ? 'Low'
      : checkScore >= 10
          ? 'Strained'
          : checkScore >= 5
              ? 'Uneven'
              : 'Steady';

  final urgent = safetyChoice >= 2;
  final seeDoctor = urgent || safetyChoice >= 1 || checkScore >= 10;

  final summary = StringBuffer()
    ..write('Answer score $answerScore of 24. Check score $checkScore after response time. Mood looks $quality. Pace was ${pace.toLowerCase()}.');
  if (pace == 'Rushed') {
    summary.write(' Several answers were under two seconds, so this check is less reliable.');
  } else if (pace == 'Slow') {
    summary.write(' Extra time on harder questions raised the check score slightly.');
  }
  if (urgent) {
    summary.write(' Get in-person help today. If you might hurt yourself, contact local emergency services now.');
  } else if (seeDoctor) {
    summary.write(' A clinician should review this. It is a screening result, not a diagnosis of depression.');
  } else {
    summary.write(' Nothing here requires a visit on its own. This is not a diagnosis.');
  }

  return MoodCheckResult(
    answerScore: answerScore,
    checkScore: checkScore,
    quality: quality,
    pace: pace,
    seeDoctor: seeDoctor,
    urgent: urgent,
    summary: summary.toString(),
  );
}
