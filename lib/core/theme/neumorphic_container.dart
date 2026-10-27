import 'package:flutter/material.dart';
import 'package:watch_your_money/core/theme/app_colors.dart';

/// Neumorphic container mengikuti DESIGN.md §3 — Dual-Light Shadow Model.
///
/// [isPressed] = true  → inset/debossed (input, active state)
/// [isPressed] = false → extruded/raised (standard card)
/// [isElevated]        → floating element style (FAB, modal header)
/// [enablePressAnimation] = true → adds scale/opacity feedback on tap
class NeumorphicContainer extends StatefulWidget {
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
  final bool enablePressAnimation;
  final double pressScaleFactor;
  final double pressOpacityFactor;
  final Duration pressAnimationDuration;

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
    this.enablePressAnimation = false,
    this.pressScaleFactor = 0.98,
    this.pressOpacityFactor = 0.9,
    this.pressAnimationDuration = const Duration(milliseconds: 100),
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
  State<NeumorphicContainer> createState() => _NeumorphicContainerState();
}

class _NeumorphicContainerState extends State<NeumorphicContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _pressScale;
  late Animation<double> _pressOpacity;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: widget.pressAnimationDuration,
      vsync: this,
    );
    _pressScale = Tween<double>(
      begin: 1.0,
      end: widget.pressScaleFactor,
    ).animate(CurvedAnimation(parent: _pressController, curve: Curves.easeOutCubic));
    _pressOpacity = Tween<double>(
      begin: 1.0,
      end: widget.pressOpacityFactor,
    ).animate(CurvedAnimation(parent: _pressController, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null && widget.enablePressAnimation) {
      _pressController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.enablePressAnimation) {
      _pressController.reverse();
    }
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    if (widget.enablePressAnimation) {
      _pressController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget container = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      padding: widget.padding,
      clipBehavior: widget.clipBehavior,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(
          color: const Color(0x0FFFFFFF), // rgba(255,255,255,0.06)
          width: 1,
        ),
        boxShadow: widget._shadows,
      ),
      child: widget.child,
    );

    if (widget.enablePressAnimation && widget.onTap != null) {
      container = GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: AnimatedBuilder(
          animation: _pressController,
          builder: (context, child) {
            return Transform.scale(
              scale: _pressScale.value,
              child: Opacity(
                opacity: _pressOpacity.value,
                child: child,
              ),
            );
          },
          child: container,
        ),
      );
    } else if (widget.onTap != null) {
      container = GestureDetector(
        onTap: widget.onTap,
        child: container,
      );
    }

    return container;
  }
}