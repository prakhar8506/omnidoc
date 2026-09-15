import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Apple Watch-Face-Style Metric Tile
/// Displays vitals with rich radial glow on a dark obsidian surface,
/// centered bold numbers, and minimal labels.
class WatchFaceTile extends StatelessWidget {
  final String title;
  final String value;
  final String? unit;
  final String? subtitle;
  final IconData icon;
  final Color glowColor;
  final VoidCallback? onTap;
  final double? width;
  final double height;
  final Widget? trailingBadge;

  const WatchFaceTile({
    super.key,
    required this.title,
    required this.value,
    this.unit,
    this.subtitle,
    required this.icon,
    required this.glowColor,
    this.onTap,
    this.width,
    this.height = 145,
    this.trailingBadge,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Container(
          width: width,
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.watchFaceDarkBg,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: glowColor.withValues(alpha: 0.28),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: glowColor.withValues(alpha: 0.18),
                blurRadius: 24,
                spreadRadius: -2,
                offset: const Offset(0, 8),
              ),
              const BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.45),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
            gradient: RadialGradient(
              center: const Alignment(0.0, -0.6),
              radius: 1.1,
              colors: [
                glowColor.withValues(alpha: 0.22),
                glowColor.withValues(alpha: 0.05),
                AppColors.watchFaceDarkBg,
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Row: Icon with circular glow pill + Title + Trailing Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: glowColor.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          color: glowColor,
                          size: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        title.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: Colors.white.withValues(alpha: 0.70),
                        ),
                      ),
                    ],
                  ),
                  if (trailingBadge != null) trailingBadge!,
                ],
              ),

              // Center: Bold Watch Number with optional unit
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.0,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: glowColor.withValues(alpha: 0.6),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                    ),
                    if (unit != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        unit!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Bottom: Subtitle / trend indicator
              if (subtitle != null)
                Center(
                  child: Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: glowColor.withValues(alpha: 0.90),
                    ),
                  ),
                )
              else
                const SizedBox(height: 2),
            ],
          ),
        ),
      ),
    );
  }
}
