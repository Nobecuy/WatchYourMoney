/// Unified chip and segmented control components for the app.
/// Replaces duplicated selector implementations across screens.
library;

import 'package:flutter/material.dart';
import 'package:watch_your_money/core/theme/app_colors.dart';
import 'package:watch_your_money/core/theme/neumorphic_container.dart';
import 'package:watch_your_money/core/widgets/app_constants.dart';

/// A selectable chip for filter/category selection
class AppChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? selectedColor;
  final Color? unselectedColor;
  final EdgeInsetsGeometry? padding;

  const AppChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
    this.selectedColor,
    this.unselectedColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.normal,
        curve: AppAnimations.standard,
        padding:
            padding ??
            const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
        decoration: BoxDecoration(
          color: selected
              ? (selectedColor ?? AppColors.accentWhite)
              : (unselectedColor ?? Colors.transparent),
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: AppSizes.iconSm,
                color: selected ? AppColors.accentBlack : AppColors.textMuted,
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.accentBlack : AppColors.textMuted,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Segmented control for mutually exclusive options (like Period selector)
class AppSegmentedControl<T> extends StatelessWidget {
  final T value;
  final List<AppSegment<T>> segments;
  final ValueChanged<T> onChanged;
  final bool dense;

  const AppSegmentedControl({
    super.key,
    required this.value,
    required this.segments,
    required this.onChanged,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    return NeumorphicContainer(
      isPressed: true,
      padding: const EdgeInsets.all(AppSpacing.xs),
      borderRadius: AppRadii.lg,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: segments.map((segment) {
          final isSelected = segment.value == value;
          return GestureDetector(
            onTap: () => onChanged(segment.value),
            child: AnimatedContainer(
              duration: AppDurations.normal,
              curve: AppAnimations.standard,
              padding: EdgeInsets.symmetric(
                horizontal: dense ? AppSpacing.sm : AppSpacing.md,
                vertical: dense ? AppSpacing.xs : AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.surfaceContainerHigh
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (segment.icon != null) ...[
                    Icon(
                      segment.icon,
                      size: dense ? AppSizes.iconXs : AppSizes.iconSm,
                      color: isSelected
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Text(
                    segment.label,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                      fontSize: dense ? 10 : 11,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class AppSegment<T> {
  final T value;
  final String label;
  final IconData? icon;

  const AppSegment({required this.value, required this.label, this.icon});
}

/// Filter chip with count badge (for category filters with transaction counts)
class AppFilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback? onTap;
  final Color? color;

  const AppFilterChip({
    super.key,
    required this.label,
    required this.count,
    this.selected = false,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.positive;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.normal,
        curve: AppAnimations.standard,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected
              ? chipColor.withValues(alpha: 0.15)
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: selected
                ? chipColor.withValues(alpha: 0.4)
                : const Color(0x10FFFFFF),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? chipColor : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 1,
              ),
              decoration: BoxDecoration(
                color: selected ? chipColor : AppColors.surfaceDim,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: selected ? AppColors.accentWhite : AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Action chip with trailing action (like Dynamic Island action button)
class AppActionChip extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final IconData? leadingIcon;

  const AppActionChip({
    super.key,
    required this.label,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? AppColors.positive;
    final fgColor = foregroundColor ?? bgColor;

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: bgColor.withValues(alpha: 0.2),
        foregroundColor: fgColor,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          side: BorderSide(color: bgColor.withValues(alpha: 0.4), width: 1),
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingIcon != null) ...[
            Icon(leadingIcon, size: AppSizes.iconSm),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
