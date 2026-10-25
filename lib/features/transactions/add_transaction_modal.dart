import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:watch_your_money/core/i18n/app_translations.dart';
import 'package:watch_your_money/core/settings/settings_provider.dart';
import 'package:watch_your_money/core/theme/app_colors.dart';
import 'package:watch_your_money/core/theme/neumorphic_container.dart';
import 'package:watch_your_money/core/utils/currency_formatter.dart';
import 'package:watch_your_money/domain/models/transaction_model.dart';
import 'package:watch_your_money/features/dashboard/dashboard_provider.dart';

class AddTransactionModal extends ConsumerStatefulWidget {
  final String initialType;
  final String? initialPaymentMethod;
  final TransactionModel? transactionToEdit;

  const AddTransactionModal({
    super.key,
    this.initialType = 'expense',
    this.initialPaymentMethod,
    this.transactionToEdit,
  });

  @override
  ConsumerState<AddTransactionModal> createState() =>
      _AddTransactionModalState();
}

class _AddTransactionModalState extends ConsumerState<AddTransactionModal> {
  late String _type; // 'expense' | 'income'
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  late String _paymentMethod; // 'cash' | 'card'
  late String _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  final List<Map<String, dynamic>> _expenseCategories = [
    {'name': 'Makanan', 'icon': Icons.restaurant_rounded},
    {'name': 'Transportasi', 'icon': Icons.directions_car_rounded},
    {'name': 'Belanja', 'icon': Icons.shopping_bag_rounded},
    {'name': 'Tagihan', 'icon': Icons.receipt_long_rounded},
    {'name': 'Hiburan', 'icon': Icons.movie_rounded},
    {'name': 'Kesehatan', 'icon': Icons.local_hospital_rounded},
    {'name': 'Edukasi', 'icon': Icons.school_rounded},
    {'name': 'Lainnya', 'icon': Icons.more_horiz_rounded},
  ];

  final List<Map<String, dynamic>> _incomeCategories = [
    {'name': 'Gaji', 'icon': Icons.payments_rounded},
    {'name': 'Bonus / Freelance', 'icon': Icons.work_rounded},
    {'name': 'Investasi', 'icon': Icons.trending_up_rounded},
    {'name': 'Hadiah', 'icon': Icons.card_giftcard_rounded},
    {'name': 'Penjualan', 'icon': Icons.storefront_rounded},
    {'name': 'Lainnya', 'icon': Icons.more_horiz_rounded},
  ];

