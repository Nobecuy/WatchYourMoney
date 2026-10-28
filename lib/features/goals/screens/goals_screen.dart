import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:watch_your_money/core/theme/app_colors.dart';
import 'package:watch_your_money/core/theme/neumorphic_container.dart';
import 'package:watch_your_money/core/utils/currency_formatter.dart';
import 'package:watch_your_money/core/widgets/app_button.dart';
import 'package:watch_your_money/core/widgets/app_constants.dart';
import 'package:watch_your_money/features/dashboard/dashboard_provider.dart';
import 'package:watch_your_money/features/goals/models/goal_model.dart';
import 'package:watch_your_money/features/goals/widgets/create_goal_modal.dart';
import 'package:watch_your_money/features/goals/widgets/goal_detail_screen.dart';
import 'package:watch_your_money/core/settings/settings_provider.dart';
import 'package:watch_your_money/core/i18n/app_translations.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedFilter = 0; // 0 = Active, 1 = Completed

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedFilter = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(goalsProvider);
    final settings = ref.watch(settingsProvider);
    final fmt = CurrencyFormatter.from(settings);
    final t = AppTranslations.of(settings.languageCode);

    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.goalsTitle.toUpperCase(),
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.8,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t.emptyStateSubtitle,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    AppButtonIcon(
                      icon: Icons.add_rounded,
                      onPressed: () => _showCreateGoalModal(context, fmt, t),
                      size: AppButtonSize.medium,
                    ),
                  ],
                ).animate().fadeIn(duration: 300.ms),
              ),
            ),

            // ── Summary Stats ────────────────────────────────────────
            goalsAsync.when(
              data: (goals) {
                final activeGoals = goals
                    .where((g) => g.status == 'active')
                    .toList();
                final completedGoals = goals
                    .where((g) => g.status == 'completed')
                    .toList();
                final totalSaved =
                    activeGoals.fold(0.0, (sum, g) => sum + g.currentAmount) +
                    completedGoals.fold(0.0, (sum, g) => sum + g.currentAmount);

                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child:
                        Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    t.activeGoals,
                                    activeGoals.length.toString(),
                                    Icons.flag_rounded,
                                    const Color(0xFF10B981),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatCard(
                                    t.completedGoals,
                                    completedGoals.length.toString(),
                                    Icons.check_circle_rounded,
                                    const Color(0xFF818CF8),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatCard(
                                    t.totalSaved,
                                    fmt.compact(totalSaved),
                                    Icons.savings_rounded,
                                    const Color(0xFFF59E0B),
                                  ),
                                ),
                              ],
                            )
                            .animate()
                            .fadeIn(delay: 100.ms, duration: 300.ms)
                            .slideY(begin: 0.1),
                  ),
                );
              },
              loading: () =>
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
              error: (_, _) =>
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ),

            // ── Filter Tabs ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child:
                    NeumorphicContainer(
                          borderRadius: AppRadii.pill,
                          padding: const EdgeInsets.all(4),
                          backgroundColor: AppColors.surfaceContainerLow,
                          child: TabBar(
                            controller: _tabController,
                            indicator: BoxDecoration(
                              color: AppColors.accentWhite,
                              borderRadius: BorderRadius.circular(
                                AppRadii.pill,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.shadowDarkFloat,
                                  offset: const Offset(2, 2),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            indicatorSize: TabBarIndicatorSize.tab,
                            dividerColor: Colors.transparent,
                            labelColor: AppColors.accentBlack,
                            unselectedLabelColor: AppColors.textMuted,
                            labelStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                            unselectedLabelStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                            tabs: [
                              Tab(text: t.activeGoals),
                              Tab(text: t.completedGoals),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 150.ms, duration: 300.ms)
                        .slideY(begin: 0.1),
              ),
            ),

            // ── Goals List ───────────────────────────────────────────
            goalsAsync.when(
              data: (goals) {
                final filteredGoals = _selectedFilter == 0
                    ? goals.where((g) => g.status == 'active').toList()
                    : goals.where((g) => g.status == 'completed').toList();

                if (goals.isEmpty) {
                  return _buildEmptyState(t, fmt);
                }

                if (filteredGoals.isEmpty) {
                  return _buildEmptyFilteredState(t, fmt);
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final goal = filteredGoals[index];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: _buildGoalCard(goal, index, fmt, t),
                    );
                  }, childCount: filteredGoals.length),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(
                      color: AppColors.accentWhite,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ),
              error: (err, _) => SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text(
                      '$err',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return NeumorphicContainer(
      borderRadius: AppRadii.lg,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Icon(icon, color: color, size: AppSizes.iconSm),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppTranslations t, CurrencyFormatter fmt) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
        child: NeumorphicContainer(
          borderRadius: AppRadii.xl,
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF818CF8).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadii.xl),
                ),
                child: const Icon(
                  Icons.flag_outlined,
                  color: Color(0xFF818CF8),
                  size: 36,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                t.emptyStateTitle,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                t.emptyStateSubtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButtonPrimary(
                label: t.createFirstGoal,
                onPressed: () => _showCreateGoalModal(context, fmt, t),
                isFullWidth: true,
                size: AppButtonSize.large,
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.1),
      ),
    );
  }

  Widget _buildEmptyFilteredState(AppTranslations t, CurrencyFormatter fmt) {
    final isActive = _selectedFilter == 0;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
        child: NeumorphicContainer(
          borderRadius: AppRadii.xl,
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadii.xl),
                ),
                child: Icon(
                  isActive ? Icons.flag_outlined : Icons.check_circle_outline,
                  color: AppColors.textMuted,
                  size: 36,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                isActive ? t.noActiveGoals : t.noGoals,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              if (isActive) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  t.emptyStateSubtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButtonPrimary(
                  label: t.createFirstGoal,
                  onPressed: () => _showCreateGoalModal(context, fmt, t),
                  isFullWidth: true,
                  size: AppButtonSize.large,
                ),
              ],
            ],
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.1),
      ),
    );
  }

  Widget _buildGoalCard(
    GoalModel goal,
    int index,
    CurrencyFormatter fmt,
    AppTranslations t,
  ) {
    final progress = goal.progress;
    final categoryColor = GoalModel.getCategoryColor(goal.category);
    final categoryIcon = GoalModel.getCategoryIcon(goal.category);
    final isCompleted = goal.status == 'completed';
    final isOverdue = goal.isOverdue && !isCompleted;

    return NeumorphicContainer(
      borderRadius: AppRadii.xl,
      padding: const EdgeInsets.all(AppSpacing.lg),
      isPressed: true,
      enablePressAnimation: true,
      onTap: () => _navigateToDetail(goal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with category icon and status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(
                  categoryIcon,
                  color: categoryColor,
                  size: AppSizes.iconMd,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      goal.categoryDisplayName,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusChip(goal, t),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(progress * 100).round()}%',
                    style: TextStyle(
                      color: categoryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${fmt.format(goal.currentAmount)} / ${fmt.format(goal.targetAmount)}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.pill),
                child: SizedBox(
                  height: 6,
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.surfaceContainerLow,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isCompleted ? AppColors.positive : categoryColor,
                    ),
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Footer with remaining amount and days
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (!isCompleted) ...[
                Flexible(
                  child: Text(
                    '${t.goalRemaining}: ${fmt.format(goal.remainingAmount)}',
                    style: TextStyle(
                      color: isOverdue
                          ? AppColors.negative
                          : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                if (!isOverdue)
                  Flexible(
                    child: Text(
                      '${goal.daysRemaining} ${t.goalDaysRemaining}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  )
                else
                  Flexible(
                    child: Text(
                      t.goalOverdue,
                      style: const TextStyle(
                        color: AppColors.negative,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
              ] else ...[
                Flexible(
                  child: Text(
                    t.goalCompleted,
                    style: const TextStyle(
                      color: AppColors.positive,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isCompleted) ...[
                    AppButton(
                      icon: Icons.add_rounded,
                      label: t.addSavings,
                      style: AppButtonStyle.ghost,
                      size: AppButtonSize.small,
                      onPressed: () => _showAddSavingsModal(goal, fmt, t),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  AppButton(
                    icon: Icons.edit_rounded,
                    label: t.editGoal,
                    style: AppButtonStyle.ghost,
                    size: AppButtonSize.small,
                    onPressed: () => _showEditGoalModal(goal, fmt, t),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 50).ms, duration: 300.ms).slideY(begin: 0.05);
  }

  Widget _buildStatusChip(GoalModel goal, AppTranslations t) {
    Color bgColor;
    Color textColor;
    String label;

    switch (goal.status) {
      case 'active':
        if (goal.isOverdue) {
          bgColor = AppColors.negative.withValues(alpha: 0.15);
          textColor = AppColors.negative;
          label = t.goalOverdue;
        } else {
          bgColor = const Color(0xFF10B981).withValues(alpha: 0.15);
          textColor = const Color(0xFF10B981);
          label = t.activeGoals;
        }
        break;
      case 'completed':
        bgColor = AppColors.positive.withValues(alpha: 0.15);
        textColor = AppColors.positive;
        label = t.goalCompleted;
        break;
      case 'archived':
        bgColor = AppColors.textMuted.withValues(alpha: 0.15);
        textColor = AppColors.textMuted;
        label = 'Arsip';
        break;
      default:
        bgColor = AppColors.textMuted.withValues(alpha: 0.15);
        textColor = AppColors.textMuted;
        label = goal.status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _navigateToDetail(GoalModel goal) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => GoalDetailScreen(goal: goal)));
  }

  void _showCreateGoalModal(
    BuildContext context,
    CurrencyFormatter fmt,
    AppTranslations t,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateGoalModal(
        fmt: fmt,
        t: t,
        onSaved: () => ref.invalidate(goalsProvider),
      ),
    );
  }

  void _showEditGoalModal(
    GoalModel goal,
    CurrencyFormatter fmt,
    AppTranslations t,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateGoalModal(
        fmt: fmt,
        t: t,
        existingGoal: goal,
        onSaved: () => ref.invalidate(goalsProvider),
      ),
    );
  }

  void _showAddSavingsModal(
    GoalModel goal,
    CurrencyFormatter fmt,
    AppTranslations t,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddSavingsModal(
        goal: goal,
        fmt: fmt,
        t: t,
        onSaved: () => ref.invalidate(goalsProvider),
      ),
    );
  }
}
