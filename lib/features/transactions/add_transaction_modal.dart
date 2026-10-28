import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import 'package:watch_your_money/core/i18n/app_translations.dart';
import 'package:watch_your_money/core/settings/settings_provider.dart';
import 'package:watch_your_money/core/theme/app_colors.dart';
import 'package:watch_your_money/core/theme/neumorphic_container.dart';
import 'package:watch_your_money/core/utils/currency_formatter.dart';
import 'package:watch_your_money/core/utils/custom_dialog.dart';
import 'package:watch_your_money/core/utils/dynamic_island_alert.dart';
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
  late String _type;
  late String _paymentMethod;
  late String _selectedCategory;

  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  final List<Map<String, dynamic>> _expenseCategories = [
    {'name': 'Makanan', 'icon': Icons.restaurant_rounded},
    {'name': 'Transportasi', 'icon': Icons.directions_car_rounded},
    {'name': 'Belanja', 'icon': Icons.shopping_bag_rounded},
    {'name': 'Tagihan', 'icon': Icons.receipt_long_rounded},
    {'name': 'Hiburan', 'icon': Icons.movie_rounded},
    {'name': 'Kesehatan', 'icon': Icons.health_and_safety_rounded},
    {'name': 'Edukasi', 'icon': Icons.school_rounded},
    {'name': 'Investasi', 'icon': Icons.trending_up_rounded},
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

  bool get _isExpense => _type == 'expense';

  List<Map<String, dynamic>> get _currentCategories =>
      _isExpense ? _expenseCategories : _incomeCategories;

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

      _amountController.value = formatted;
      _noteController.text = editTx.note;
      _selectedDate = editTx.date;
      _selectedCategory = editTx.categoryId;

      final categoryExists = _currentCategories.any(
        (category) =>
            (category['name'] as String).toLowerCase() ==
            _selectedCategory.toLowerCase(),
      );

      if (!categoryExists) {
        _currentCategories.insert(0, {
          'name': _selectedCategory,
          'icon': Icons.label_outline_rounded,
        });
      }
    } else {
      _type = widget.initialType;
      _paymentMethod = widget.initialPaymentMethod ?? 'cash';
      _selectedCategory = _currentCategories.first['name'] as String;
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
      _selectedCategory = _currentCategories.first['name'] as String;
    });
  }

  void _quickAddAmount(double value) {
    final current = _amountController.text.numericValue;
    final updated = current + value;

    final formatted = ThousandsSeparatorInputFormatter().formatEditUpdate(
      TextEditingValue.empty,
      TextEditingValue(text: updated.toInt().toString()),
    );

    _amountController.value = formatted;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        final baseTheme = Theme.of(context);

        return Theme(
          data: baseTheme.copyWith(
            colorScheme: baseTheme.colorScheme.copyWith(
              primary: AppColors.accentWhite,
              onPrimary: AppColors.accentBlack,
              surface: AppColors.surfaceContainerHigh,
              onSurface: AppColors.textPrimary,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: AppColors.surfaceContainer,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  void _showAddCustomCategoryDialog() {
    final t = AppTranslations.of(ref.read(appSettingsProvider).languageCode);

    showCustomInputDialog(
      context: context,
      title: t.addCategory,
      hintText: t.categoryName,
      confirmText: t.save,
      cancelText: t.cancel,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Nama kategori tidak boleh kosong';
        }
        return null;
      },
    ).then((category) {
      if (category == null || category.trim().isEmpty || !mounted) return;

      final name = category.trim();

      setState(() {
        final exists = _currentCategories.any(
          (item) =>
              (item['name'] as String).toLowerCase() == name.toLowerCase(),
        );

        if (!exists) {
          _currentCategories.insert(0, {
            'name': name,
            'icon': Icons.label_outline_rounded,
          });
        }

        _selectedCategory = name;
      });
    });
  }

  Future<void> _deleteThisTransaction() async {
    final t = AppTranslations.of(ref.read(appSettingsProvider).languageCode);

    final confirmed = await showCustomConfirm(
      context: context,
      title: t.deleteTransaction,
      message: t.confirmDelete,
      confirmText: t.delete,
      cancelText: t.cancel,
      isDestructive: true,
      icon: Icons.delete_outline_rounded,
      iconColor: AppColors.negativeLight,
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(transactionRepositoryProvider)
          .deleteTransaction(widget.transactionToEdit!.id);

      ref.invalidate(transactionsProvider);

      if (!mounted) return;

      Navigator.pop(context);
      context.showDynamicIslandSuccess(t.txDeleted);
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      context.showDynamicIslandError('Gagal menghapus transaksi: $e');
    }
  }

  Future<void> _saveTransaction() async {
    final t = AppTranslations.of(ref.read(appSettingsProvider).languageCode);

    final amount = _amountController.text.numericValue;

    if (amount <= 0) {
      context.showDynamicIslandError(t.enterValidAmount);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final isEdit = widget.transactionToEdit != null;

      double balanceBefore = 0;
      double balanceAfter = 0;

      if (!isEdit) {
        final transactions = await ref
            .read(transactionRepositoryProvider)
            .getTransactions();

        double income = 0;
        double expense = 0;

        for (final tx in transactions) {
          if (tx.paymentMethod != _paymentMethod) continue;

          if (tx.type == 'income') {
            income += tx.amount;
          } else {
            expense += tx.amount;
          }
        }

        balanceBefore = income - expense;
        balanceAfter = _type == 'income'
            ? balanceBefore + amount
            : balanceBefore - amount;
      } else {
        balanceBefore = widget.transactionToEdit!.balanceBefore;
        balanceAfter = widget.transactionToEdit!.balanceAfter;
      }

      final transaction = TransactionModel(
        id: isEdit ? widget.transactionToEdit!.id : const Uuid().v4(),
        amount: amount,
        type: _type,
        categoryId: _selectedCategory,
        note: _noteController.text.trim(),
        date: _selectedDate,
        paymentMethod: _paymentMethod,
        balanceBefore: balanceBefore,
        balanceAfter: balanceAfter,
      );

      if (isEdit) {
        await ref
            .read(transactionRepositoryProvider)
            .updateTransaction(transaction);
      } else {
        await ref
            .read(transactionRepositoryProvider)
            .addTransaction(transaction);
      }

      ref.invalidate(transactionsProvider);

      if (!mounted) return;

      Navigator.pop(context);
      context.showDynamicIslandSuccess(isEdit ? t.txUpdated : t.txSaved);
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      context.showDynamicIslandError('Gagal menyimpan: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final fmt = CurrencyFormatter.from(settings);
    final t = AppTranslations.of(settings.languageCode);

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(maxHeight: screenHeight * 0.94),
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHandle(),
                      const SizedBox(height: 5),
                      _buildHeader(t),
                      const SizedBox(height: 14),
                      _buildTypeSelector(t),
                      const SizedBox(height: 14),
                      _buildAmountCard(fmt),
                      const SizedBox(height: 8),
                      _buildQuickAmounts(),
                      const SizedBox(height: 16),
                      _buildPaymentSection(t),
                      const SizedBox(height: 16),
                      _buildCategorySection(t),
                      const SizedBox(height: 16),
                      _buildDateAndNoteSection(t),
                    ],
                  ),
                ),
              ),

              // CTA tetap berada di bawah saat konten di-scroll.
              Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 16,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: _buildSaveButton(t),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        width: 34,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.surfaceBright,
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }

  Widget _buildHeader(dynamic t) {
    final isEdit = widget.transactionToEdit != null;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      isEdit ? t.editTransaction : 'Tambah Transaksi',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.35,
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const Text(
                      'WATCH UI',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              const Text(
                'Catat arus kas masuk & keluar presisi',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (isEdit) ...[
          _roundIconButton(
            icon: Icons.delete_outline_rounded,
            color: AppColors.negativeLight,
            onTap: _isLoading ? null : _deleteThisTransaction,
          ),
          const SizedBox(width: 7),
        ],
        _roundIconButton(
          icon: Icons.close_rounded,
          color: AppColors.textSecondary,
          onTap: _isLoading ? null : () => Navigator.pop(context),
        ),
      ],
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _roundIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: AppColors.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }

  Widget _buildTypeSelector(dynamic t) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0x12FFFFFF)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _typeOption(
              label: t.expense,
              icon: Icons.arrow_upward_rounded,
              selected: _isExpense,
              selectedColor: const Color(0xFF25262B),
              iconColor: const Color(0xFFFF6470),
              onTap: () => _switchType('expense'),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _typeOption(
              label: t.income,
              icon: Icons.arrow_downward_rounded,
              selected: !_isExpense,
              selectedColor: const Color(0xFF25262B),
              iconColor: const Color(0xFF00D6A0),
              onTap: () => _switchType('income'),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 220.ms).slideY(begin: 0.06);
  }

  Widget _typeOption({
    required String label,
    required IconData icon,
    required bool selected,
    required Color selectedColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: selected ? selectedColor : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? const Color(0x22FFFFFF) : Colors.transparent,
        ),
        boxShadow: selected
            ? const [
                BoxShadow(
                  color: Color(0x44000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 13,
                  color: selected ? iconColor : AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountCard(CurrencyFormatter fmt) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 13),
      decoration: BoxDecoration(
        color: const Color(0xFF101114),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x12FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'NOMINAL TRANSAKSI',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 9,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: _isExpense
                      ? const Color(0xFF39191D)
                      : const Color(0xFF10332B),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  _isExpense ? 'EXPENSE (-)' : 'INCOME (+)',
                  style: TextStyle(
                    color: _isExpense
                        ? const Color(0xFFFF6872)
                        : const Color(0xFF00D6A0),
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                fmt.symbol,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  autofocus: false,
                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 29,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
                    height: 1.15,
                  ),
                  cursorColor: AppColors.accentWhite,
                  decoration: const InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 29,
                    ),
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
    ).animate().fadeIn(delay: 40.ms, duration: 240.ms);
  }

  Widget _buildQuickAmounts() {
    const amounts = [
      ('+50rb', 50000.0),
      ('+100rb', 100000.0),
      ('+250rb', 250000.0),
      ('+500rb', 500000.0),
      ('+1jt', 1000000.0),
    ];

    return Row(
      children: [
        for (final amount in amounts)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _quickAmountChip(amount.$1, amount.$2),
            ),
          ),
      ],
    );
  }

  Widget _quickAmountChip(String label, double value) {
    return Material(
      color: AppColors.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        onTap: _isLoading ? null : () => _quickAddAmount(value),
        borderRadius: BorderRadius.circular(7),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: const Color(0x12FFFFFF)),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String title, {Widget? trailing}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.65,
            ),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildPaymentSection(dynamic t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(
          t.paymentMethodLabel,
          trailing: const Text(
            'PILIH SUMBER DANA',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 8,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _paymentMethodCard(
                method: 'cash',
                title: t.filterCash,
                subtitle: 'Dompet fisik',
                icon: Icons.payments_outlined,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _paymentMethodCard(
                method: 'card',
                title: t.filterCard,
                subtitle: 'Kartu / Debit',
                icon: Icons.credit_card_rounded,
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 70.ms, duration: 240.ms);
  }

  Widget _paymentMethodCard({
    required String method,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final selected = _paymentMethod == method;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.surfaceContainerHigh
            : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? const Color(0x20FFFFFF) : const Color(0x0AFFFFFF),
        ),
        boxShadow: selected
            ? const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading
              ? null
              : () => setState(() => _paymentMethod = method),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: selected ? AppColors.textPrimary : AppColors.textMuted,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF00D6A0)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection(dynamic t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(
          t.categoryLabel,
          trailing: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isLoading ? null : _showAddCustomCategoryDialog,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.add_rounded,
                      size: 12,
                      color: AppColors.textPrimary,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      t.addCategoryShort,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _currentCategories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 6,
            mainAxisSpacing: 7,
            mainAxisExtent: 35,
          ),
          itemBuilder: (context, index) {
            final category = _currentCategories[index];
            final name = category['name'] as String;
            final icon = category['icon'] as IconData;
            final selected = _selectedCategory == name;

            return _categoryTile(
              name: name,
              icon: icon,
              selected: selected,
              onTap: _isLoading
                  ? null
                  : () => setState(() => _selectedCategory = name),
            );
          },
        ),
      ],
    ).animate().fadeIn(delay: 100.ms, duration: 240.ms);
  }

  Widget _categoryTile({
    required String name,
    required IconData icon,
    required bool selected,
    required VoidCallback? onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: selected ? AppColors.accentWhite : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: selected ? AppColors.accentWhite : const Color(0x0FFFFFFF),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 13,
                  color: selected
                      ? AppColors.accentBlack
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected
                          ? AppColors.accentBlack
                          : AppColors.textSecondary,
                      fontSize: 9,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateAndNoteSection(dynamic t) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel(t.dateLabel),
              const SizedBox(height: 6),
              Material(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: _isLoading ? null : _pickDate,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 39,
                    padding: const EdgeInsets.symmetric(horizontal: 9),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0x0FFFFFFF)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            DateFormat(
                              'dd MMM yyyy',
                              'id_ID',
                            ).format(_selectedDate),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
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
        const SizedBox(width: 7),
        Expanded(
          flex: 6,
          child: Column(
            children: [
              const SizedBox(height: 15),
              Container(
                height: 39,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0x0FFFFFFF)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.edit_note_rounded,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        controller: _noteController,
                        textInputAction: TextInputAction.done,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 10,
                        ),
                        decoration: InputDecoration(
                          hintText: t.noteHint,
                          hintStyle: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 9,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 130.ms, duration: 240.ms);
  }

  Widget _buildSaveButton(dynamic t) {
    final isEdit = widget.transactionToEdit != null;

    return SizedBox(
      height: 43,
      width: double.infinity,
      child: Material(
        color: AppColors.accentWhite,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: _isLoading ? null : _saveTransaction,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _isLoading
                ? const Center(
                    key: ValueKey('loading'),
                    child: SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accentBlack,
                      ),
                    ),
                  )
                : Row(
                    key: const ValueKey('label'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          isEdit
                              ? t.saveChanges
                              : 'Simpan ${_isExpense ? t.expense : t.income}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.accentBlack,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 15,
                        color: AppColors.accentBlack,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 160.ms, duration: 220.ms);
  }
}
