import 'package:flutter/material.dart';

import 'chart_frame.dart';

class StepDots extends StatelessWidget {
  const StepDots({
    super.key,
    required this.count,
    required this.index,
    this.loading = false,
    this.error,
  });

  final int count;
  final int index;
  final bool loading;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return ChartFrame(
      semanticsLabel: 'Step ${index + 1} of $count.',
      loading: loading,
      error: error,
      child: Row(
        children: [
          for (var i = 0; i < count; i++)
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 6,
                margin: EdgeInsets.only(right: i == count - 1 ? 0 : 6),
                decoration: BoxDecoration(
                  color: i <= index ? ChartColors.iris : ChartColors.iris.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class StressScale extends StatelessWidget {
  const StressScale({
    super.key,
    required this.value,
    this.loading = false,
    this.error,
    this.caption,
  });

  /// 0–1, or null when stress was not measured.
  final double? value;
  final bool loading;
  final String? error;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    return ChartFrame(
      semanticsLabel: value == null ? 'No stress reading.' : 'Stress ${(value! * 100).round()} percent. ${caption ?? ''}',
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
                return Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(99),
                        gradient: const LinearGradient(colors: [ChartColors.mint, ChartColors.amber, ChartColors.danger]),
                      ),
                    ),
                    if (value != null)
                      Positioned(
                        left: (value!.clamp(0, 1) * (box.maxWidth - 18)),
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: ChartColors.ink, width: 3),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 6),
            Text(caption!, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: ink.withValues(alpha: 0.75))),
          ],
        ],
      ),
    );
  }
}

class AvatarStack extends StatelessWidget {
  const AvatarStack({
    super.key,
    required this.names,
    this.loading = false,
    this.error,
  });

  final List<String> names;
  final bool loading;
  final String? error;

  @override
  Widget build(BuildContext context) {
    if (!loading && error == null && names.isEmpty) {
      return const ChartFrame(semanticsLabel: 'No family members yet.', child: Text('—'));
    }
    final shown = names.take(5).toList();
    return ChartFrame(
      semanticsLabel: '${names.length} family members.',
      loading: loading,
      error: error,
      child: SizedBox(
        height: 44,
        child: Stack(
          children: [
            for (var i = 0; i < shown.length; i++)
              Positioned(
                left: i * 28,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: ChartColors.iris.withValues(alpha: 0.15 + i * 0.12),
                  child: Text(
                    shown[i].isEmpty ? '?' : shown[i].characters.first.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w800, color: ChartColors.ink),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
