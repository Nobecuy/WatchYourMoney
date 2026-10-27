// Micro-interaction widgets for consistent press feedback and animations.
// Provides scale/opacity effects on tap/long press, maintaining Onyx dark theme.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A button wrapper that adds press feedback (scale + opacity) to any child.
class PressableButton extends StatefulWidget {
  const PressableButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.onLongPress,
    this.scaleFactor = 0.96,
    this.opacityFactor = 0.85,
    this.animationDuration = const Duration(milliseconds: 120),
    this.hapticFeedback = true,
    this.borderRadius,
    this.clipBehavior = Clip.none,
  });

  final Widget child;
  final VoidCallback onPressed;
  final VoidCallback? onLongPress;
  final double scaleFactor;
  final double opacityFactor;
  final Duration animationDuration;
  final bool hapticFeedback;
  final BorderRadius? borderRadius;
  final Clip clipBehavior;

  @override
  State<PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<PressableButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleFactor,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: widget.opacityFactor,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.hapticFeedback) return;
    // Light haptic feedback on press
  }

  void _handleTapUp(TapUpDetails details) {
    _animateRelease();
    widget.onPressed();
  }

  void _handleTapCancel() {
    _animateRelease();
  }

  void _handleLongPress() {
    if (widget.onLongPress != null) {
      _controller.forward();
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _controller.reverse();
      });
      widget.onLongPress!();
    }
  }

  void _animateRelease() {
    if (_controller.isAnimating) return;
    _controller.forward().then((_) => _controller.reverse());
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onLongPress: widget.onLongPress != null ? _handleLongPress : null,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// A card wrapper that adds subtle press feedback (scale).
class PressableCard extends StatefulWidget {
  const PressableCard({
    super.key,
    required this.child,
    this.onPressed,
    this.onLongPress,
    this.scaleFactor = 0.985,
    this.animationDuration = const Duration(milliseconds: 100),
    this.hapticFeedback = false,
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final double scaleFactor;
  final Duration animationDuration;
  final bool hapticFeedback;
  final BorderRadius? borderRadius;

  @override
  State<PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<PressableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleFactor,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onPressed?.call();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  void _handleLongPress() {
    if (widget.onLongPress != null) {
      _controller.forward();
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) _controller.reverse();
      });
      widget.onLongPress!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed != null ? _handleTapDown : null,
      onTapUp: widget.onPressed != null ? _handleTapUp : null,
      onTapCancel: widget.onPressed != null ? _handleTapCancel : null,
      onLongPress: widget.onLongPress != null ? _handleLongPress : null,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// A list item that animates on press with scale.
class PressableListItem extends StatefulWidget {
  const PressableListItem({
    super.key,
    required this.child,
    this.onPressed,
    this.onLongPress,
    this.scaleFactor = 0.99,
    this.animationDuration = const Duration(milliseconds: 80),
    this.padding,
    this.margin,
    this.color,
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final double scaleFactor;
  final Duration animationDuration;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final BorderRadius? borderRadius;

  @override
  State<PressableListItem> createState() => _PressableListItemState();
}

class _PressableListItemState extends State<PressableListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleFactor,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onPressed?.call();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  void _handleLongPress() {
    if (widget.onLongPress != null) {
      _controller.forward();
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _controller.reverse();
      });
      widget.onLongPress!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: widget.onPressed != null ? _handleTapDown : null,
            onTapUp: widget.onPressed != null ? _handleTapUp : null,
            onTapCancel: widget.onPressed != null ? _handleTapCancel : null,
            onLongPress: widget.onLongPress != null ? _handleLongPress : null,
            child: Container(
              padding: widget.padding,
              margin: widget.margin,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: widget.borderRadius,
              ),
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}

/// Mixin for adding press animations to any widget via [AnimatedScale].
mixin PressAnimationMixin<T extends StatefulWidget> on State<T> {
  late AnimationController _pressController;
  late Animation<double> _pressScale;

  void initPressAnimation({
    Duration duration = const Duration(milliseconds: 100),
    double scaleFactor = 0.97,
    TickerProvider? vsync,
  }) {
    _pressController = AnimationController(
      duration: duration,
      vsync: vsync ?? (this as TickerProvider),
    );
    _pressScale = Tween<double>(begin: 1.0, end: scaleFactor).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOutCubic),
    );
  }

  void disposePressAnimation() {
    _pressController.dispose();
  }

  void onPressDown() => _pressController.forward();
  void onPressUp() => _pressController.reverse();
  void onPressCancel() => _pressController.reverse();

  AnimatedBuilder buildPressAnimation({required Widget child}) {
    return AnimatedBuilder(
      animation: _pressController,
      builder: (context, _) => Transform.scale(scale: _pressScale.value, child: child),
    );
  }
}

/// Staggered list animation for ListView/GridView items.
/// Applies fade-in + slide-up with configurable delay per index.
class StaggeredListView extends StatelessWidget {
  const StaggeredListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.scrollDirection = Axis.vertical,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.controller,
    this.staggerDelay = const Duration(milliseconds: 60),
    this.staggerDuration = const Duration(milliseconds: 350),
    this.fadeBegin = 0.0,
    this.fadeEnd = 1.0,
    this.slideBegin = const Offset(0, 0.15),
    this.slideEnd = Offset.zero,
    this.curve = Curves.easeOutCubic,
    this.reverseOnRtl = true,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final Axis scrollDirection;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final ScrollController? controller;
  final Duration staggerDelay;
  final Duration staggerDuration;
  final double fadeBegin;
  final double fadeEnd;
  final Offset slideBegin;
  final Offset slideEnd;
  final Curve curve;
  final bool reverseOnRtl;

  @override
  Widget build(BuildContext context) {
    final isRtl = reverseOnRtl && Directionality.of(context) == TextDirection.rtl;
    final slideX = isRtl ? -slideBegin.dx : slideBegin.dx;

    return ListView.builder(
      controller: controller,
      scrollDirection: scrollDirection,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        final delay = staggerDelay * index;
        return itemBuilder(context, index).animate().fadeIn(
              delay: delay,
              duration: staggerDuration,
              curve: curve,
            ).slide(
              begin: Offset(slideX, slideBegin.dy),
              end: slideEnd,
              delay: delay,
              duration: staggerDuration,
              curve: curve,
            );
      },
    );
  }
}

/// Staggered GridView with consistent entrance animations.
class StaggeredGridView extends StatelessWidget {
  const StaggeredGridView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.gridDelegate,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.staggerDelay = const Duration(milliseconds: 50),
    this.staggerDuration = const Duration(milliseconds: 300),
    this.fadeBegin = 0.0,
    this.fadeEnd = 1.0,
    this.slideBegin = const Offset(0, 0.12),
    this.slideEnd = Offset.zero,
    this.curve = Curves.easeOutCubic,
    this.reverseOnRtl = true,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final SliverGridDelegate gridDelegate;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final Duration staggerDelay;
  final Duration staggerDuration;
  final double fadeBegin;
  final double fadeEnd;
  final Offset slideBegin;
  final Offset slideEnd;
  final Curve curve;
  final bool reverseOnRtl;

  @override
  Widget build(BuildContext context) {
    final isRtl = reverseOnRtl && Directionality.of(context) == TextDirection.rtl;
    final slideX = isRtl ? -slideBegin.dx : slideBegin.dx;

    return GridView.builder(
      gridDelegate: gridDelegate,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        final delay = staggerDelay * index;
        return itemBuilder(context, index).animate().fadeIn(
              delay: delay,
              duration: staggerDuration,
              curve: curve,
            ).slide(
              begin: Offset(slideX, slideBegin.dy),
              end: slideEnd,
              delay: delay,
              duration: staggerDuration,
              curve: curve,
            );
      },
    );
  }
}

