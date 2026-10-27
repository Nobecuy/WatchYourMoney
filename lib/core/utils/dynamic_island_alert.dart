import 'package:flutter/material.dart';
import 'package:watch_your_money/core/theme/app_colors.dart';

/// A global overlay-based Dynamic Island style alert system
/// that shows pill-shaped notifications at the top of the screen.

class DynamicIslandAlert {
  static OverlayEntry? _currentEntry;
  static DateTime? _lastShownTime;
  static const Duration _minInterval = Duration(milliseconds: 150);

  /// Shows a Dynamic Island style alert at the top of the screen.
  ///
  /// [context] - BuildContext to find the Overlay
  /// [message] - The message to display
  /// [type] - The type of alert (success, error, warning, info)
  /// [duration] - How long to show the alert (default 3 seconds)
  /// [action] - Optional action button
  static void show({
    required BuildContext context,
    required String message,
    DynamicIslandType type = DynamicIslandType.info,
    Duration duration = const Duration(seconds: 3),
    DynamicIslandAction? action,
  }) {
    // Debounce rapid calls
    final now = DateTime.now();
    if (_lastShownTime != null &&
        now.difference(_lastShownTime!) < _minInterval) {
      return;
    }
    _lastShownTime = now;

    // Remove any existing alert
    _dismiss();

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _DynamicIslandWidget(
        message: message,
        type: type,
        duration: duration,
        action: action,
        onDismiss: () => _dismiss(),
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }

  /// Shows a success alert (green accent)
  static void success({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
    DynamicIslandAction? action,
  }) {
    show(
      context: context,
      message: message,
      type: DynamicIslandType.success,
      duration: duration,
      action: action,
    );
  }

  /// Shows an error alert (red accent)
  static void error({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 4),
    DynamicIslandAction? action,
  }) {
    show(
      context: context,
      message: message,
      type: DynamicIslandType.error,
      duration: duration,
      action: action,
    );
  }

  /// Shows a warning alert (amber accent)
  static void warning({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
    DynamicIslandAction? action,
  }) {
    show(
      context: context,
      message: message,
      type: DynamicIslandType.warning,
      duration: duration,
      action: action,
    );
  }

  /// Shows an info alert (blue accent)
  static void info({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
    DynamicIslandAction? action,
  }) {
    show(
      context: context,
      message: message,
      type: DynamicIslandType.info,
      duration: duration,
      action: action,
    );
  }

  /// Dismisses the current alert if any
  static void _dismiss() {
    _currentEntry?.remove();
    _currentEntry = null;
  }

  /// Dismisses the current alert publicly
  static void dismiss() => _dismiss();
}

/// Type of Dynamic Island alert
enum DynamicIslandType {
  success,
  error,
  warning,
  info,
}

/// Action button for Dynamic Island alert
class DynamicIslandAction {
  final String label;
  final VoidCallback onPressed;
  final Color? textColor;
  final Color? backgroundColor;

  const DynamicIslandAction({
    required this.label,
    required this.onPressed,
    this.textColor,
    this.backgroundColor,
  });
}

class _DynamicIslandWidget extends StatefulWidget {
  final String message;
  final DynamicIslandType type;
  final Duration duration;
  final DynamicIslandAction? action;
  final VoidCallback onDismiss;

  const _DynamicIslandWidget({
    required this.message,
    required this.type,
    required this.duration,
    this.action,
    required this.onDismiss,
  });

  @override
  State<_DynamicIslandWidget> createState() => _DynamicIslandWidgetState();
}

class _DynamicIslandWidgetState extends State<_DynamicIslandWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  Color get _accentColor {
    switch (widget.type) {
      case DynamicIslandType.success:
        return AppColors.positive;
      case DynamicIslandType.error:
        return AppColors.negative;
      case DynamicIslandType.warning:
        return AppColors.goldAccent;
      case DynamicIslandType.info:
        return const Color(0xFF38BDF8);
    }
  }

  Color get _backgroundColor {
    switch (widget.type) {
      case DynamicIslandType.success:
        return const Color(0xFF052e16); // Dark green tint
      case DynamicIslandType.error:
        return const Color(0xFF2e0508); // Dark red tint
      case DynamicIslandType.warning:
        return const Color(0xFF2e1d00); // Dark amber tint
      case DynamicIslandType.info:
        return const Color(0xFF001a2e); // Dark blue tint
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case DynamicIslandType.success:
        return Icons.check_circle_rounded;
      case DynamicIslandType.error:
        return Icons.error_rounded;
      case DynamicIslandType.warning:
        return Icons.warning_amber_rounded;
      case DynamicIslandType.info:
        return Icons.info_rounded;
    }
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward();

    // Auto dismiss after duration
    Future.delayed(widget.duration, () {
      if (mounted) _dismissWithAnimation();
    });
  }

  Future<void> _dismissWithAnimation() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top + 8; // Add small margin from top

    return Positioned(
      top: topPadding,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: _backgroundColor,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: _accentColor.withValues(alpha: 0.3),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      spreadRadius: -4,
                    ),
                    BoxShadow(
                      color: _accentColor.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _icon,
                        color: _accentColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Message
                    Expanded(
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Action button or close
                    if (widget.action != null) ...[
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: () {
                          widget.action!.onPressed();
                          _dismissWithAnimation();
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: widget.action!.backgroundColor ??
                              _accentColor.withValues(alpha: 0.2),
                          foregroundColor: widget.action!.textColor ??
                              _accentColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                            side: BorderSide(
                              color: _accentColor.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          widget.action!.label,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _dismissWithAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.close_rounded,
                            color: AppColors.textMuted,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Convenience extension for BuildContext
extension DynamicIslandAlertExtension on BuildContext {
  void showDynamicIslandSuccess(String message,
      {Duration duration = const Duration(seconds: 3),
      DynamicIslandAction? action}) {
    DynamicIslandAlert.success(
      context: this,
      message: message,
      duration: duration,
      action: action,
    );
  }

  void showDynamicIslandError(String message,
      {Duration duration = const Duration(seconds: 4),
      DynamicIslandAction? action}) {
    DynamicIslandAlert.error(
      context: this,
      message: message,
      duration: duration,
      action: action,
    );
  }

  void showDynamicIslandWarning(String message,
      {Duration duration = const Duration(seconds: 3),
      DynamicIslandAction? action}) {
    DynamicIslandAlert.warning(
      context: this,
      message: message,
      duration: duration,
      action: action,
    );
  }

  void showDynamicIslandInfo(String message,
      {Duration duration = const Duration(seconds: 3),
      DynamicIslandAction? action}) {
    DynamicIslandAlert.info(
      context: this,
      message: message,
      duration: duration,
      action: action,
    );
  }
}