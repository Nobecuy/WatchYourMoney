import 'package:flutter/material.dart';
import 'package:watch_your_money/core/theme/app_colors.dart';
import 'package:watch_your_money/core/theme/neumorphic_container.dart';

/// Custom Dialog utility for consistent theming across the app
/// Matches the dark monochrome Onyx theme (#0A0A0A / #121316)

/// Shows a simple alert dialog with a message and single OK button
Future<void> showCustomAlert({
  required BuildContext context,
  required String title,
  required String message,
  String? buttonText,
  IconData? icon,
  Color? iconColor,
  VoidCallback? onConfirm,
}) {
  final t = buttonText ?? 'OK';

  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _CustomAlertDialog(
      title: title,
      message: message,
      buttonText: t,
      icon: icon,
      iconColor: iconColor,
      onConfirm: onConfirm,
    ),
  );
}

/// Shows a confirmation dialog with Yes/No buttons
Future<bool?> showCustomConfirm({
  required BuildContext context,
  required String title,
  required String message,
  String? confirmText,
  String? cancelText,
  bool isDestructive = false,
  IconData? icon,
  Color? iconColor,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _CustomConfirmDialog(
      title: title,
      message: message,
      confirmText: confirmText ?? 'Ya',
      cancelText: cancelText ?? 'Batal',
      isDestructive: isDestructive,
      icon: icon,
      iconColor: iconColor,
    ),
  );
}

/// Shows a dialog with a text input field
Future<String?> showCustomInputDialog({
  required BuildContext context,
  required String title,
  required String hintText,
  String? initialValue,
  String? confirmText,
  String? cancelText,
  TextInputType keyboardType = TextInputType.text,
  String? Function(String?)? validator,
}) {
  final controller = TextEditingController(text: initialValue);

  return showDialog<String>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _CustomInputDialog(
      title: title,
      hintText: hintText,
      controller: controller,
      confirmText: confirmText ?? 'Simpan',
      cancelText: cancelText ?? 'Batal',
      keyboardType: keyboardType,
      validator: validator,
    ),
  );
}

/// Generic custom dialog builder for full control
Future<T?> showCustomDialog<T>({
  required BuildContext context,
  required Widget child,
  bool barrierDismissible = true,
  Color? backgroundColor,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (ctx) => Dialog(
      backgroundColor: backgroundColor ?? AppColors.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: child,
    ),
  );
}

/// Internal: Simple Alert Dialog Widget
class _CustomAlertDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback? onConfirm;

  const _CustomAlertDialog({
    required this.title,
    required this.message,
    required this.buttonText,
    this.icon,
    this.iconColor,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: iconColor ?? AppColors.textSecondary,
                size: 40,
              ),
              const SizedBox(height: 16),
            ],
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentWhite,
                  foregroundColor: AppColors.accentBlack,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  onConfirm?.call();
                },
                child: Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Internal: Confirmation Dialog Widget
class _CustomConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final bool isDestructive;
  final IconData? icon;
  final Color? iconColor;

  const _CustomConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmText,
    required this.cancelText,
    required this.isDestructive,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: iconColor ?? (isDestructive ? AppColors.negativeLight : AppColors.textSecondary),
                size: 40,
              ),
              const SizedBox(height: 16),
            ],
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: NeumorphicContainer(
                    onTap: () => Navigator.of(context).pop(false),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    borderRadius: 12,
                    child: Center(
                      child: Text(
                        cancelText,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: NeumorphicContainer(
                    onTap: () => Navigator.of(context).pop(true),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    borderRadius: 12,
                    backgroundColor: isDestructive
                        ? AppColors.negative.withValues(alpha: 0.2)
                        : AppColors.surfaceBright,
                    child: Center(
                      child: Text(
                        confirmText,
                        style: TextStyle(
                          color: isDestructive
                              ? AppColors.negativeLight
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Internal: Input Dialog Widget
class _CustomInputDialog extends StatefulWidget {
  final String title;
  final String hintText;
  final TextEditingController controller;
  final String confirmText;
  final String cancelText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _CustomInputDialog({
    required this.title,
    required this.hintText,
    required this.controller,
    required this.confirmText,
    required this.cancelText,
    required this.keyboardType,
    this.validator,
  });

  @override
  State<_CustomInputDialog> createState() => _CustomInputDialogState();
}

class _CustomInputDialogState extends State<_CustomInputDialog> {
  String? _errorText;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: widget.controller,
              autofocus: true,
              keyboardType: widget.keyboardType,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: const TextStyle(color: AppColors.textMuted),
                errorText: _errorText,
                filled: true,
                fillColor: AppColors.surfaceDim,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.surfaceBright, width: 1),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.negative, width: 1),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (value) {
                if (_errorText != null && widget.validator != null) {
                  setState(() {
                    _errorText = widget.validator!(value);
                  });
                }
              },
              onSubmitted: (_) => _handleConfirm(),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: NeumorphicContainer(
                    onTap: () => Navigator.of(context).pop(),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    borderRadius: 12,
                    child: Center(
                      child: Text(
                        widget.cancelText,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: NeumorphicContainer(
                    onTap: _handleConfirm,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    borderRadius: 12,
                    backgroundColor: AppColors.surfaceBright,
                    child: Center(
                      child: Text(
                        widget.confirmText,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleConfirm() {
    if (widget.validator != null) {
      final error = widget.validator!(widget.controller.text);
      if (error != null) {
        setState(() => _errorText = error);
        return;
      }
    }
    Navigator.of(context).pop(widget.controller.text.trim());
  }
}