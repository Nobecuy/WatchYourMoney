/// Unified card and section container components for the app.
/// Replaces repeated NeumorphicContainer patterns with consistent padding, radius, and styling.

import 'package:flutter/material.dart';
import 'package:watch_your_money/core/theme/app_colors.dart';
import 'package:watch_your_money/core/theme/neumorphic_container.dart';
import 'package:watch_your_money/core/widgets/app_constants.dart';

/// Standard card container with consistent styling
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final Color? backgroundColor;
  final bool isPressed;
  final bool isElevated;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final Clip clipBehavior;
  final bool enablePressAnimation;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
    this.isPressed = false,
    this.isElevated = false,
    this.onTap,
    this.width,
    this.height,
    this.clipBehavior = Clip.none,
    this.enablePressAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    return NeumorphicContainer(
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      borderRadius: borderRadius ?? AppRadii.xl,
      backgroundColor: backgroundColor ?? AppColors.surfaceContainer,
      isPressed: isPressed,
      isElevated: isElevated,
      onTap: onTap,
      width: width,
      height: height,
      clipBehavior: clipBehavior,
      enablePressAnimation: enablePressAnimation && onTap != null,
      child: child,
    );
  }
}

/// Section container with optional header and consistent spacing
class AppSection extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;

  const AppSection({
    super.key,
    this.title,
    this.subtitle,
    this.trailing,
    required this.children,
    this.padding,
    this.borderRadius,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: [
        if (title != null || trailing != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (title != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title!,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ...children,
      ],
    );
  }
}

/// Summary card for displaying key metrics (income, expense, balance, etc.)
class AppSummaryCard extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  final IconData icon;
  final String? trend;
  final Color? trendColor;
  final VoidCallback? onTap;

  const AppSummaryCard({
    super.key,
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
    this.trend,
    this.trendColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NeumorphicContainer(
      borderRadius: AppRadii.lg,
      padding: const EdgeInsets.all(AppSpacing.lg),
      isPressed: onTap != null,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(icon, color: color, size: AppSizes.iconSm),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            amount,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          if (trend != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(
                  trend!.startsWith('+') || trend!.startsWith('↑')
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: AppSizes.iconXs,
                  color: trendColor ?? color,
                ),
                const SizedBox(width: 4),
                Text(
                  trend!,
                  style: TextStyle(
                    color: trendColor ?? color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Info card for displaying current/target values (used in Adjust Balance modal)
class AppInfoCard extends StatelessWidget {
  final String label;
  final String value;
  final String? badgeText;
  final Color? badgeColor;
  final Color valueColor;
  final Widget? trailing;

  const AppInfoCard({
    super.key,
    required this.label,
    required this.value,
    this.badgeText,
    this.badgeColor,
    this.valueColor = AppColors.textPrimary,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return NeumorphicContainer(
      borderRadius: AppRadii.md,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (badgeText != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: (badgeColor ?? AppColors.positive).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Text(
                badgeText!,
                style: TextStyle(
                  color: badgeColor ?? AppColors.positive,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Transition display showing before → after values (for balance changes)
class AppTransitionDisplay extends StatelessWidget {
  final String fromValue;
  final String toValue;
  final bool isPositive;
  final String? fromLabel;
  final String? toLabel;

  const AppTransitionDisplay({
    super.key,
    required this.fromValue,
    required this.toValue,
    required this.isPositive,
    this.fromLabel,
    this.toLabel,
  });

  @override
  Widget build(BuildContext context) {
    return NeumorphicContainer(
      borderRadius: AppRadii.md,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (fromLabel != null) ...[
            Text(
              fromLabel!,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Text(
            fromValue,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: isPositive
                  ? AppColors.positive.withValues(alpha: 0.15)
                  : AppColors.negative.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
            child: Icon(
              isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              size: AppSizes.iconSm,
              color: isPositive ? AppColors.positive : AppColors.negative,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            toValue,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w700,
            ),
          ),
          if (toLabel != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Text(
              toLabel!,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Quick action card for dashboard quick actions
class AppQuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isWide;

  const AppQuickAction({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    return NeumorphicContainer(
      isElevated: true,
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? AppSpacing.lg : AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      borderRadius: AppRadii.lg,
      backgroundColor: AppColors.surfaceContainer,
      onTap: onTap,
      enablePressAnimation: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Icon(icon, color: color, size: AppSizes.iconMd),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}