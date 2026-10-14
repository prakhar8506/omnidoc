import 'package:flutter/material.dart';

import 'chart_frame.dart';

class ZoneBar extends StatelessWidget {
  const ZoneBar({
    super.key,
    required this.active,
    this.labels = const ['1', '2', '3', '4', '5'],
    this.loading = false,
    this.error,
    this.caption,
  });

  /// 0–4, or null when no zone was measured.
  final int? active;
  final List<String> labels;
  final bool loading;
  final String? error;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    return ChartFrame(
      semanticsLabel: active == null ? 'No heart-rate zone.' : 'Zone ${active! + 1} of ${labels.length}.',
      loading: loading,
      error: error,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              for (var i = 0; i < labels.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 18,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active == i ? ChartColors.iris : ChartColors.iris.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      labels[i],
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: active == i ? Colors.white : ink.withValues(alpha: 0.6)),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (caption != null) ...[
            const SizedBox(height: 6),
            Text(caption!, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: ink.withValues(alpha: 0.7))),
          ],
        ],
      ),
    );
  }
}
