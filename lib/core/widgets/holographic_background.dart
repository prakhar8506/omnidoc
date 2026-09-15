import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Ambient Pearlescent / Holographic Shifting Background
/// Muted, low-saturation multi-hue gradient (peach → lavender → soft ice cyan → pearl blush)
/// that mimics light diffusing through frosted glass.
class HolographicBackground extends StatefulWidget {
  final Widget child;

  const HolographicBackground({
    super.key,
    required this.child,
  });

  @override
  State<HolographicBackground> createState() => _HolographicBackgroundState();
}

class _HolographicBackgroundState extends State<HolographicBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        final alignTop = Alignment(
          -0.8 + 0.4 * progress,
          -1.0 + 0.2 * progress,
        );
        final alignBottom = Alignment(
          0.8 - 0.4 * progress,
          1.0 - 0.2 * progress,
        );

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: alignTop,
              end: alignBottom,
              colors: const [
                AppColors.holoPeach,
                AppColors.holoLavender,
                AppColors.holoIceCyan,
                AppColors.holoBlush,
                AppColors.surface,
              ],
              stops: const [0.0, 0.28, 0.58, 0.85, 1.0],
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}
