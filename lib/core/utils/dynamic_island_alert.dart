import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

enum DynamicIslandType { success, error, warning, info }

enum _IslandStage { expanded, compact, idle }

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

class DynamicIslandAlert {
  static OverlayEntry? _entry;
  static DateTime? _lastShown;
  static const _minInterval = Duration(milliseconds: 150);

  static void show({
    required BuildContext context,
    required String message,
    DynamicIslandType type = DynamicIslandType.info,
    Duration duration = const Duration(seconds: 3),
    DynamicIslandAction? action,
    String? title,
    String? detail,
    bool mini = false,
  }) {
    final now = DateTime.now();

    if (_lastShown != null && now.difference(_lastShown!) < _minInterval) {
      return;
    }

    _lastShown = now;
    dismiss();

    final overlay = Overlay.of(context);

    late final OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _DynamicIslandOverlay(
        message: message,
        type: type,
        duration: duration,
        action: action,
        title: title,
        detail: detail,
        mini: mini,
        onRemove: () {
          if (identical(_entry, entry)) {
            _entry = null;
            entry.remove();
          }
        },
      ),
    );

    _entry = entry;
    overlay.insert(entry);
  }

  static void success({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
    DynamicIslandAction? action,
    String? title,
    String? detail,
  }) {
    show(
      context: context,
      message: message,
      type: DynamicIslandType.success,
      duration: duration,
      action: action,
      title: title ?? 'Ledger Confirmed',
      detail: detail,
    );
  }

  static void error({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 4),
    DynamicIslandAction? action,
    String? title,
    String? detail,
  }) {
    show(
      context: context,
      message: message,
      type: DynamicIslandType.error,
      duration: duration,
      action: action,
      title: title ?? 'Vault Rejected',
      detail: detail ?? 'Cek apakah ada yang terlewat',
    );
  }

  static void warning({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
    DynamicIslandAction? action,
    String? title,
    String? detail,
  }) {
    show(
      context: context,
      message: message,
      type: DynamicIslandType.warning,
      duration: duration,
      action: action,
      title: title ?? 'Perhatian',
      detail: detail,
    );
  }

  static void info({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
    DynamicIslandAction? action,
    String? title,
    String? detail,
  }) {
    show(
      context: context,
      message: message,
      type: DynamicIslandType.info,
      duration: duration,
      action: action,
      title: title ?? 'Informasi',
      detail: detail,
    );
  }

  static void miniSuccess({
    required BuildContext context,
    String message = 'Transaksi berhasil',
    Duration duration = const Duration(seconds: 2),
  }) {
    show(
      context: context,
      message: message,
      type: DynamicIslandType.success,
      duration: duration,
      title: 'Berhasil',
      mini: true,
    );
  }

  static void miniError({
    required BuildContext context,
    String message = 'Transaksi gagal',
    Duration duration = const Duration(seconds: 2),
  }) {
    show(
      context: context,
      message: message,
      type: DynamicIslandType.error,
      duration: duration,
      title: 'Gagal',
      mini: true,
    );
  }

  /// Menampilkan kapsul idle yang menetap sampai alert berikutnya
  /// dipicu atau dismiss() dipanggil.
  static void showIdle(BuildContext context) {
    dismiss();

    late final OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _DynamicIslandOverlay(
        message: '',
        type: DynamicIslandType.info,
        duration: const Duration(days: 365),
        mini: true,
        startIdle: true,
        onRemove: () {
          if (identical(_entry, entry)) {
            _entry = null;
            entry.remove();
          }
        },
      ),
    );

    _entry = entry;
    Overlay.of(context).insert(entry);
  }

  static void dismiss() {
    final oldEntry = _entry;
    _entry = null;
    oldEntry?.remove();
  }
}

class _DynamicIslandOverlay extends StatefulWidget {
  final String message;
  final DynamicIslandType type;
  final Duration duration;
  final DynamicIslandAction? action;
  final String? title;
  final String? detail;
  final bool mini;
  final bool startIdle;
  final VoidCallback onRemove;

  const _DynamicIslandOverlay({
    required this.message,
    required this.type,
    required this.duration,
    required this.onRemove,
    this.action,
    this.title,
    this.detail,
    this.mini = false,
    this.startIdle = false,
  });

  @override
  State<_DynamicIslandOverlay> createState() => _DynamicIslandOverlayState();
}

