/// Unified button component for the app.
/// Replaces 5+ different button implementations across screens.
library;

import 'package:flutter/material.dart';
import 'package:watch_your_money/core/theme/app_colors.dart';
import 'package:watch_your_money/core/theme/neumorphic_container.dart';
import 'package:watch_your_money/core/widgets/app_constants.dart';

enum AppButtonStyle {
  /// White background, black text - primary actions
  primary,

  /// Neumorphic raised - secondary actions
  secondary,

  /// Transparent with border - outline actions
  outline,

  /// Text only - tertiary/ghost actions
  ghost,

  /// Icon button in neumorphic container
  icon,

  /// Danger/destructive actions
  destructive,
}

enum AppButtonSize { small, medium, large, extraLarge }

class AppButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final AppButtonStyle style;
  final AppButtonSize size;
  final bool isLoading;
  final bool isFullWidth;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Widget? trailingIcon;

  const AppButton({
    super.key,
    this.label,
    this.icon,
    required this.onPressed,
    this.style = AppButtonStyle.primary,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
    this.padding,
    this.backgroundColor,
    this.foregroundColor,
    this.trailingIcon,
  }) : assert(
         label != null || icon != null,
         'Either label or icon must be provided',
       );

  double get _height {
    switch (size) {
      case AppButtonSize.small:
        return AppSizes.buttonHeightSm;
      case AppButtonSize.medium:
        return AppSizes.buttonHeightMd;
      case AppButtonSize.large:
        return AppSizes.buttonHeightLg;
      case AppButtonSize.extraLarge:
        return AppSizes.buttonHeightXl;
    }
  }

  EdgeInsetsGeometry get _contentPadding {
    switch (size) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: AppSpacing.md);
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: AppSpacing.lg);
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: AppSpacing.xl);
      case AppButtonSize.extraLarge:
        return const EdgeInsets.symmetric(horizontal: AppSpacing.xxl);
    }
  }

  double get _fontSize {
    switch (size) {
      case AppButtonSize.small:
        return 12;
      case AppButtonSize.medium:
        return 14;
      case AppButtonSize.large:
        return 15;
      case AppButtonSize.extraLarge:
        return 16;
    }
  }

  double get _iconSize {
    switch (size) {
      case AppButtonSize.small:
        return AppSizes.iconSm;
      case AppButtonSize.medium:
        return AppSizes.iconMd;
      case AppButtonSize.large:
        return AppSizes.iconLg;
      case AppButtonSize.extraLarge:
        return AppSizes.iconXl;
    }
  }

  BorderRadius get _borderRadius {
    return BorderRadius.circular(AppRadii.pill);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    final child = _buildChild();

    switch (style) {
      case AppButtonStyle.primary:
        return _buildPrimaryButton(enabled, child);
      case AppButtonStyle.secondary:
        return _buildSecondaryButton(enabled, child);
      case AppButtonStyle.outline:
        return _buildOutlineButton(enabled, child);
      case AppButtonStyle.ghost:
        return _buildGhostButton(enabled, child);
      case AppButtonStyle.icon:
        return _buildIconButton(enabled, child);
      case AppButtonStyle.destructive:
        return _buildDestructiveButton(enabled, child);
    }
  }

  Widget _buildChild() {
    if (isLoading) {
      return SizedBox(
        width: _iconSize,
        height: _iconSize,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: _getLoadingColor(),
        ),
      );
    }

    final widgets = <Widget>[];
    if (icon != null) {
      widgets.add(Icon(icon, size: _iconSize));
      if (label != null) widgets.add(const SizedBox(width: AppSpacing.sm));
    }
    if (label != null) {
      widgets.add(
        Text(
          label!,
          style: TextStyle(
            fontSize: _fontSize,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      );
    }
    if (trailingIcon != null) {
      if (label != null || icon != null)
        widgets.add(const SizedBox(width: AppSpacing.sm));
      widgets.add(trailingIcon!);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: widgets,
    );
  }

  Color _getLoadingColor() {
    switch (style) {
      case AppButtonStyle.primary:
      case AppButtonStyle.destructive:
        return AppColors.accentBlack;
      case AppButtonStyle.secondary:
      case AppButtonStyle.outline:
      case AppButtonStyle.ghost:
      case AppButtonStyle.icon:
        return AppColors.textMuted;
    }
  }

  Widget _buildPrimaryButton(bool enabled, Widget child) {
    return SizedBox(
      height: _height,
      width: isFullWidth ? double.infinity : null,
      child: NeumorphicContainer(
        isElevated: true,
        backgroundColor: enabled
            ? AppColors.accentWhite
            : AppColors.surfaceContainerHigh,
        borderRadius: AppRadii.pill,
        onTap: enabled ? onPressed : null,
        padding: padding ?? _contentPadding,
        enablePressAnimation: enabled,
        child: Center(
          child: DefaultTextStyle(
            style: TextStyle(
              color: enabled ? AppColors.accentBlack : AppColors.textMuted,
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(bool enabled, Widget child) {
    return SizedBox(
      height: _height,
      width: isFullWidth ? double.infinity : null,
      child: NeumorphicContainer(
        backgroundColor: enabled
            ? (backgroundColor ?? AppColors.surfaceContainerHigh)
            : AppColors.surfaceContainerLow,
        borderRadius: AppRadii.pill,
        onTap: enabled ? onPressed : null,
        padding: padding ?? _contentPadding,
        enablePressAnimation: enabled,
        child: Center(
          child: DefaultTextStyle(
            style: TextStyle(
              color: enabled
                  ? (foregroundColor ?? AppColors.textPrimary)
                  : AppColors.textMuted,
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildOutlineButton(bool enabled, Widget child) {
    return SizedBox(
      height: _height,
      width: isFullWidth ? double.infinity : null,
      child: NeumorphicContainer(
        backgroundColor: Colors.transparent,
        borderRadius: AppRadii.pill,
        onTap: enabled ? onPressed : null,
        padding: padding ?? _contentPadding,
        enablePressAnimation: enabled,
        child: Center(
          child: DefaultTextStyle(
            style: TextStyle(
              color: enabled
                  ? (foregroundColor ?? AppColors.accentWhite)
                  : AppColors.textMuted,
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildGhostButton(bool enabled, Widget child) {
    return SizedBox(
      height: _height,
      width: isFullWidth ? double.infinity : null,
      child: TextButton(
        onPressed: enabled ? onPressed : null,
        style: TextButton.styleFrom(
          foregroundColor: enabled
              ? (foregroundColor ?? AppColors.textPrimary)
              : AppColors.textMuted,
          padding: padding ?? _contentPadding,
          shape: RoundedRectangleBorder(borderRadius: _borderRadius),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: child,
      ),
    );
  }

  Widget _buildIconButton(bool enabled, Widget child) {
    final dimension = _height;
    return NeumorphicContainer(
      width: dimension,
      height: dimension,
      borderRadius: AppRadii.md,
      padding: EdgeInsets.zero,
      onTap: enabled ? onPressed : null,
      enablePressAnimation: enabled,
      child: Center(
        child: DefaultTextStyle(
          style: TextStyle(
            color: enabled
                ? (foregroundColor ?? AppColors.textPrimary)
                : AppColors.textMuted,
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildDestructiveButton(bool enabled, Widget child) {
    return SizedBox(
      height: _height,
      width: isFullWidth ? double.infinity : null,
      child: NeumorphicContainer(
        isElevated: true,
        backgroundColor: enabled
            ? AppColors.negative
            : AppColors.negative.withValues(alpha: 0.5),
        borderRadius: AppRadii.pill,
        onTap: enabled ? onPressed : null,
        padding: padding ?? _contentPadding,
        enablePressAnimation: enabled,
        child: Center(
          child: DefaultTextStyle(
            style: const TextStyle(color: AppColors.accentWhite),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Convenience factory constructors
class AppButtonPrimary extends AppButton {
  const AppButtonPrimary({
    super.key,
    required super.label,
    required super.onPressed,
    super.size = AppButtonSize.medium,
    super.isLoading = false,
    super.isFullWidth = false,
  }) : super(style: AppButtonStyle.primary);
}

class AppButtonSecondary extends AppButton {
  const AppButtonSecondary({
    super.key,
    required super.label,
    required super.onPressed,
    super.size = AppButtonSize.medium,
    super.isLoading = false,
    super.isFullWidth = false,
  }) : super(style: AppButtonStyle.secondary);
}

class AppButtonOutline extends AppButton {
  const AppButtonOutline({
    super.key,
    required super.label,
    required super.onPressed,
    super.size = AppButtonSize.medium,
    super.isLoading = false,
    super.isFullWidth = false,
  }) : super(style: AppButtonStyle.outline);
}

class AppButtonGhost extends AppButton {
  const AppButtonGhost({
    super.key,
    required super.label,
    required super.onPressed,
    super.size = AppButtonSize.medium,
    super.isFullWidth = false,
  }) : super(style: AppButtonStyle.ghost);
}

class AppButtonIcon extends AppButton {
  const AppButtonIcon({
    super.key,
    required super.icon,
    required super.onPressed,
    super.size = AppButtonSize.medium,
  }) : super(style: AppButtonStyle.icon, label: null);
}

class AppButtonDestructive extends AppButton {
  const AppButtonDestructive({
    super.key,
    required super.label,
    required super.onPressed,
    super.size = AppButtonSize.medium,
    super.isLoading = false,
    super.isFullWidth = false,
  }) : super(style: AppButtonStyle.destructive);
}
