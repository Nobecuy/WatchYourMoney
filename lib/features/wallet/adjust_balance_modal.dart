import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:watch_your_money/core/settings/settings_provider.dart';
import 'package:watch_your_money/core/theme/app_colors.dart';
import 'package:watch_your_money/core/theme/neumorphic_container.dart';
import 'package:watch_your_money/core/utils/currency_formatter.dart';
import 'package:watch_your_money/domain/models/transaction_model.dart';
import 'package:watch_your_money/features/dashboard/dashboard_provider.dart';

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
    _noteController.text =
        'Penyesuaian saldo ${_method == 'card' ? 'Kartu / Kredit' : 'Tunai'}';
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
      final current = _currentBalance;
      final amountText = current > 0 ? current.toInt().toString() : '';
      if (amountText.isNotEmpty) {
        final formatted = ThousandsSeparatorInputFormatter().formatEditUpdate(
          TextEditingValue.empty,
          TextEditingValue(text: amountText),
        );
        _amountController.text = formatted.text;
        _amountController.selection = formatted.selection;
      } else {
        _amountController.text = '';
      }
      _noteController.text =
          'Penyesuaian saldo ${_method == 'card' ? 'Kartu / Kredit' : 'Tunai'}';
    });
  }

  double _parseTargetAmount() {
    return _amountController.text.numericValue;
  }

  Future<void> _saveAdjustment() async {
    final target = _parseTargetAmount();
    final current = _currentBalance;
    final diff = target - current;

    if (diff.abs() < 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nominal saldo baru sama dengan saldo saat ini.'),
          backgroundColor: AppColors.surfaceContainerHigh,
        ),
      );
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
        categoryId: 'Penyesuaian Saldo',
        note: _noteController.text.trim().isNotEmpty
            ? _noteController.text.trim()
            : 'Penyesuaian saldo ${_method == 'card' ? 'Kartu / Kredit' : 'Tunai'}',
        date: DateTime.now(),
        paymentMethod: _method,
      );

      await ref.read(transactionRepositoryProvider).addTransaction(tx);
      ref.invalidate(transactionsProvider);

      final fmt = CurrencyFormatter.from(ref.read(appSettingsProvider));
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Saldo ${_method == 'card' ? 'Kartu / Kredit' : 'Tunai'} berhasil diubah ke ${fmt.format(target)}',
            ),
            backgroundColor: AppColors.surfaceContainerHigh,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui saldo: $e'),
            backgroundColor: AppColors.surfaceContainerHigh,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final fmt = CurrencyFormatter.from(settings);
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
                          color:
                              (isCard
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
                            'Koreksi saldo riil ${isCard ? 'kartu kredit/debit' : 'kas tunai'}',
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

              // Account Selector (Kartu/Kredit vs Tunai)
              NeumorphicContainer(
                isPressed: true,
                padding: const EdgeInsets.all(4),
                borderRadius: 16,
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _switchMethod('card'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isCard
                                ? AppColors.surfaceContainerHigh
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: isCard
                                ? const [
                                    BoxShadow(
                                      color: Color(0x66000000),
                                      offset: Offset(0, 3),
                                      blurRadius: 8,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.credit_card_rounded,
                                size: 16,
                                color: isCard
                                    ? const Color(0xFF818CF8)
                                    : AppColors.textMuted,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Kartu / Kredit',
                                style: TextStyle(
                                  color: isCard
                                      ? AppColors.textPrimary
                                      : AppColors.textMuted,
                                  fontWeight: isCard
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _switchMethod('cash'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !isCard
                                ? AppColors.surfaceContainerHigh
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: !isCard
                                ? const [
                                    BoxShadow(
                                      color: Color(0x66000000),
                                      offset: Offset(0, 3),
                                      blurRadius: 8,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.payments_rounded,
                                size: 16,
                                color: !isCard
                                    ? const Color(0xFF34D399)
                                    : AppColors.textMuted,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Uang Tunai',
                                style: TextStyle(
                                  color: !isCard
                                      ? AppColors.textPrimary
                                      : AppColors.textMuted,
                                  fontWeight: !isCard
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Current Balance Info Card
              NeumorphicContainer(
                borderRadius: 14,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SALDO SAAT INI DI APLIKASI',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          fmt.format(current),
                          style: TextStyle(
                            color: current >= 0
                                ? AppColors.textPrimary
                                : AppColors.negativeLight,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (isCard
                                    ? const Color(0xFF6366F1)
                                    : const Color(0xFF10B981))
                                .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isCard ? 'DOMPET KARTU' : 'DOMPET KAS',
                        style: TextStyle(
                          color: isCard
                              ? const Color(0xFF818CF8)
                              : const Color(0xFF34D399),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Target Balance Input Card
              NeumorphicContainer(
                isPressed: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                borderRadius: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SALDO SEBENARNYA (TARGET)',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text(
                          'Rp',
                          style: TextStyle(
                            color: AppColors.accentWhite,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            autofocus: true,
                            onChanged: (_) => setState(() {}),
                            inputFormatters: [
                              ThousandsSeparatorInputFormatter(),
                            ],
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                            decoration: const InputDecoration(
                              hintText: '0',
                              hintStyle: TextStyle(color: AppColors.textMuted),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Quick Amount Presets
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPresetChip('Set ke 0', 0),
                      _buildPresetChip('+100rb', current + 100000),
                      _buildPresetChip('+500rb', current + 500000),
                      _buildPresetChip('+1jt', current + 1000000),
                      _buildPresetChip('+5jt', current + 5000000),
                    ],
                  ),
                ),
              ),

              // Difference Calculation Preview
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: diff == 0
                        ? const Color(0x14FFFFFF)
                        : (diff > 0
                              ? const Color(0x3310B981)
                              : const Color(0x33F43F5E)),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      diff == 0
                          ? Icons.info_outline_rounded
                          : (diff > 0
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded),
                      size: 16,
                      color: diff == 0
                          ? AppColors.textMuted
                          : (diff > 0
                                ? AppColors.positive
                                : AppColors.negativeLight),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        diff == 0
                            ? 'Saldo tidak berubah'
                            : (diff > 0
                                  ? 'Pemasukan penyesuaian: +${fmt.format(diff)}'
                                  : 'Pengeluaran penyesuaian: -${fmt.format(diff.abs())}'),
                        style: TextStyle(
                          color: diff == 0
                              ? AppColors.textMuted
                              : (diff > 0
                                    ? AppColors.positive
                                    : AppColors.negativeLight),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Note Field
              NeumorphicContainer(
                isPressed: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                borderRadius: 999,
                clipBehavior: Clip.antiAlias,
                child: TextField(
                  controller: _noteController,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Keterangan penyesuaian...',
                    hintStyle: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                    icon: Icon(
                      Icons.edit_note_rounded,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // Save Button
              GestureDetector(
                onTap: _isLoading ? null : _saveAdjustment,
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
                    child: _isLoading
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
              ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, double value) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () {
          setState(() {
            final amountText = value.toInt().toString();
            if (amountText.isNotEmpty) {
              final formatted = ThousandsSeparatorInputFormatter().formatEditUpdate(
                TextEditingValue.empty,
                TextEditingValue(text: amountText),
              );
              _amountController.text = formatted.text;
              _amountController.selection = formatted.selection;
            } else {
              _amountController.text = '';
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0x0FFFFFFF)),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
