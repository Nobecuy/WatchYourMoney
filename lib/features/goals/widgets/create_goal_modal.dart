import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:watch_your_money/core/theme/app_colors.dart';
import 'package:watch_your_money/core/theme/neumorphic_container.dart';
import 'package:watch_your_money/core/utils/currency_formatter.dart';
import 'package:watch_your_money/core/widgets/app_button.dart';
import 'package:watch_your_money/core/widgets/app_text_field.dart';
import 'package:watch_your_money/core/widgets/app_constants.dart';
import 'package:watch_your_money/core/utils/dynamic_island_alert.dart';
import 'package:watch_your_money/features/auth/auth_provider.dart';
import 'package:watch_your_money/features/goals/models/goal_model.dart';
import 'package:watch_your_money/features/dashboard/dashboard_provider.dart';
import 'package:watch_your_money/core/i18n/app_translations.dart';

// ============================================================
// CREATE / EDIT GOAL MODAL
// ============================================================

class CreateGoalModal extends ConsumerStatefulWidget {
  final CurrencyFormatter fmt;
  final AppTranslations t;
  final GoalModel? existingGoal;
  final VoidCallback onSaved;

  const CreateGoalModal({
    super.key,
    required this.fmt,
    required this.t,
    this.existingGoal,
    required this.onSaved,
  });

  @override
  ConsumerState<CreateGoalModal> createState() => _CreateGoalModalState();
}

