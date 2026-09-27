import 'package:flutter/material.dart';

/// Body / care domain used to find the right kind of clinic.
enum CareDomain {
  general,
  heart,
  liver,
  hormones,
  skin,
  bones,
  mind,
  women,
  lungs,
  eyes,
  dental,
  child,
}

extension CareDomainX on CareDomain {
  String get label {
    switch (this) {
      case CareDomain.general:
        return 'General';
      case CareDomain.heart:
        return 'Heart';
      case CareDomain.liver:
        return 'Liver';
      case CareDomain.hormones:
        return 'Hormones';
      case CareDomain.skin:
        return 'Skin';
      case CareDomain.bones:
        return 'Bones';
      case CareDomain.mind:
        return 'Mind';
      case CareDomain.women:
        return "Women's";
      case CareDomain.lungs:
        return 'Lungs';
      case CareDomain.eyes:
        return 'Eyes';
      case CareDomain.dental:
        return 'Dental';
      case CareDomain.child:
        return 'Child';
    }
  }

  IconData get icon {
    switch (this) {
      case CareDomain.general:
        return Icons.medical_services_rounded;
      case CareDomain.heart:
        return Icons.favorite_rounded;
      case CareDomain.liver:
        return Icons.water_drop_rounded;
      case CareDomain.hormones:
        return Icons.science_rounded;
      case CareDomain.skin:
        return Icons.face_retouching_natural_rounded;
      case CareDomain.bones:
        return Icons.accessibility_new_rounded;
      case CareDomain.mind:
        return Icons.psychology_rounded;
      case CareDomain.women:
        return Icons.pregnant_woman_rounded;
      case CareDomain.lungs:
        return Icons.air_rounded;
      case CareDomain.eyes:
        return Icons.visibility_rounded;
      case CareDomain.dental:
        return Icons.mood_rounded;
      case CareDomain.child:
        return Icons.child_care_rounded;
    }
  }
}

/// One open window within a day, e.g. 09:00–13:00.
class DayHours {
  final TimeOfDay open;
  final TimeOfDay close;

  const DayHours({required this.open, required this.close});

  int get openMinutes => open.hour * 60 + open.minute;
  int get closeMinutes => close.hour * 60 + close.minute;

  bool contains(TimeOfDay t) {
    final m = t.hour * 60 + t.minute;
    return m >= openMinutes && m < closeMinutes;
  }

  String formatRange() => '${_fmt(open)} – ${_fmt(close)}';

  static String _fmt(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final p = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $p';
  }
}

/// Weekly clinic hours. Missing weekday key = closed that day.
class WeeklyHours {
  /// Keys: DateTime.monday (1) … DateTime.sunday (7)
  final Map<int, List<DayHours>> byWeekday;

  const WeeklyHours(this.byWeekday);

  List<DayHours>? hoursFor(DateTime day) => byWeekday[day.weekday];

  bool isClosedAllDay(DateTime day) {
    final h = hoursFor(day);
    return h == null || h.isEmpty;
  }
}

enum ClinicOpenStatus { open, closed, openingSoon, closingSoon }

class ClinicAvailability {
  final ClinicOpenStatus status;
  final String badgeLabel;
  final String detail;
  final Color badgeColor;

  const ClinicAvailability({
    required this.status,
    required this.badgeLabel,
    required this.detail,
    required this.badgeColor,
  });

  bool get isOpenNow =>
      status == ClinicOpenStatus.open || status == ClinicOpenStatus.closingSoon;
}

/// A bookable clinician / clinic outlet with Google-style open hours.
class ClinicDoctor {
  final String id;
  final String name;
  final String specialty;
  final String clinicName;
  final String address;
  final String avatarUrl;
  final List<CareDomain> domains;
  final WeeklyHours weeklyHours;
  final bool offersVideo;
  final bool acceptsWalkIn;
  final double rating;
  final String nextSlotHint;
  final Color accent;