/// Extension to easily wrap any widget with press animation.
extension PressAnimation on Widget {
  /// Wraps this widget with press scale/opacity animation.
  Widget pressable({
    required VoidCallback onPressed,
    VoidCallback? onLongPress,
    double scaleFactor = 0.96,
    double opacityFactor = 0.85,
    Duration animationDuration = const Duration(milliseconds: 120),
    bool hapticFeedback = true,
    BorderRadius? borderRadius,
  }) {
    return PressableButton(
      onPressed: onPressed,
      onLongPress: onLongPress,
      scaleFactor: scaleFactor,
      opacityFactor: opacityFactor,
      animationDuration: animationDuration,
      hapticFeedback: hapticFeedback,
      borderRadius: borderRadius,
      child: this,
    );
  }

  /// Wraps this widget with subtle card press animation.
  Widget pressableCard({
    VoidCallback? onPressed,
    VoidCallback? onLongPress,
    double scaleFactor = 0.985,
    Duration animationDuration = const Duration(milliseconds: 100),
    BorderRadius? borderRadius,
  }) {
    return PressableCard(
      onPressed: onPressed,
      onLongPress: onLongPress,
      scaleFactor: scaleFactor,
      animationDuration: animationDuration,
      borderRadius: borderRadius,
      child: this,
    );
  }

