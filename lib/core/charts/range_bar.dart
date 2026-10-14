import 'package:flutter/material.dart';

import 'chart_frame.dart';

/// Two numbers from a printed range such as "70-99". Returns null when the report has no interval.
(double, double)? parseReferenceRange(String raw) {
  final nums = RegExp(r'\d+(?:\.\d+)?')
      .allMatches(raw.replaceAll(',', ''))
      .map((match) => double.tryParse(match.group(0)!))
      .whereType<double>()
      .toList();
  if (nums.length < 2 || nums[1] <= nums[0]) return null;
  return (nums[0], nums[1]);
}

double? firstNumber(String raw) {
  final match = RegExp(r'\d+(?:\.\d+)?').firstMatch(raw.replaceAll(',', ''));
  if (match == null) return null;
  return double.tryParse(match.group(0)!);
}

/// Where a reading sits against its reference interval.
/// Below the low end stays in the first zone, inside the interval in the middle, above in the last.
double rangePosition(double value, double low, double high) {
  if (high <= low) return 0.5;
  if (value < low) {
    final floor = low - (high - low);
    final span = low - floor;
    if (span <= 0) return 0.09;
    return (0.18 * ((value - floor) / span)).clamp(0.02, 0.18);
  }
  if (value <= high) {
    return 0.18 + 0.37 * ((value - low) / (high - low));
  }
  final ceiling = high + (high - low);
  final span = ceiling - high;
  if (span <= 0) return 0.78;
  return (0.55 + 0.45 * ((value - high) / span)).clamp(0.55, 0.98);
}

class RangeBar extends StatelessWidget {
  const RangeBar({
    super.key,
    required this.value,
    required this.low,
    required this.high,
    this.loading = false,
    this.error,
    this.caption,
  });

  final double? value;
  final double? low;
  final double? high;
  final bool loading;
  final String? error;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final ready = value != null && low != null && high != null && high! > low!;
    final ink = Theme.of(context).colorScheme.onSurface;
    return ChartFrame(
      semanticsLabel: ready ? '${caption ?? 'Range'} ${value!.toStringAsFixed(1)}' : 'Range is not available.',
      loading: loading,
      error: error,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 22,
            child: LayoutBuilder(
              builder: (context, box) {
                final knob = ready ? rangePosition(value!, low!, high!) * box.maxWidth : null;
                return Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Row(
                      children: [
                        Expanded(flex: 18, child: _zone(const Color(0xFFF6C56B))),
                        const SizedBox(width: 2),
                        Expanded(flex: 37, child: _zone(ChartColors.mint)),
                        const SizedBox(width: 2),
                        Expanded(flex: 45, child: _zone(const Color(0xFFFF8AA8))),
                      ],
                    ),
                    if (knob != null)
                      Positioned(
                        left: (knob - 9).clamp(0, box.maxWidth - 18),
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: ChartColors.ink, width: 4),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 4),
            Text(caption!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: ink.withValues(alpha: 0.7))),
          ],
        ],
      ),
    );
  }

  Widget _zone(Color color) => Container(height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5)));
}
