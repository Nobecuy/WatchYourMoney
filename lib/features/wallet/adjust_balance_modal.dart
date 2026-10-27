import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:watch_your_money/core/i18n/app_translations.dart';
import 'package:watch_your_money/core/settings/settings_provider.dart';
import 'package:watch_your_money/core/theme/app_colors.dart';
import 'package:watch_your_money/core/theme/neumorphic_container.dart';
import 'package:watch_your_money/core/utils/currency_formatter.dart';
import 'package:watch_your_money/core/utils/dynamic_island_alert.dart';
import 'package:watch_your_money/core/widgets/app_card.dart';
import 'package:watch_your_money/domain/models/transaction_model.dart';
import 'package:watch_your_money/features/dashboard/dashboard_provider.dart';
import 'package:watch_your_money/features/wallet/widgets/wallet_current_balance_card.dart';
import 'package:watch_your_money/features/wallet/widgets/wallet_difference_preview.dart';
import 'package:watch_your_money/features/wallet/widgets/wallet_method_selector.dart';
import 'package:watch_your_money/features/wallet/widgets/wallet_note_field.dart';
import 'package:watch_your_money/features/wallet/widgets/wallet_preset_chips.dart';
import 'package:watch_your_money/features/wallet/widgets/wallet_save_button.dart';
import 'package:watch_your_money/features/wallet/widgets/wallet_target_amount_input.dart';

class AdjustBalanceModal extends ConsumerStatefulWidget {
  final String initialMethod; // 'card' | 'cash'
  final double currentCardBalance;
  final double currentCashBalance;

  const AdjustBalanceModal({
    super.key,
    this.initialMethod = 'card',
    required this.currentCardBalance,
    required this.currentCashBalance,
  });

  @override
  ConsumerState<AdjustBalanceModal> createState() => _AdjustBalanceModalState();
}

class _AdjustBalanceModalState extends ConsumerState<AdjustBalanceModal> {
  late String _method; // 'card' | 'cash'
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _method = widget.initialMethod;
    _initializeAmountAndNote();
  }

  void _initializeAmountAndNote() {
    final current = _currentBalance;
    final amountText = current > 0 ? current.toInt().toString() : '';
    if (amountText.isNotEmpty) {
      final formatted = ThousandsSeparatorInputFormatter().formatEditUpdate(
        TextEditingValue.empty,
        TextEditingValue(text: amountText),
      );
      _amountController.text = formatted.text;
      _amountController.selection = formatted.selection;
    }
    final settings = ref.read(appSettingsProvider);
    final t = AppTranslations.of(settings.languageCode);
    _noteController.text =
        '${t.adjustBalanceCategory} ${_method == 'card' ? t.cardCredit : t.cashWalletName}';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double get _currentBalance =>
      _method == 'card' ? widget.currentCardBalance : widget.currentCashBalance;

  void _switchMethod(String newMethod) {
    if (_method == newMethod) return;
    setState(() {
      _method = newMethod;
      _initializeAmountAndNote();
    });
  }

  double _parseTargetAmount() {
    return _amountController.text.numericValue;
  }

  Future<void> _saveAdjustment() async {
    final target = _parseTargetAmount();
    final current = _currentBalance;
    final diff = target - current;
    final settings = ref.read(appSettingsProvider);
    final t = AppTranslations.of(settings.languageCode);

    if (diff.abs() < 0.01) {
      context.showDynamicIslandWarning(t.balanceSameAsCurrent);
      Navigator.pop(context);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final isIncrease = diff > 0;
      final tx = TransactionModel(
        id: const Uuid().v4(),
        amount: diff.abs(),
        type: isIncrease ? 'income' : 'expense',
        categoryId: t.adjustBalanceCategory,
        note: _noteController.text.trim().isNotEmpty
            ? _noteController.text.trim()
            : '${t.adjustBalanceCategory} ${_method == 'card' ? t.cardCredit : t.cashWalletName}',
        date: DateTime.now(),
        paymentMethod: _method,
      );

      await ref.read(transactionRepositoryProvider).addTransaction(tx);
      ref.invalidate(transactionsProvider);

      final fmt = CurrencyFormatter.from(ref.read(appSettingsProvider));
      if (mounted) {
        Navigator.pop(context, true);
        context.showDynamicIslandSuccess(
          '${_method == 'card' ? t.balanceUpdatedCard : t.balanceUpdatedCash} ${fmt.format(target)}',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        context.showDynamicIslandError('${t.failedToUpdateBalance}: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final fmt = CurrencyFormatter.from(settings);
    final t = AppTranslations.of(settings.languageCode);
    final current = _currentBalance;
    final target = _parseTargetAmount();
    final diff = target - current;
    final isCard = _method == 'card';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBright,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isCard
                                  ? const Color(0xFF6366F1)
                                  : const Color(0xFF10B981))
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isCard
                              ? Icons.credit_card_rounded
                              : Icons.payments_rounded,
                          color: isCard
                              ? const Color(0xFF818CF8)
                              : const Color(0xFF34D399),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Edit / Sesuaikan Saldo',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            isCard ? t.correctCardBalance : t.correctCashBalance,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const NeumorphicContainer(
                      width: 34,
                      height: 34,
                      borderRadius: 10,
                      padding: EdgeInsets.zero,
                      child: Center(
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 200.ms),

              const SizedBox(height: 20),

              // Wallet Method Selector
              WalletMethodSelector(
                selectedMethod: _method,
                onMethodChanged: _switchMethod,
              ),

              const SizedBox(height: 18),

              // Current Balance Info Card
              WalletCurrentBalanceCard(
                method: _method,
                currentBalance: current,
                fmt: fmt,
              ),

              const SizedBox(height: 16),

              // Balance Transition Preview (Before → After)
              if (diff != 0)
                AppTransitionDisplay(
                  fromValue: fmt.format(current),
                  toValue: fmt.format(target),
                  isPositive: diff > 0,
                ),

              const SizedBox(height: 16),

              // Target Balance Input Card
              WalletTargetAmountInput(
                controller: _amountController,
                fmt: fmt,
                onChanged: () => setState(() {}),
              ),

              // Quick Amount Presets
              WalletPresetChips(
                currentBalance: current,
                controller: _amountController,
                fmt: fmt,
              ),

              // Difference Calculation Preview
              WalletDifferencePreview(
                current: current,
                target: target,
                fmt: fmt,
              ),

              const SizedBox(height: 14),

              // Note Field
              WalletNoteField(
                controller: _noteController,
              ),

              const SizedBox(height: 22),

              // Save Button
              WalletSaveButton(
                isLoading: _isLoading,
                onPressed: _saveAdjustment,
              ),
            ],
          ),
        ),
      ),
    );
  }
}