  /// Wraps this widget as a pressable list item.
  Widget pressableListItem({
    VoidCallback? onPressed,
    VoidCallback? onLongPress,
    double scaleFactor = 0.99,
    Duration animationDuration = const Duration(milliseconds: 80),
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color? color,
    BorderRadius? borderRadius,
  }) {
    return PressableListItem(
      onPressed: onPressed,
      onLongPress: onLongPress,
      scaleFactor: scaleFactor,
      animationDuration: animationDuration,
      padding: padding,
      margin: margin,
      color: color,
      borderRadius: borderRadius,
      child: this,
    );
  }
}

/// Reusable entry animation widget for fade-in + slide-up entrance.
/// Provides consistent, performant entry animations with configurable delay.
class FadeInSlideUp extends StatelessWidget {
  const FadeInSlideUp({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOutCubic,
    this.slideBegin = const Offset(0, 0.12),
    this.slideEnd = Offset.zero,
    this.fadeBegin = 0.0,
    this.fadeEnd = 1.0,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Curve curve;
  final Offset slideBegin;
  final Offset slideEnd;
  final double fadeBegin;
  final double fadeEnd;

  @override
  Widget build(BuildContext context) {
    return child.animate().fadeIn(
          delay: delay,
          duration: duration,
          curve: curve,
          begin: fadeBegin,
        ).slide(
          begin: slideBegin,
          delay: delay,
          duration: duration,
          curve: curve,
        );
  }
}

/// Staggered entry animation for multiple children.
/// Applies fade-in + slide-up with increasing delay per index.
class StaggeredEntry extends StatelessWidget {
  const StaggeredEntry({
    super.key,
    required this.children,
    this.staggerDelay = const Duration(milliseconds: 60),
    this.duration = const Duration(milliseconds: 350),
    this.curve = Curves.easeOutCubic,
    this.slideBegin = const Offset(0, 0.12),
    this.fadeBegin = 0.0,
    this.axis = Axis.vertical,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
  });

  final List<Widget> children;
  final Duration staggerDelay;
  final Duration duration;
  final Curve curve;
  final Offset slideBegin;
  final double fadeBegin;
  final Axis axis;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;

  @override
  Widget build(BuildContext context) {
    return Flex(
      direction: axis,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;
        final delay = staggerDelay * index;
        return FadeInSlideUp(
          delay: delay,
          duration: duration,
          curve: curve,
          slideBegin: slideBegin,
          fadeBegin: fadeBegin,
          child: child,
        );
      }).toList(),
    );
  }
}

/// Wraps a list of children with staggered entrance animations.
class StaggeredColumn extends StatelessWidget {
  const StaggeredColumn({
    super.key,
    required this.children,
    this.staggerDelay = const Duration(milliseconds: 60),
    this.duration = const Duration(milliseconds: 350),
    this.curve = Curves.easeOutCubic,
    this.slideBegin = const Offset(0, 0.12),
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
  });

  final List<Widget> children;
  final Duration staggerDelay;
  final Duration duration;
  final Curve curve;
  final Offset slideBegin;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;
        final delay = staggerDelay * index;
        return FadeInSlideUp(
          delay: delay,
          duration: duration,
          curve: curve,
          slideBegin: slideBegin,
          child: child,
        );
      }).toList(),
    );
  }
}

/// Wraps a list of children with staggered entrance animations (Row version).
class StaggeredRow extends StatelessWidget {
  const StaggeredRow({
    super.key,
    required this.children,
    this.staggerDelay = const Duration(milliseconds: 60),
    this.duration = const Duration(milliseconds: 350),
    this.curve = Curves.easeOutCubic,
    this.slideBegin = const Offset(0, 0.12),
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
  });

  final List<Widget> children;
  final Duration staggerDelay;
  final Duration duration;
  final Curve curve;
  final Offset slideBegin;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;
        final delay = staggerDelay * index;
        return FadeInSlideUp(
          delay: delay,
          duration: duration,
          curve: curve,
          slideBegin: slideBegin,
          child: child,
        );
      }).toList(),
    );
  }
}