import 'package:flutter/material.dart';
import 'package:watch_your_money/core/theme/app_colors.dart';

/// Neumorphic container mengikuti DESIGN.md §3 — Dual-Light Shadow Model.
///
/// [isPressed] = true  → inset/debossed (input, active state)
/// [isPressed] = false → extruded/raised (standard card)
/// [isElevated]        → floating element style (FAB, modal header)
class NeumorphicContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final bool isPressed;
  final bool isElevated;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final Clip clipBehavior;

  const NeumorphicContainer({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.isPressed = false,
    bool isElevated = false,
    bool isFloating = false,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.backgroundColor,
    this.onTap,
    this.width,
    this.height,
    this.clipBehavior = Clip.none,
  }) : isElevated = isElevated || isFloating;

  List<BoxShadow> get _shadows {
    if (isPressed) {
      // Inset / Sunken — input fields, pressed state
      return const [
        BoxShadow(
          color: AppColors.shadowInsetDark,
          offset: Offset(3, 3),
          blurRadius: 7,
        ),
        BoxShadow(
          color: AppColors.shadowInsetLight,
          offset: Offset(-3, -3),
          blurRadius: 7,
        ),
      ];
    }
    if (isElevated) {
      // Floating element — FAB, pill nav, modals
      return const [
        BoxShadow(
          color: AppColors.shadowLightFloat,
          offset: Offset(-6, -6),
          blurRadius: 14,
        ),
        BoxShadow(
          color: AppColors.shadowDarkFloat,
          offset: Offset(8, 8),
          blurRadius: 20,
        ),
      ];
    }
    // Standard Raised Surface
    return const [
      BoxShadow(
        color: AppColors.shadowLight,
        offset: Offset(-4, -4),
        blurRadius: 10,
      ),
      BoxShadow(
        color: AppColors.shadowDark,
        offset: Offset(5, 5),
        blurRadius: 14,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        width: width,
        height: height,
        margin: margin,
        padding: padding,
        clipBehavior: clipBehavior,
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: const Color(0x0FFFFFFF), // rgba(255,255,255,0.06)
            width: 1,
          ),
          boxShadow: _shadows,
        ),
        child: child,
      ),
    );
  }
}
