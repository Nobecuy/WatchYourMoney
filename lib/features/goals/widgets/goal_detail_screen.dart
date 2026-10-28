import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:watch_your_money/core/theme/app_colors.dart';
import 'package:watch_your_money/core/theme/neumorphic_container.dart';
import 'package:watch_your_money/core/utils/currency_formatter.dart';
import 'package:watch_your_money/core/widgets/app_button.dart';
import 'package:watch_your_money/core/widgets/app_constants.dart';
import 'package:watch_your_money/core/utils/dynamic_island_alert.dart';
import 'package:watch_your_money/features/dashboard/dashboard_provider.dart';
import 'package:watch_your_money/features/goals/models/goal_model.dart';
import 'package:watch_your_money/features/goals/widgets/create_goal_modal.dart';
import 'package:watch_your_money/core/i18n/app_translations.dart';
import 'package:watch_your_money/core/settings/settings_provider.dart';

class GoalDetailScreen extends ConsumerStatefulWidget {
  final GoalModel goal;

  const GoalDetailScreen({super.key, required this.goal});

  @override
  ConsumerState<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends ConsumerState<GoalDetailScreen> {
  late GoalModel _goal;
  List<Map<String, dynamic>> _contributions = [];

  @override
  void initState() {
    super.initState();
    _goal = widget.goal;
    _loadContributions();
  }

  // Placeholder riwayat kontribusi.
  // Nantinya hubungkan dengan data kontribusi dari database.
  void _loadContributions() {
    if (!mounted) return;

    setState(() {
      _contributions = [
        if (_goal.initialAmount > 0)
          {
            'amount': _goal.initialAmount,
            'date': _goal.createdAt,
            'note': 'Saldo awal target',
          },
        if (_goal.currentAmount > _goal.initialAmount)
          {
            'amount': _goal.currentAmount - _goal.initialAmount,
            'date': _goal.updatedAt ?? _goal.createdAt,
            'note': 'Kontribusi tabungan',
          },
      ];
    });
  }

  Future<void> _handleCompleteGoal() async {
    try {
      final repository = ref.read(goalRepositoryProvider);

      final updatedGoal = _goal.copyWith(
        status: 'completed',
        updatedAt: DateTime.now(),
      );

      await repository.updateGoal(updatedGoal);

      if (!mounted) return;

      context.showDynamicIslandSuccess('Target diselesaikan!');
      ref.invalidate(goalsProvider);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      context.showDynamicIslandError('Gagal menyelesaikan target: $e');
    }
  }

  Future<void> _handleArchiveGoal() async {
    try {
      final repository = ref.read(goalRepositoryProvider);

      final updatedGoal = _goal.copyWith(
        status: 'archived',
        updatedAt: DateTime.now(),
      );

      await repository.updateGoal(updatedGoal);

      if (!mounted) return;

      context.showDynamicIslandSuccess('Target diarsipkan');
      ref.invalidate(goalsProvider);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      context.showDynamicIslandError('Gagal mengarsipkan: $e');
    }
  }

  Future<void> _handleDeleteGoal() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: const Icon(
          Icons.delete_outline_rounded,
          color: AppColors.negative,
          size: 30,
        ),
        title: const Text(
          'Hapus Target?',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: const Text(
          'Target ini akan dihapus permanen.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              'Batal',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Hapus',
              style: TextStyle(color: AppColors.negative),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final repository = ref.read(goalRepositoryProvider);
      await repository.deleteGoal(_goal.id);

      if (!mounted) return;

      context.showDynamicIslandSuccess('Target dihapus');
      ref.invalidate(goalsProvider);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      context.showDynamicIslandError('Gagal menghapus: $e');
    }
  }

  void _showEditModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateGoalModal(
        fmt: CurrencyFormatter.from(ref.read(settingsProvider)),
        t: AppTranslations.of(ref.read(settingsProvider).languageCode),
        existingGoal: _goal,
        onSaved: () {
          ref.invalidate(goalsProvider);
        },
      ),
    );
  }

  void _showAddSavingsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddSavingsModal(
        goal: _goal,
        fmt: CurrencyFormatter.from(ref.read(settingsProvider)),
        t: AppTranslations.of(ref.read(settingsProvider).languageCode),
        onSaved: () {
          ref.invalidate(goalsProvider);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final fmt = CurrencyFormatter.from(settings);
    final t = AppTranslations.of(settings.languageCode);

    final categoryColor = GoalModel.getCategoryColor(_goal.category);
    final categoryIcon = GoalModel.getCategoryIcon(_goal.category);
    final isCompleted = _goal.status == 'completed';
    final isArchived = _goal.status == 'archived';
    final progress = _goal.progress.clamp(0.0, 1.0).toDouble();

    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 310,
            pinned: true,
            backgroundColor: AppColors.surfaceCanvas,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimary,
              ),
            ),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.textPrimary,
                ),
                color: AppColors.surfaceContainerHigh,
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _showEditModal();
                      break;
                    case 'complete':
                      _handleCompleteGoal();
                      break;
                    case 'archive':
                      _handleArchiveGoal();
                      break;
                    case 'delete':
                      _handleDeleteGoal();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.edit_rounded,
                          size: 18,
                          color: AppColors.textPrimary,
                        ),
                        const SizedBox(width: 12),
                        Text(t.editGoal),
                      ],
                    ),
                  ),
                  if (!isCompleted && !isArchived)
                    PopupMenuItem(
                      value: 'complete',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 18,
                            color: AppColors.positive,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            t.completeGoal,
                            style: const TextStyle(color: AppColors.positive),
                          ),
                        ],
                      ),
                    ),
                  if (!isArchived)
                    PopupMenuItem(
                      value: 'archive',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.archive_outlined,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 12),
                          Text(t.archiveGoal),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: AppColors.negative,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          t.deleteGoal,
                          style: const TextStyle(color: AppColors.negative),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      categoryColor.withValues(alpha: 0.18),
                      AppColors.surfaceCanvas,
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: categoryColor.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(17),
                                border: Border.all(
                                  color: categoryColor.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Icon(
                                categoryIcon,
                                color: categoryColor,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _goal.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 21,
                                      height: 1.2,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    _goal.categoryDisplayName,
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildStatusChip(_goal, t),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 78,
                              height: 78,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox.expand(
                                    child: CircularProgressIndicator(
                                      value: progress,
                                      strokeWidth: 6,
                                      strokeCap: StrokeCap.round,
                                      backgroundColor:
                                          AppColors.surfaceContainerLow,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        isCompleted
                                            ? AppColors.positive
                                            : categoryColor,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${(progress * 100).round()}%',
                                    style: TextStyle(
                                      color: isCompleted
                                          ? AppColors.positive
                                          : categoryColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'PROGRES TERKUMPUL',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    fmt.format(_goal.currentAmount),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 20,
                                      height: 1.15,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'dari ${fmt.format(_goal.targetAmount)}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (!isCompleted) ...[
                                    const SizedBox(height: 7),
                                    Text(
                                      'Kurang ${fmt.format(_goal.remainingAmount)}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: _goal.isOverdue
                                            ? AppColors.negative
                                            : AppColors.textSecondary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
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

          // Main content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section heading
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'RINGKASAN TARGET',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          '${(progress * 100).round()}% tercapai',
                          style: TextStyle(
                            color: categoryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 250.ms),

                  const SizedBox(height: 12),

                  // Three information cards.
                  // Two cards side-by-side and one full-width card.
                  LayoutBuilder(
                        builder: (context, constraints) {
                          final cardWidth = (constraints.maxWidth - 12) / 2;

                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              SizedBox(
                                width: cardWidth,
                                child: _buildInfoTile(
                                  icon: Icons.calendar_month_rounded,
                                  label: t.goalTargetDate,
                                  value:
                                      '${_goal.targetDate.day}/${_goal.targetDate.month}/${_goal.targetDate.year}',
                                  subtitle: _goal.isOverdue && !isCompleted
                                      ? t.goalOverdue
                                      : '${_goal.daysRemaining} ${t.goalDaysRemaining}',
                                  color: _goal.isOverdue && !isCompleted
                                      ? AppColors.negative
                                      : categoryColor,
                                ),
                              ),
                              SizedBox(
                                width: cardWidth,
                                child: _buildInfoTile(
                                  icon: Icons.account_balance_wallet_rounded,
                                  label: t.goalInitialAmount,
                                  value: fmt.format(_goal.initialAmount),
                                  subtitle: 'Dana awal saat target dibuat',
                                  color: categoryColor,
                                ),
                              ),
                              SizedBox(
                                width: constraints.maxWidth,
                                child: _buildInfoTile(
                                  icon: Icons.flag_rounded,
                                  label: 'SISA TARGET',
                                  value: fmt.format(_goal.remainingAmount),
                                  subtitle: isCompleted
                                      ? 'Target sudah tercapai'
                                      : 'Dana yang masih perlu dikumpulkan',
                                  color: isCompleted
                                      ? AppColors.positive
                                      : categoryColor,
                                  horizontal: true,
                                ),
                              ),
                            ],
                          );
                        },
                      )
                      .animate()
                      .fadeIn(delay: 60.ms, duration: 300.ms)
                      .slideY(begin: 0.03),

                  const SizedBox(height: 24),

                  // Primary actions
                  Text(
                    'AKSI TARGET',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 350;

                      if (isCompleted || isArchived) {
                        return SizedBox(
                          width: double.infinity,
                          child: AppButtonOutline(
                            label: t.editGoal,
                            onPressed: _showEditModal,
                            size: AppButtonSize.large,
                            isFullWidth: true,
                          ),
                        );
                      }

                      if (compact) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppButton(
                              icon: Icons.add_rounded,
                              label: t.addSavings,
                              style: AppButtonStyle.primary,
                              onPressed: _showAddSavingsModal,
                              size: AppButtonSize.large,
                              isFullWidth: true,
                            ),
                            const SizedBox(height: 10),
                            AppButtonOutline(
                              label: t.editGoal,
                              onPressed: _showEditModal,
                              size: AppButtonSize.large,
                              isFullWidth: true,
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              icon: Icons.add_rounded,
                              label: t.addSavings,
                              style: AppButtonStyle.primary,
                              onPressed: _showAddSavingsModal,
                              size: AppButtonSize.large,
                              isFullWidth: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppButtonOutline(
                              label: t.editGoal,
                              onPressed: _showEditModal,
                              size: AppButtonSize.large,
                              isFullWidth: true,
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  // Contribution history heading
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.goalHistory.toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Perjalanan dana targetmu',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          '${_contributions.length} aktivitas',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  if (_contributions.isEmpty)
                    _buildEmptyHistory()
                  else
                    ..._contributions.asMap().entries.map((entry) {
                      final index = entry.key;
                      final contribution = entry.value;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child:
                            _buildContributionTile(
                                  contribution: contribution,
                                  fmt: fmt,
                                )
                                .animate()
                                .fadeIn(
                                  delay: (index * 50).ms,
                                  duration: 250.ms,
                                )
                                .slideX(begin: 0.03),
                      );
                    }),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 36)),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
    required Color color,
    bool horizontal = false,
  }) {
    return NeumorphicContainer(
      borderRadius: AppRadii.lg,
      padding: const EdgeInsets.all(14),
      child: horizontal
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoIcon(icon, color),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoText(
                    label: label,
                    value: value,
                    subtitle: subtitle,
                    color: color,
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInfoIcon(icon, color),
                const SizedBox(height: 12),
                _buildInfoText(
                  label: label,
                  value: value,
                  subtitle: subtitle,
                  color: color,
                ),
              ],
            ),
    );
  }

  Widget _buildInfoIcon(IconData icon, Color color) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 19),
    );
  }

  Widget _buildInfoText({
    required String label,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 9,
            height: 1.35,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          value,
          softWrap: true,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            height: 1.3,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          softWrap: true,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 10,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildContributionTile({
    required Map<String, dynamic> contribution,
    required CurrencyFormatter fmt,
  }) {
    final amount = (contribution['amount'] as num).toDouble();
    final date = contribution['date'] as DateTime;
    final note = contribution['note'] as String;

    return NeumorphicContainer(
      borderRadius: AppRadii.lg,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.positive.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.savings_rounded,
              color: AppColors.positive,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(date),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '+${fmt.format(amount)}',
              textAlign: TextAlign.end,
              softWrap: true,
              style: const TextStyle(
                color: AppColors.positive,
                fontSize: 12,
                height: 1.3,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return NeumorphicContainer(
      borderRadius: AppRadii.xl,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.history_rounded,
                color: AppColors.textMuted,
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Belum ada riwayat kontribusi',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Kontribusi yang tercatat akan muncul di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(GoalModel goal, AppTranslations t) {
    late Color backgroundColor;
    late Color foregroundColor;
    late String label;

    switch (goal.status) {
      case 'active':
        if (goal.isOverdue) {
          backgroundColor = AppColors.negative.withValues(alpha: 0.13);
          foregroundColor = AppColors.negative;
          label = t.goalOverdue;
        } else {
          backgroundColor = AppColors.positive.withValues(alpha: 0.12);
          foregroundColor = AppColors.positive;
          label = t.activeGoals;
        }
        break;
      case 'completed':
        backgroundColor = AppColors.positive.withValues(alpha: 0.12);
        foregroundColor = AppColors.positive;
        label = t.goalCompleted;
        break;
      case 'archived':
        backgroundColor = AppColors.textMuted.withValues(alpha: 0.12);
        foregroundColor = AppColors.textMuted;
        label = 'Arsip';
        break;
      default:
        backgroundColor = AppColors.textMuted.withValues(alpha: 0.12);
        foregroundColor = AppColors.textMuted;
        label = goal.status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: foregroundColor.withValues(alpha: 0.15)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