  @override
  void initState() {
    super.initState();
    final editTx = widget.transactionToEdit;
    if (editTx != null) {
      _type = editTx.type;
      _paymentMethod = editTx.paymentMethod;
      final amountText = editTx.amount.toInt().toString();
      final formatted = ThousandsSeparatorInputFormatter().formatEditUpdate(
        TextEditingValue.empty,
        TextEditingValue(text: amountText),
      );
      _amountController.text = formatted.text;
      _amountController.selection = formatted.selection;
      _noteController.text = editTx.note;
      _selectedDate = editTx.date;
      _selectedCategory = editTx.categoryId;

      // Ensure custom or adjustment category exists in list
      final catList = _type == 'expense'
          ? _expenseCategories
          : _incomeCategories;
      final exists = catList.any(
        (c) =>
            (c['name'] as String).toLowerCase() ==
            _selectedCategory.toLowerCase(),
      );
      if (!exists) {
        catList.insert(0, {
          'name': _selectedCategory,
          'icon': Icons.label_outline_rounded,
        });
      }
    } else {
      _type = widget.initialType;
      _paymentMethod = widget.initialPaymentMethod ?? 'cash';
      _selectedCategory = _type == 'expense'
          ? _expenseCategories.first['name'] as String
          : _incomeCategories.first['name'] as String;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _switchType(String newType) {
    if (_type == newType) return;
    setState(() {
      _type = newType;
      _selectedCategory = _type == 'expense'
          ? _expenseCategories.first['name'] as String
          : _incomeCategories.first['name'] as String;
    });
  }

  void _quickAddAmount(double add) {
    final current = _amountController.text.numericValue;
    final updated = current + add;
    _amountController.text = updated.toInt().toString();
    // Apply formatter manually since we're setting text programmatically
    final formatted = ThousandsSeparatorInputFormatter().formatEditUpdate(
      TextEditingValue.empty,
      TextEditingValue(text: updated.toInt().toString()),
    );
    _amountController.text = formatted.text;
    _amountController.selection = formatted.selection;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accentWhite,
              onPrimary: AppColors.accentBlack,
              surface: AppColors.surfaceContainerHigh,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _showAddCustomCategoryDialog() {
    final t = AppTranslations.of(ref.read(appSettingsProvider).languageCode);
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          t.addCategory,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: t.categoryName,
            hintStyle: const TextStyle(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.surfaceDim,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              t.cancel,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentWhite,
              foregroundColor: AppColors.accentBlack,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              final cat = textController.text.trim();
              if (cat.isNotEmpty) {
                setState(() {
                  if (_type == 'expense') {
                    _expenseCategories.insert(0, {
                      'name': cat,
                      'icon': Icons.label_outline_rounded,
                    });
                  } else {
                    _incomeCategories.insert(0, {
                      'name': cat,
                      'icon': Icons.label_outline_rounded,
                    });
                  }
                  _selectedCategory = cat;
                });
                Navigator.pop(ctx);
              }
            },
            child: Text(
              t.save,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteThisTransaction() async {
    final t = AppTranslations.of(ref.read(appSettingsProvider).languageCode);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          t.deleteTransaction,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        content: Text(
          t.confirmDelete,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              t.cancel,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.negative,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      await ref
          .read(transactionRepositoryProvider)
          .deleteTransaction(widget.transactionToEdit!.id);
      ref.invalidate(transactionsProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.txDeleted),
            backgroundColor: AppColors.surfaceContainerHigh,
          ),
        );
      }
    }
  }

  Future<void> _saveTransaction() async {
    final t = AppTranslations.of(ref.read(appSettingsProvider).languageCode);
    final amount = _amountController.text.numericValue;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.enterValidAmount),
          backgroundColor: AppColors.surfaceContainerHigh,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final isEdit = widget.transactionToEdit != null;
      final tx = TransactionModel(
        id: isEdit ? widget.transactionToEdit!.id : const Uuid().v4(),
        amount: amount,
        type: _type,
        categoryId: _selectedCategory,
        note: _noteController.text.trim(),
        date: _selectedDate,
        paymentMethod: _paymentMethod,
      );

      if (isEdit) {
        await ref.read(transactionRepositoryProvider).updateTransaction(tx);
      } else {
        await ref.read(transactionRepositoryProvider).addTransaction(tx);
      }

      ref.invalidate(transactionsProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? t.txUpdated : t.txSaved),
            backgroundColor: AppColors.surfaceContainerHigh,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
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
    final t = AppTranslations.of(settings.languageCode);
    final isExpense = _type == 'expense';
    final currentCategories = isExpense
        ? _expenseCategories
        : _incomeCategories;

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
              // ── Top Handle Indicator ─────────────────────────
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

              // ── Header Title & Close Button ──────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.transactionToEdit != null
                        ? t.editTransaction
                        : t.addTransaction,
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      if (widget.transactionToEdit != null) ...[
                        GestureDetector(
                          onTap: _deleteThisTransaction,
                          child: const NeumorphicContainer(
                            width: 34,
                            height: 34,
                            borderRadius: 10,
                            padding: EdgeInsets.zero,
                            child: Center(
                              child: Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: AppColors.negativeLight,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
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
                  ),
                ],
              ).animate().fadeIn(duration: 200.ms),

              const SizedBox(height: 20),

              // ── Animated Type Toggle: Pengeluaran vs Pemasukan ──
              NeumorphicContainer(
                isPressed: true,
                padding: const EdgeInsets.all(4),
                borderRadius: 16,
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _switchType('expense'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isExpense
                                ? AppColors.surfaceContainerHigh
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: isExpense
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
                                Icons.arrow_upward_rounded,
                                size: 16,
                                color: isExpense
                                    ? AppColors.textPrimary
                                    : AppColors.textMuted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                t.expense,
                                style: TextStyle(
                                  color: isExpense
                                      ? AppColors.textPrimary
                                      : AppColors.textMuted,
                                  fontWeight: isExpense
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _switchType('income'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !isExpense
                                ? AppColors.surfaceContainerHigh
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: !isExpense
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
                                Icons.arrow_downward_rounded,
                                size: 16,
                                color: !isExpense
                                    ? AppColors.textPrimary
                                    : AppColors.textMuted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                t.income,
                                style: TextStyle(
                                  color: !isExpense
                                      ? AppColors.textPrimary
                                      : AppColors.textMuted,
                                  fontWeight: !isExpense
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.1),

              const SizedBox(height: 20),

              // ── Nominal Input Card ───────────────────────────
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
                      'NOMINAL',
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
                        Text(
                          fmt.symbol,
                          style: TextStyle(
                            color: isExpense
                                ? const Color(0xFFE2E8F0)
                                : AppColors.accentWhite,
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
              ).animate().fadeIn(delay: 50.ms, duration: 250.ms),

              // Quick Amount Chips
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildQuickAmountChip('+50rb', 50000),
                      _buildQuickAmountChip('+100rb', 100000),
                      _buildQuickAmountChip('+250rb', 250000),
                      _buildQuickAmountChip('+500rb', 500000),
                      _buildQuickAmountChip('+1jt', 1000000),
                    ],
                  ),
                ),
              ),

              // ── Category Selector Header ─────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    t.categoryLabel,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  GestureDetector(
                    onTap: _showAddCustomCategoryDialog,
                    child: Text(
                      t.addCategoryShort,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Category Horizontal List / Wrap
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: currentCategories.map((cat) {
                  final name = cat['name'] as String;
                  final icon = cat['icon'] as IconData;
                  final isSelected = _selectedCategory == name;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = name),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accentWhite
                            : AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.accentWhite
                              : const Color(0x0FFFFFFF),
                        ),
                        boxShadow: isSelected
                            ? const [
                                BoxShadow(
                                  color: Color(0x40FFFFFF),
                                  blurRadius: 10,
                                  offset: Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon,
                            size: 15,
                            color: isSelected
                                ? AppColors.accentBlack
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            name,
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.accentBlack
                                  : AppColors.textSecondary,
                              fontSize: 13,
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
              ).animate().fadeIn(delay: 100.ms, duration: 250.ms),

              const SizedBox(height: 20),

              // ── Payment Method & Date Row ────────────────────
              Row(
                children: [
                  // Payment Method
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.paymentMethodLabel,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildPaymentMethodButton(
                              'cash',
                              t.filterCash,
                              Icons.payments_outlined,
                            ),
                            const SizedBox(width: 8),
                            _buildPaymentMethodButton(
                              'card',
                              t.filterCard,
                              Icons.credit_card_rounded,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Date Picker Button
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.dateLabel,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _pickDate,
                          child: NeumorphicContainer(
                            isPressed: true,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 11,
                            ),
                            borderRadius: 12,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 14,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    DateFormat('dd MMM yyyy')
                                        .format(_selectedDate),
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 150.ms, duration: 250.ms),

              const SizedBox(height: 18),

              // ── Catatan / Note Field ─────────────────────────
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
                    fontSize: 13.5,
                  ),
                  decoration: InputDecoration(
                    hintText: t.noteHint,
                    hintStyle: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                    icon: Icon(
                      Icons.edit_note_rounded,
                      color: AppColors.textMuted,
                      size: 22,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 250.ms),

              const SizedBox(height: 24),

              // ── Simpan Button (White Pill CTA) ───────────────
              GestureDetector(
                    onTap: _isLoading ? null : _saveTransaction,
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
                            : Text(
                                widget.transactionToEdit != null
                                    ? t.saveChanges
                                    : '${t.save} ${isExpense ? t.expense : t.income}',
                                style: const TextStyle(
                                  color: AppColors.accentBlack,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 250.ms, duration: 250.ms)
                  .slideY(begin: 0.15),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAmountChip(String label, double value) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => _quickAddAmount(value),
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

  Widget _buildPaymentMethodButton(String method, String label, IconData icon) {
    final isSelected = _paymentMethod == method;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _paymentMethod = method),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surfaceBright : AppColors.surfaceDim,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.textPrimary
                  : const Color(0x0FFFFFFF),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? AppColors.textPrimary : AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
