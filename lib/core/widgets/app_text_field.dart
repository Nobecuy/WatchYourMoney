/// Unified text field component for the app.
/// Replaces 4+ different text field implementations across screens.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:watch_your_money/core/theme/app_colors.dart';
import 'package:watch_your_money/core/theme/neumorphic_container.dart';
import 'package:watch_your_money/core/widgets/app_constants.dart';

class AppTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool obscureText;
  final bool enabled;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final FormFieldValidator<String>? validator;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization;
  final EdgeInsetsGeometry? contentPadding;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.obscureText = false,
    this.enabled = true,
    this.autofocus = false,
    this.textInputAction,
    this.onChanged,
    this.onTap,
    this.validator,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
    this.contentPadding,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late FocusNode _focusNode;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() => _hasFocus = _focusNode.hasFocus);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            boxShadow: _hasFocus && widget.enabled
                ? [
                    BoxShadow(
                      color: AppColors.accentWhite.withValues(alpha: 0.15),
                      blurRadius: 16,
                      spreadRadius: 2,
                      offset: const Offset(0, 0),
                    ),
                    BoxShadow(
                      color: AppColors.accentWhite.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: NeumorphicContainer(
            isPressed: true,
            padding: EdgeInsets.zero,
            borderRadius: AppRadii.lg,
            clipBehavior: Clip.antiAlias,
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              autofocus: widget.autofocus,
              maxLines: widget.maxLines,
              minLines: widget.minLines,
              maxLength: widget.maxLength,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              inputFormatters: widget.inputFormatters,
              textInputAction: widget.textInputAction,
              textCapitalization: widget.textCapitalization,
              onChanged: widget.onChanged,
              onTap: widget.onTap,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                height: 1.5,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
                helperText: widget.helperText,
                helperStyle: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
                errorText: widget.errorText,
                errorStyle: const TextStyle(
                  color: AppColors.negative,
                  fontSize: 11,
                ),
                prefixIcon: widget.prefixIcon != null
                    ? Icon(
                        widget.prefixIcon,
                        color: AppColors.textMuted,
                        size: AppSizes.iconMd,
                      )
                    : null,
                suffixIcon: widget.suffixIcon,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding:
                    widget.contentPadding ??
                    const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                counterText: '',
                isDense: true,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Specialized text field for currency input with thousands separator
class AppCurrencyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final String? hintText;
  final ValueChanged<double>? onAmountChanged;
  final bool enabled;
  final bool autofocus;

  const AppCurrencyTextField({
    super.key,
    required this.controller,
    this.label,
    this.hintText,
    this.onAmountChanged,
    this.enabled = true,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: label,
      hintText: hintText,
      keyboardType: TextInputType.number,
      inputFormatters: [
        ThousandsSeparatorInputFormatter(),
        FilteringTextInputFormatter.digitsOnly,
      ],
      enabled: enabled,
      autofocus: autofocus,
      onChanged: (value) {
        if (onAmountChanged != null) {
          onAmountChanged!(value.numericValue);
        }
      },
      prefixIcon: Icons.attach_money_rounded,
    );
  }
}

/// Input formatter for thousands separator (Indonesian format: 1.000.000)
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove all non-digits
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.isEmpty) {
      return TextEditingValue.empty;
    }

    // Format with Indonesian thousands separator (.)
    final formatted = _formatWithSeparator(digitsOnly);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatWithSeparator(String digits) {
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      final indexFromEnd = digits.length - i;
      if (indexFromEnd % 3 == 0 && i != 0) {
        buffer.write('.');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}

extension StringExtension on String {
  double get numericValue {
    return double.tryParse(replaceAll('.', '').replaceAll(',', '')) ?? 0.0;
  }
}
