import 'package:flutter_test/flutter_test.dart';
import 'package:health_companion/features/trainers/trainer_offer.dart';

void main() {
  test('commission is 20 percent of the monthly rate, in whole rupees', () {
    const offer = TrainerOffer(
      id: 'gym-blr',
      name: 'Gym coach',
      city: 'Bengaluru',
      tracks: ['gym'],
      monthlyRateInr: 8000,
      bio: '',
    );
    expect(offer.curaKeepsInr, 1600);
    expect(offer.trainerReceivesInr, 6400);
    expect(offer.curaKeepsInr + offer.trainerReceivesInr, offer.monthlyRateInr);
  });

  test('a trainer is shown when they cover one opted-in track', () {
    final offer = openingTrainerRoster[3];
    expect(offer.covers(const ['diet']), isTrue);
    expect(offer.covers(const ['assist']), isFalse);
  });
}
