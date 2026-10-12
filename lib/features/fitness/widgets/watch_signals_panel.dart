import 'package:flutter/material.dart';

import '../../../core/state/app_state.dart';
import '../../wearables/services/wearable_service.dart';

/// Shows each watch signal only when the connected tracker actually sent it.
class WatchSignalsPanel extends StatelessWidget {
  const WatchSignalsPanel({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    final muted = ink.withValues(alpha: 0.72);
    final card = Theme.of(context).colorScheme.surface;
    final signals = appState.watchSignals;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'From your watch',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ink),
          ),
          const SizedBox(height: 4),
          Text(
            'Sleep, heart-rate zones, ECG, blood pressure, and the other rows use whatever smartwatch or tracker you connect. If that device does not send a signal, the row stays off.',
            style: TextStyle(fontSize: 13, height: 1.35, color: muted),
          ),
          const SizedBox(height: 12),
          if (signals.isEmpty)
            Text(
              'Sync a watch or fitness tracker. Each feature stays blank until that device shares the reading.',
              style: TextStyle(fontSize: 13, height: 1.35, color: muted),
            )
          else
            for (final signal in signals) _row(signal, ink, muted),
        ],
      ),
    );
  }

  Widget _row(WatchSignal signal, Color ink, Color muted) {
    final color = signal.available ? const Color(0xFF10B981) : muted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            signal.available ? Icons.check_circle_rounded : Icons.info_outline_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(signal.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ink)),
                const SizedBox(height: 2),
                Text(signal.detail, style: TextStyle(fontSize: 12, height: 1.35, color: muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