class _CreateGoalModalState extends ConsumerState<CreateGoalModal>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _initialAmountController = TextEditingController();

  DateTime? _targetDate;
  String _selectedCategory = 'savings';
  bool _isLoading = false;

  String? _targetAmountError;
  String? _initialAmountError;

  late final AnimationController _entranceController;
  late final Animation<double> _entranceAnimation;

  static const Color _cardColor = Color(0xFF191A20);
  static const Color _borderColor = Color(0xFF30313A);
  static const Color _accentColor = Color(0xFFBE9AFF);

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _entranceAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );

    _entranceController.forward();

    final goal = widget.existingGoal;

    if (goal != null) {
      _titleController.text = goal.title;
      _targetAmountController.text = widget.fmt.format(goal.targetAmount);
      _initialAmountController.text = widget.fmt.format(goal.initialAmount);
      _targetDate = goal.targetDate;
      _selectedCategory = goal.category;
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _titleController.dispose();
    _targetAmountController.dispose();
    _initialAmountController.dispose();
    super.dispose();
  }

  double _getNumericValue(String text) {
    return NumericValue(text).numericValue;
  }

  void _validateTargetAmount(double value) {
    setState(() {
      _targetAmountError = value <= 0 ? widget.t.enterValidTargetAmount : null;
    });
  }

  void _validateInitialAmount(double value) {
    setState(() {
      _initialAmountError = value < 0 ? 'Nominal tidak boleh negatif' : null;
    });
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Future<void> _pickTargetDate() async {
    final now = _dateOnly(DateTime.now());
    final existingDate = _targetDate;

    final initialDate =
        existingDate != null && !_dateOnly(existingDate).isBefore(now)
        ? _dateOnly(existingDate)
        : now.add(const Duration(days: 30));

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: DateTime(now.year + 10, now.month, now.day),
      builder: (context, child) {
        final base = Theme.of(context);

        return Theme(
          data: base.copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFBE9AFF),
              onPrimary: Color(0xFF191A20),
              surface: Color(0xFF191A20),
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF191A20),
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null && mounted) {
      setState(() => _targetDate = date);
    }
  }

  Future<void> _saveGoal() async {
    if (_isLoading) return;

    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) return;

    if (_targetDate == null) {
      context.showDynamicIslandError(widget.t.targetDateRequired);
      return;
    }

    if (_targetAmountError != null || _initialAmountError != null) {
      return;
    }

    final targetAmount = _getNumericValue(_targetAmountController.text);
    final initialAmount = _getNumericValue(_initialAmountController.text);

    if (targetAmount <= 0) {
      setState(() {
        _targetAmountError = widget.t.enterValidTargetAmount;
      });
      return;
    }

    if (initialAmount < 0) {
      setState(() {
        _initialAmountError = 'Nominal tidak boleh negatif';
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(goalRepositoryProvider);
      final authState = ref.read(authProvider);
      final userId = authState.user?.id ?? '';
      final existing = widget.existingGoal;

      final goal = GoalModel(
        id: existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        title: _titleController.text.trim(),
        targetAmount: targetAmount,
        currentAmount: existing?.currentAmount ?? initialAmount,
        category: _selectedCategory,
        targetDate: _targetDate!,
        initialAmount: initialAmount,
        status: existing?.status ?? 'active',
        createdAt: existing?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (existing != null) {
        await repository.updateGoal(goal);
      } else {
        await repository.addGoal(goal);
      }

      if (!mounted) return;

      widget.onSaved();

      context.showDynamicIslandSuccess(
        existing != null ? widget.t.goalUpdated : widget.t.goalSaved,
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        context.showDynamicIslandError('${widget.t.failedToUpdateBalance}: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingGoal != null;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedBuilder(
      animation: _entranceAnimation,
      builder: (context, child) {
        final progress = _entranceAnimation.value;

        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - progress)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboardInset),
        child: NeumorphicContainer(
          borderRadius: 28,
          backgroundColor: AppColors.surfaceContainer,
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDragHandle(),
                    const SizedBox(height: 8),

                    _buildHeader(isEditing),
                    const SizedBox(height: 24),

                    _buildSectionLabel('INFORMASI TARGET'),
                    const SizedBox(height: 12),

                    AppTextField(
                      controller: _titleController,
                      label: widget.t.goalTitle,
                      hintText: 'Contoh: Laptop baru',
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama target wajib diisi';
                        }

                        if (value.trim().length < 3) {
                          return 'Nama target minimal 3 karakter';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: AppSpacing.md),

                    AppCurrencyTextField(
                      controller: _targetAmountController,
                      label: widget.t.goalTargetAmount,
                      hintText: 'Rp 0',
                      onAmountChanged: _validateTargetAmount,
                    ),

                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      child: _targetAmountError == null
                          ? const SizedBox.shrink()
                          : _buildError(_targetAmountError!),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    AppCurrencyTextField(
                      controller: _initialAmountController,
                      label: widget.t.goalInitialAmount,
                      hintText: 'Rp 0 (opsional)',
                      onAmountChanged: _validateInitialAmount,
                    ),

                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      child: _initialAmountError == null
                          ? const SizedBox.shrink()
                          : _buildError(_initialAmountError!),
                    ),

                    const SizedBox(height: 24),

                    _buildSectionLabel('KATEGORI'),
                    const SizedBox(height: 12),
                    _buildCategorySelector(),

                    const SizedBox(height: 24),

                    _buildSectionLabel('BATAS WAKTU'),
                    const SizedBox(height: 12),
                    _buildTargetDatePicker(),

                    const SizedBox(height: 24),

                    _buildActionButtons(isEditing),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        width: 38,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.surfaceBright,
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isEditing) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: _accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: _accentColor.withValues(alpha: 0.20)),
          ),
          child: const Icon(Icons.flag_rounded, color: _accentColor, size: 23),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? widget.t.editGoal : widget.t.createGoal,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                isEditing
                    ? widget.t.goalDetail
                    : 'Rencanakan target keuanganmu.',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildError(String message) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.negative,
            size: 13,
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.negative, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: GoalModel.categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = GoalModel.categories[index];
          final value = category['value'] as String;
          final color = category['color'] as Color;
          final icon = category['icon'] as IconData;
          final label = category['label'] as String;
          final selected = _selectedCategory == value;

          return _AnimatedCategoryTile(
            value: value,
            label: label,
            icon: icon,
            color: color,
            selected: selected,
            onTap: () {
              if (_selectedCategory == value) return;

              setState(() => _selectedCategory = value);
            },
          );
        },
      ),
    );
  }

  Widget _buildTargetDatePicker() {
    final hasDate = _targetDate != null;
    final date = _targetDate;

    final dateLabel = date == null
        ? 'Pilih tanggal target'
        : '${date.day.toString().padLeft(2, '0')}/'
              '${date.month.toString().padLeft(2, '0')}/'
              '${date.year}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _pickTargetDate,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: hasDate
                  ? _accentColor.withValues(alpha: 0.35)
                  : _borderColor,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: hasDate
                      ? _accentColor.withValues(alpha: 0.13)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  color: hasDate ? _accentColor : AppColors.textMuted,
                  size: 21,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.t.goalTargetDate,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Text(
                        dateLabel,
                        key: ValueKey(dateLabel),
                        style: TextStyle(
                          color: hasDate
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                          fontSize: 14,
                          fontWeight: hasDate
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
                size: 21,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isEditing) {
    return Row(
      children: [
        Expanded(
          child: AppButtonGhost(
            label: widget.t.cancel,
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            size: AppButtonSize.large,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: AppButtonPrimary(
            label: isEditing ? widget.t.saveChanges : widget.t.save,
            onPressed: _isLoading ? null : _saveGoal,
            isLoading: _isLoading,
            size: AppButtonSize.large,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// ANIMATED CATEGORY TILE
// ============================================================

class _AnimatedCategoryTile extends StatelessWidget {
  const _AnimatedCategoryTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: selected ? 1 : 0.97,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            width: 88,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? color.withValues(alpha: 0.13)
                  : const Color(0xFF191A20),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: selected
                    ? color.withValues(alpha: 0.85)
                    : const Color(0xFF30313A),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: selected
                        ? color.withValues(alpha: 0.16)
                        : Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    icon,
                    color: selected ? color : AppColors.textMuted,
                    size: 19,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontSize: 10,
                    height: 1.1,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 5),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: selected ? 15 : 0,
                  height: 2,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ADD SAVINGS MODAL
// ============================================================

class AddSavingsModal extends ConsumerStatefulWidget {
  final GoalModel goal;
  final CurrencyFormatter fmt;
  final AppTranslations t;
  final VoidCallback onSaved;

  const AddSavingsModal({
    super.key,
    required this.goal,
    required this.fmt,
    required this.t,
    required this.onSaved,
  });

  @override
  ConsumerState<AddSavingsModal> createState() => _AddSavingsModalState();
}

class _AddSavingsModalState extends ConsumerState<AddSavingsModal>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  bool _isLoading = false;
  String? _amountError;

  late final AnimationController _entranceController;
  late final Animation<double> _entranceAnimation;

  static const Color _cardColor = Color(0xFF191A20);
  static const Color _borderColor = Color(0xFF30313A);

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _entranceAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  double _getNumericValue(String text) {
    return NumericValue(text).numericValue;
  }

  void _validateAmount(double value) {
    setState(() {
      _amountError = value <= 0 ? widget.t.enterValidSavingsAmount : null;
    });
  }

  void _setQuickAmount(double amount) {
    _amountController.text = widget.fmt.format(amount);

    setState(() {
      _amountError = null;
    });
  }

  Future<void> _addSavings() async {
    if (_isLoading) return;

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final amount = _getNumericValue(_amountController.text);

    if (amount <= 0) {
      setState(() {
        _amountError = widget.t.enterValidSavingsAmount;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(goalRepositoryProvider);

      await repository.addSavings(widget.goal.id, amount);

      if (!mounted) return;

      widget.onSaved();

      context.showDynamicIslandSuccess(widget.t.savingsAdded);

      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        context.showDynamicIslandError('Gagal menambah tabungan: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = GoalModel.getCategoryColor(widget.goal.category);

    final progress = widget.goal.progress.clamp(0.0, 1.0);
    final remaining = (widget.goal.targetAmount - widget.goal.currentAmount)
        .clamp(0.0, double.infinity);

    return AnimatedBuilder(
      animation: _entranceAnimation,
      builder: (context, child) {
        final value = _entranceAnimation.value;

        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: NeumorphicContainer(
          borderRadius: 28,
          backgroundColor: AppColors.surfaceContainer,
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDragHandle(),
                    const SizedBox(height: 20),

                    _buildGoalSummary(categoryColor, progress, remaining),

                    const SizedBox(height: 28),

                    const Text(
                      'TAMBAH NOMINAL',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    AppCurrencyTextField(
                      controller: _amountController,
                      label: widget.t.savingsAmount,
                      hintText: 'Rp 0',
                      autofocus: true,
                      onAmountChanged: _validateAmount,
                    ),

                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      child: _amountError == null
                          ? const SizedBox.shrink()
                          : Padding(
                              padding: const EdgeInsets.only(top: 6, left: 4),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    color: AppColors.negative,
                                    size: 13,
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      _amountError!,
                                      style: const TextStyle(
                                        color: AppColors.negative,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),

                    const SizedBox(height: 22),

                    const Text(
                      'NOMINAL CEPAT',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [50000.0, 100000.0, 200000.0, 500000.0].map((
                        amount,
                      ) {
                        return _QuickAmountChip(
                          label: '+${widget.fmt.compact(amount)}',
                          onTap: _isLoading
                              ? null
                              : () => _setQuickAmount(amount),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 28),

                    Row(
                      children: [
                        Expanded(
                          child: AppButtonGhost(
                            label: widget.t.cancel,
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.of(context).pop(),
                            size: AppButtonSize.large,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: AppButtonPrimary(
                            label: widget.t.addSavings,
                            onPressed: _isLoading ? null : _addSavings,
                            isLoading: _isLoading,
                            size: AppButtonSize.large,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        width: 38,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.surfaceBright,
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }

  Widget _buildGoalSummary(
    Color categoryColor,
    double progress,
    double remaining,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  GoalModel.getCategoryIcon(widget.goal.category),
                  color: categoryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.goal.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Progres target saat ini',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: progress),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return SizedBox(
                    width: 48,
                    height: 48,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox.expand(
                          child: CircularProgressIndicator(
                            value: value,
                            strokeWidth: 4,
                            strokeCap: StrokeCap.round,
                            backgroundColor: AppColors.surfaceContainerLow,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              categoryColor,
                            ),
                          ),
                        ),
                        Text(
                          '${(value * 100).round()}%',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TERKUMPUL',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.fmt.format(widget.goal.currentAmount),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'TARGET',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    widget.fmt.format(widget.goal.targetAmount),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 15),

          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progress),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 5,
                  backgroundColor: AppColors.surfaceContainerLow,
                  valueColor: AlwaysStoppedAnimation<Color>(categoryColor),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          Text(
            remaining <= 0
                ? 'Target sudah tercapai.'
                : 'Kurang ${widget.fmt.format(remaining)} lagi untuk mencapai target.',
            style: TextStyle(
              color: remaining <= 0 ? categoryColor : AppColors.textMuted,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// QUICK AMOUNT CHIP
// ============================================================

class _QuickAmountChip extends StatelessWidget {
  const _QuickAmountChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
          decoration: BoxDecoration(
            color: const Color(0xFF191A20),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: const Color(0xFF30313A)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, color: Color(0xFF45D6A0), size: 14),
              const SizedBox(width: 4),
              Text(
                label.startsWith('+') ? label.substring(1) : label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
