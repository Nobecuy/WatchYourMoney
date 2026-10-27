// Page transition helpers for smooth, consistent navigation across the app.
// Uses PageRouteBuilder with FadeTransition + SlideTransition (250-300ms, Curves.easeOutCubic).

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Configuration for page transitions.
class PageTransitionConfig {
  const PageTransitionConfig({
    this.duration = const Duration(milliseconds: 280),
    this.curve = Curves.easeOutCubic,
    this.reverseDuration,
    this.reverseCurve,
    this.slideOffset = const Offset(0.15, 0),
    this.fadeBegin = 0.0,
    this.fadeEnd = 1.0,
  });

  final Duration duration;
  final Curve curve;
  final Duration? reverseDuration;
  final Curve? reverseCurve;
  final Offset slideOffset;
  final double fadeBegin;
  final double fadeEnd;

  /// Default transition for page navigation (push).
  static const PageTransitionConfig push = PageTransitionConfig();

  /// Quick transition for modals/bottom sheets.
  static const PageTransitionConfig modal = PageTransitionConfig(
    duration: Duration(milliseconds: 250),
    curve: Curves.easeOutCubic,
    slideOffset: Offset(0, 0.08),
  );

  /// Snappy transition for bottom navigation tab switches.
  static const PageTransitionConfig tabSwitch = PageTransitionConfig(
    duration: Duration(milliseconds: 200),
    curve: Curves.easeOutCubic,
    slideOffset: Offset(0.08, 0),
  );
}

/// Builds a [PageRouteBuilder] with consistent fade + slide transition.
PageRouteBuilder<T> _buildPageRoute<T>({
  required Widget page,
  required RouteSettings settings,
  PageTransitionConfig config = PageTransitionConfig.push,
  bool fullscreenDialog = false,
}) {
  return PageRouteBuilder<T>(
    settings: settings,
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: config.duration,
    reverseTransitionDuration: config.reverseDuration ?? config.duration,
    opaque: false,
    barrierDismissible: false,
    fullscreenDialog: fullscreenDialog,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: config.curve,
        reverseCurve: config.reverseCurve ?? config.curve.flipped,
      );

      final slideAnimation = Tween<Offset>(
        begin: config.slideOffset,
        end: Offset.zero,
      ).animate(curvedAnimation);

      final fadeAnimation = Tween<double>(
        begin: config.fadeBegin,
        end: config.fadeEnd,
      ).animate(curvedAnimation);

      return FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(
          position: slideAnimation,
          child: child,
        ),
      );
    },
  );
}

/// Pushes a new page with the standard page transition.
Future<T?> _pushPageRoute<T>(BuildContext context, Widget page) {
  return Navigator.of(context).push<T>(
    _buildPageRoute<T>(
      page: page,
      settings: RouteSettings(name: page.runtimeType.toString()),
    ),
  );
}

/// Pushes a new page as a fullscreen dialog with modal transition.
Future<T?> _pushModalPageRoute<T>(BuildContext context, Widget page) {
  return Navigator.of(context).push<T>(
    _buildPageRoute<T>(
      page: page,
      settings: RouteSettings(name: page.runtimeType.toString()),
      config: PageTransitionConfig.modal,
      fullscreenDialog: true,
    ),
  );
}

/// Replaces the current route with a new page (no back stack).
Future<T?> _replacePageRoute<T>(BuildContext context, Widget page) {
  return Navigator.of(context).pushReplacement<T, dynamic>(
    _buildPageRoute<T>(
      page: page,
      settings: RouteSettings(name: page.runtimeType.toString()),
    ),
  );
}

/// Pushes a new page and removes all previous routes.
Future<T?> _pushAndRemoveUntilRoute<T>(BuildContext context, Widget page) {
  return Navigator.of(context).pushAndRemoveUntil<T>(
    _buildPageRoute<T>(
      page: page,
      settings: RouteSettings(name: page.runtimeType.toString()),
    ),
    (route) => false,
  );
}

/// Shows a bottom sheet with custom transition animation.
Future<T?> _showAnimatedBottomSheetRoute<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  Color? backgroundColor,
  double? elevation,
  ShapeBorder? shape,
  Clip clipBehavior = Clip.none,
  Color? barrierColor,
  bool isDismissible = true,
  bool enableDrag = true,
  RouteSettings? routeSettings,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: backgroundColor ?? Colors.transparent,
    elevation: elevation ?? 0,
    shape: shape ??
        const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
    clipBehavior: clipBehavior,
    barrierColor: barrierColor ?? Colors.black.withValues(alpha: 0.65),
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    routeSettings: routeSettings,
    builder: (context) {
      return _AnimatedBottomSheetChild(builder: builder);
    },
  );
}

/// Internal widget that adds entrance animation to bottom sheet content.
class _AnimatedBottomSheetChild extends StatelessWidget {
  const _AnimatedBottomSheetChild({required this.builder});

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return builder(context)
        .animate()
        .fadeIn(duration: 200.ms)
        .slideY(
          begin: 0.15,
          end: 0,
          duration: 280.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

/// Shows a dialog with custom fade + scale transition.
Future<T?> _showAnimatedDialogRoute<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor,
  bool useSafeArea = true,
  RouteSettings? routeSettings,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor ?? Colors.black.withValues(alpha: 0.7),
    barrierLabel: '',
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Extension for convenient navigation with transitions.
extension NavigationTransitions on BuildContext {
  /// Push a page with standard transition.
  Future<T?> pushPage<T>(Widget page) => _pushPageRoute<T>(this, page);

  /// Push a modal page (fullscreen dialog).
  Future<T?> pushModalPage<T>(Widget page) => _pushModalPageRoute<T>(this, page);

  /// Replace current page.
  Future<T?> replacePage<T>(Widget page) => _replacePageRoute<T>(this, page);

  /// Push and clear stack.
  Future<T?> pushAndRemoveUntil<T>(Widget page) =>
      _pushAndRemoveUntilRoute<T>(this, page);

  /// Show animated bottom sheet.
  Future<T?> showAnimatedBottomSheet<T>({
    required WidgetBuilder builder,
    bool isScrollControlled = true,
    Color? backgroundColor,
    double? elevation,
    ShapeBorder? shape,
    Clip clipBehavior = Clip.none,
    Color? barrierColor,
    bool isDismissible = true,
    bool enableDrag = true,
    RouteSettings? routeSettings,
  }) =>
      _showAnimatedBottomSheetRoute<T>(
        context: this,
        builder: builder,
        isScrollControlled: isScrollControlled,
        backgroundColor: backgroundColor,
        elevation: elevation,
        shape: shape,
        clipBehavior: clipBehavior,
        barrierColor: barrierColor,
        isDismissible: isDismissible,
        enableDrag: enableDrag,
        routeSettings: routeSettings,
      );

  /// Show animated dialog.
  Future<T?> showAnimatedDialog<T>({
    required WidgetBuilder builder,
    bool barrierDismissible = true,
    Color? barrierColor,
    bool useSafeArea = true,
    RouteSettings? routeSettings,
  }) =>
      _showAnimatedDialogRoute<T>(
        context: this,
        builder: builder,
        barrierDismissible: barrierDismissible,
        barrierColor: barrierColor,
        useSafeArea: useSafeArea,
        routeSettings: routeSettings,
      );
}