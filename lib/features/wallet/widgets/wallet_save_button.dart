// Save button widget for Adjust Balance modal.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:watch_your_money/core/theme/app_colors.dart';

class WalletSaveButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const WalletSaveButton({
    super.key,
    required this.isLoading,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.accentWhite,
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33FFFFFF),
              offset: Offset(0, 4),
              blurRadius: 14,
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.accentBlack,
                  ),
                )
              : const Text(
                  'Perbarui Saldo',
                  style: TextStyle(
                    color: AppColors.accentBlack,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
        ),
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.1);
  }
}