  const ClinicDoctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.clinicName,
    required this.address,
    required this.avatarUrl,
    required this.domains,
    required this.weeklyHours,
    this.offersVideo = false,
    this.acceptsWalkIn = false,
    this.rating = 4.5,
    this.nextSlotHint = '',
    this.accent = const Color(0xFF6E5DF6),
  });

  ClinicAvailability availabilityAt([DateTime? when]) {
    final now = when ?? DateTime.now();
    final tod = TimeOfDay(hour: now.hour, minute: now.minute);
    final todayMinutes = tod.hour * 60 + tod.minute;
    final hours = weeklyHours.hoursFor(now);

    if (hours == null || hours.isEmpty) {
      final next = _nextOpen(now);
      return ClinicAvailability(
        status: ClinicOpenStatus.closed,
        badgeLabel: 'Closed today',
        detail: next == null
            ? 'No hours listed'
            : 'Opens ${_weekdayName(next.day.weekday)} ${_fmt(next.window.open)}',
        badgeColor: const Color(0xFFB45309),
      );
    }

    for (final window in hours) {
      if (window.contains(tod)) {
        final minsLeft = window.closeMinutes - todayMinutes;
        if (minsLeft <= 60) {
          return ClinicAvailability(
            status: ClinicOpenStatus.closingSoon,
            badgeLabel: 'Closing soon',
            detail: 'Closes ${_fmt(window.close)} · ${window.formatRange()}',
            badgeColor: const Color(0xFFD97706),
          );
        }
        return ClinicAvailability(
          status: ClinicOpenStatus.open,
          badgeLabel: 'Open now',
          detail: 'Closes ${_fmt(window.close)} · ${window.formatRange()}',
          badgeColor: const Color(0xFF0F766E),
        );
      }
    }

    // Before first window or between windows
    for (final window in hours) {
      if (todayMinutes < window.openMinutes) {
        final minsUntil = window.openMinutes - todayMinutes;
        if (minsUntil <= 60) {
          return ClinicAvailability(
            status: ClinicOpenStatus.openingSoon,
            badgeLabel: 'Opening soon',
            detail: 'Opens ${_fmt(window.open)} · ${window.formatRange()}',
            badgeColor: const Color(0xFF2563EB),
          );
        }
        return ClinicAvailability(
          status: ClinicOpenStatus.closed,
          badgeLabel: 'Closed',
          detail: 'Opens ${_fmt(window.open)} · ${window.formatRange()}',
          badgeColor: const Color(0xFFB45309),
        );
      }
    }

    final next = _nextOpen(now);
    return ClinicAvailability(
      status: ClinicOpenStatus.closed,
      badgeLabel: 'Closed',
      detail: next == null
          ? 'Closed for the day'
          : 'Opens ${_weekdayName(next.day.weekday)} ${_fmt(next.window.open)}',
      badgeColor: const Color(0xFFB45309),
    );
  }

  String hoursSummaryFor(DateTime day) {
    final hours = weeklyHours.hoursFor(day);
    if (hours == null || hours.isEmpty) return 'Closed';
    return hours.map((h) => h.formatRange()).join(', ');
  }

  ({DateTime day, DayHours window})? _nextOpen(DateTime from) {
    for (var offset = 0; offset < 8; offset++) {
      final day = DateTime(from.year, from.month, from.day).add(Duration(days: offset));
      final hours = weeklyHours.hoursFor(day);
      if (hours == null || hours.isEmpty) continue;
      if (offset == 0) {
        final nowM = from.hour * 60 + from.minute;
        for (final w in hours) {
          if (w.openMinutes > nowM) return (day: day, window: w);
        }
        continue;
      }
      return (day: day, window: hours.first);
    }
    return null;
  }

  static String _weekdayName(int weekday) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[(weekday - 1).clamp(0, 6)];
  }

  static String _fmt(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final p = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $p';
  }
}