class _DynamicIslandOverlayState extends State<_DynamicIslandOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _progress;
  late final AnimationController _pulse;
  late final AnimationController _shake;

  Timer? _timer;
  late _IslandStage _stage;
  bool _closing = false;

  Color get _accent {
    switch (widget.type) {
      case DynamicIslandType.success:
        return const Color(0xFF10B981);
      case DynamicIslandType.error:
        return const Color(0xFFEF4444);
      case DynamicIslandType.warning:
        return const Color(0xFFF59E0B);
      case DynamicIslandType.info:
        return const Color(0xFF38BDF8);
    }
  }

  Color get _background {
    switch (widget.type) {
      case DynamicIslandType.success:
        return const Color(0xFF101A17);
      case DynamicIslandType.error:
        return const Color(0xFF1D1215);
      case DynamicIslandType.warning:
        return const Color(0xFF1D1910);
      case DynamicIslandType.info:
        return const Color(0xFF101820);
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case DynamicIslandType.success:
        return Icons.check_rounded;
      case DynamicIslandType.error:
        return Icons.close_rounded;
      case DynamicIslandType.warning:
        return Icons.warning_amber_rounded;
      case DynamicIslandType.info:
        return Icons.info_outline_rounded;
    }
  }

  @override
  void initState() {
    super.initState();

    _stage = widget.startIdle
        ? _IslandStage.idle
        : widget.mini
        ? _IslandStage.compact
        : _IslandStage.expanded;

    _progress = AnimationController(vsync: this, duration: widget.duration);

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );

    if (!widget.startIdle) {
      _progress.forward();

      if (widget.type == DynamicIslandType.error) {
        _shake.forward();
      }

      _scheduleStageChanges();
    }
  }

  void _scheduleStageChanges() {
    _timer?.cancel();

    _timer = Timer(widget.duration, () {
      if (!mounted || _closing) return;

      _progress.stop();

      // Expanded → Compact
      setState(() => _stage = _IslandStage.compact);

      _timer = Timer(const Duration(milliseconds: 700), () {
        if (!mounted || _closing) return;

        // Compact → Idle
        setState(() => _stage = _IslandStage.idle);

        // Hapus alert setelah 800 ms
        _timer = Timer(const Duration(milliseconds: 800), () {
          if (!mounted || _closing) return;
          _close();
        });
      });
    });
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    _timer?.cancel();

    if (mounted) {
      setState(() => _stage = _IslandStage.idle);
    }

    await Future<void>.delayed(const Duration(milliseconds: 300));

    if (mounted) widget.onRemove();
  }

  void _runAction() {
    widget.action?.onPressed();
    _close();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progress.dispose();
    _pulse.dispose();
    _shake.dispose();
    super.dispose();
  }

  double _width(double screenWidth) {
    switch (_stage) {
      case _IslandStage.expanded:
        return math.min(358, screenWidth - 24);
      case _IslandStage.compact:
        return math.min(250, screenWidth - 24);
      case _IslandStage.idle:
        return math.min(124, screenWidth - 24);
    }
  }

  double get _height {
    switch (_stage) {
      case _IslandStage.expanded:
        return 94;
      case _IslandStage.compact:
        return 40;
      case _IslandStage.idle:
        return 35;
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top + 8;
    final screenWidth = MediaQuery.of(context).size.width;

    return Positioned(
      top: top,
      left: 12,
      right: 12,
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 520),
            curve: Curves.elasticOut,
            width: _width(screenWidth),
            height: _height,
            decoration: BoxDecoration(
              color: _background,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: _accent.withValues(alpha: 0.24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                  spreadRadius: -6,
                ),
                BoxShadow(
                  color: _accent.withValues(alpha: 0.18),
                  blurRadius: 24,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _buildStage(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStage() {
    switch (_stage) {
      case _IslandStage.expanded:
        return _expanded();
      case _IslandStage.compact:
        return _compact();
      case _IslandStage.idle:
        return _idle();
    }
  }

  Widget _expanded() {
    return AnimatedBuilder(
      key: const ValueKey('expanded'),
      animation: Listenable.merge([_pulse, _shake]),
      builder: (context, _) {
        final shake = widget.type == DynamicIslandType.error
            ? math.sin(_shake.value * math.pi * 8) * (1 - _shake.value) * 4
            : 0.0;

        final pulse = 0.9 + (_pulse.value * 0.1);

        return Transform.translate(
          offset: Offset(shake, 0),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: Row(
                  children: [
                    Transform.scale(
                      scale: pulse,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: _accent.withValues(alpha: 0.24),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _accent.withValues(alpha: 0.14),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Icon(_icon, color: _accent, size: 23),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.title ?? _defaultTitle(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: _accent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: _accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.message,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (widget.detail != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              widget.detail!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.58),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (widget.action != null) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: _runAction,
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: _accent,
                          size: 22,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 0,
                child: AnimatedBuilder(
                  animation: _progress,
                  builder: (context, _) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: _progress.value,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            color: _accent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _compact() {
    return Padding(
      key: const ValueKey('compact'),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_icon, color: _accent, size: 17),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              widget.message.isEmpty ? 'Bye' : widget.message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 7),
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: _accent, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }

  Widget _idle() {
    return Padding(
      key: const ValueKey('idle'),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _accent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: _accent.withValues(alpha: 0.5), blurRadius: 5),
              ],
            ),
          ),
          const SizedBox(width: 7),
          const Text(
            'watch',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  String _defaultTitle() {
    switch (widget.type) {
      case DynamicIslandType.success:
        return 'LEDGER CONFIRMED';
      case DynamicIslandType.error:
        return 'VAULT REJECTED';
      case DynamicIslandType.warning:
        return 'WARNING';
      case DynamicIslandType.info:
        return 'INFORMATION';
    }
  }
}

extension DynamicIslandAlertExtension on BuildContext {
  void showDynamicIslandSuccess(
    String message, {
    Duration duration = const Duration(seconds: 3),
    DynamicIslandAction? action,
    String? title,
    String? detail,
  }) {
    DynamicIslandAlert.success(
      context: this,
      message: message,
      duration: duration,
      action: action,
      title: title,
      detail: detail,
    );
  }

  void showDynamicIslandError(
    String message, {
    Duration duration = const Duration(seconds: 4),
    DynamicIslandAction? action,
    String? title,
    String? detail,
  }) {
    DynamicIslandAlert.error(
      context: this,
      message: message,
      duration: duration,
      action: action,
      title: title,
      detail: detail,
    );
  }

  void showDynamicIslandWarning(
    String message, {
    Duration duration = const Duration(seconds: 3),
    DynamicIslandAction? action,
    String? title,
    String? detail,
  }) {
    DynamicIslandAlert.warning(
      context: this,
      message: message,
      duration: duration,
      action: action,
      title: title,
      detail: detail,
    );
  }

  void showDynamicIslandInfo(
    String message, {
    Duration duration = const Duration(seconds: 3),
    DynamicIslandAction? action,
    String? title,
    String? detail,
  }) {
    DynamicIslandAlert.info(
      context: this,
      message: message,
      duration: duration,
      action: action,
      title: title,
      detail: detail,
    );
  }
}
