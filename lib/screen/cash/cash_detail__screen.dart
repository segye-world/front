import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/account_record_model.dart';
import '../../models/budget_model.dart';
import '../../routes/routes.dart';
import '../../services/account_record_api.dart';
import '../../services/budget_api.dart';
import '../../services/category_api.dart';
import '../../services/finance_settings_api.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icon_sizes.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/app_dialog.dart';
import '../../widgets/common/app_primary_button.dart';
import '../../widgets/template/app_top_bar.dart';
import '../../widgets/template/bottom_nav_layout.dart';

class CashDetailScreen extends StatefulWidget {
  const CashDetailScreen({super.key});

  @override
  State<CashDetailScreen> createState() => _CashDetailScreenState();
}

class _CashDetailScreenState extends State<CashDetailScreen> {
  static const _primaryPink = AppColors.primaryPink;
  static const _lineNavy = AppColors.navyDark;
  static const _green = AppColors.incomeAccent;
  static const _red = AppColors.expenseAccent;
  static const _blue = AppColors.chartBlue;
  static const _purple = AppColors.chartPurple;

  List<AccountRecordModel> _recentRecords = [];
  Map<String, int> _expenseTotals = {};
  int _monthIncome = 0;
  int _monthExpense = 0;
  bool _isLoading = true;
  List<CategoryModel> _categories = [];
  BudgetModel? _budget;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await FinanceSettingsApi.ensureDefaults();
      final now = DateTime.now();
      final today = _dateStr(now);
      final firstOfMonth = _dateStr(DateTime(now.year, now.month, 1));

      final results = await Future.wait([
        AccountRecordApi.fetchByDateRange(firstOfMonth, today),
        CategoryApi.fetchAll(),
        BudgetApi.fetch(year: now.year, month: now.month),
      ]);

      final monthRecords = results[0] as List<AccountRecordModel>;
      final categories = results[1] as List<CategoryModel>;
      final budget = results[2] as BudgetModel?;

      final monthIncome = monthRecords
          .where((r) => r.categoryType == 'INCOME')
          .fold(0, (sum, r) => sum + r.amount);
      final monthExpense = monthRecords
          .where((r) => r.categoryType == 'EXPENSE')
          .fold(0, (sum, r) => sum + r.amount);

      final expenseTotals = <String, int>{};
      for (final r in monthRecords.where((r) => r.categoryType == 'EXPENSE')) {
        expenseTotals[r.categoryName] = (expenseTotals[r.categoryName] ?? 0) + r.amount;
      }

      if (!mounted) return;
      setState(() {
        _recentRecords = monthRecords.reversed.take(4).toList();
        _expenseTotals = expenseTotals;
        _monthIncome = monthIncome;
        _monthExpense = monthExpense;
        _categories = categories;
        _budget = budget;
      });
    } catch (_) {
      // show empty state on error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AppTopBar(title: '소비 상세 페이지', showBack: false),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: _primaryPink, strokeWidth: 2))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _TopActionButton(
                                label: '+ 수입·지출 추가',
                                backgroundColor: _primaryPink,
                                textColor: Colors.white,
                                onTap: _showAddTransactionDialog,
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: _TopActionButton(
                                label: '전체 보기',
                                backgroundColor: Colors.white,
                                textColor: _lineNavy,
                                onTap: () => _openAllRecords(context),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: _MonthlySummaryCard(
                                title: '이번 달 총 수입',
                                amount: _monthIncome,
                                accentColor: _green,
                                chartIcon: Icons.show_chart,
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: _MonthlySummaryCard(
                                title: '이번 달 총 지출',
                                amount: _monthExpense,
                                accentColor: _red,
                                chartIcon: Icons.trending_down,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _OutlinedSection(
                          child: _BudgetGoalSection(
                            budget: _budget,
                            monthExpense: _monthExpense,
                            onEdit: _showEditBudgetDialog,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _OutlinedSection(
                          child: _CategoryExpenseChart(
                            totals: _expenseTotals,
                            colors: const [_blue, _green, _red, _purple],
                          ),
                        ),
                        const SizedBox(height: 18),
                        _OutlinedSection(
                          height: 310,
                          child: _RecentRecords(
                            records: _recentRecords,
                            onViewAll: () => _openAllRecords(context),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentItem: AppNavItem.cash),
    );
  }

  void _openAllRecords(BuildContext context) {
    Navigator.of(context).pushNamed(Routes.cashRecords).then((_) => _loadData());
  }

  Future<void> _showEditBudgetDialog() async {
    final now = DateTime.now();
    final result = await showDialog<int>(
      context: context,
      builder: (_) => _BudgetGoalDialog(initialAmount: _budget?.limitAmount),
    );
    if (result == null) return;
    try {
      final saved = await BudgetApi.upsert(year: now.year, month: now.month, limitAmount: result);
      if (!mounted) return;
      setState(() => _budget = saved);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('지출 목표 저장에 실패했습니다.')),
        );
      }
    }
  }

  void _showAddTransactionDialog() {
    final expenseCategories =
        _categories.where((category) => category.type == 'EXPENSE').toList();
    final incomeCategories =
        _categories.where((category) => category.type == 'INCOME').toList();
    if (expenseCategories.isEmpty || incomeCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카테고리와 수입원을 먼저 추가해 주세요.')),
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (_) => _AddTransactionDialog(
        expenseCategories: expenseCategories,
        incomeCategories: incomeCategories,
        onSave: (amount, category, sourceCategory, isExpense, transactionTime) async {
          try {
            await AccountRecordApi.create(
              amount: amount,
              categoryId: category.id,
              sourceCategoryId: sourceCategory?.id,
              transactionTime: transactionTime,
            );
            await _loadData();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(isExpense ? '지출을 추가했습니다.' : '수입을 추가했습니다.')),
              );
            }
          } catch (_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('가계부 기록에 실패했습니다.')),
              );
            }
          }
        },
      ),
    );
  }
}

class _TopActionButton extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onTap;

  const _TopActionButton({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.card),
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: _CashDetailScreenState._lineNavy, width: 1),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Text(label, style: AppTextStyles.body.copyWith(color: textColor, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _MonthlySummaryCard extends StatelessWidget {
  final String title;
  final int amount;
  final Color accentColor;
  final IconData chartIcon;

  const _MonthlySummaryCard({
    required this.title,
    required this.amount,
    required this.accentColor,
    required this.chartIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 94,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _CashDetailScreenState._lineNavy, width: 1),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(chartIcon, size: 18, color: accentColor),
          const Spacer(),
          Text(title, style: AppTextStyles.small.copyWith(color: _CashDetailScreenState._lineNavy, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(_formatWon(amount), style: AppTextStyles.subtitle.copyWith(color: _CashDetailScreenState._lineNavy)),
        ],
      ),
    );
  }
}

class _OutlinedSection extends StatelessWidget {
  final Widget child;
  final double? height;

  const _OutlinedSection({required this.child, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _CashDetailScreenState._lineNavy, width: 1),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: child,
    );
  }
}

class _CategoryExpenseChart extends StatelessWidget {
  final Map<String, int> totals;
  final List<Color> colors;

  const _CategoryExpenseChart({required this.totals, required this.colors});

  @override
  Widget build(BuildContext context) {
    final entries = totals.entries.toList(growable: false);
    final total = entries.fold<int>(0, (sum, entry) => sum + entry.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.credit_card, size: 16, color: _CashDetailScreenState._lineNavy),
            const SizedBox(width: 6),
            Text('카테고리별 지출', style: AppTextStyles.caption.copyWith(color: _CashDetailScreenState._lineNavy, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 20),
        if (entries.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('이번 달 지출 내역이 없어요.', style: AppTextStyles.caption)),
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _CategoryPieChart(entries: entries, colors: colors, total: total),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: entries.asMap().entries.map((indexed) {
                    final color = colors[indexed.key % colors.length];
                    final name = indexed.value.key;
                    final amount = indexed.value.value;
                    final percent = total == 0 ? 0 : (amount / total * 100).round();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _CategoryLegendRow(
                        color: color,
                        name: name,
                        amount: amount,
                        percent: percent,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// 카테고리별 지출 비중을 보여주는 원형(도넛) 차트.
class _CategoryPieChart extends StatelessWidget {
  final List<MapEntry<String, int>> entries;
  final List<Color> colors;
  final int total;

  const _CategoryPieChart({required this.entries, required this.colors, required this.total});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: CustomPaint(
        painter: _PieChartPainter(
          values: entries.map((e) => e.value.toDouble()).toList(),
          colors: colors,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('합계', style: AppTextStyles.tiny.copyWith(color: AppColors.textTertiary)),
                  Text(
                    _formatWon(total),
                    style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700, color: _CashDetailScreenState._lineNavy),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;

  const _PieChartPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (sum, value) => sum + value);
    if (total <= 0) return;

    final rect = Offset.zero & size;
    var startAngle = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweepAngle = values[i] / total * 2 * math.pi;
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;
      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);
      startAngle += sweepAngle;
    }

    // 도넛 모양으로 보이도록 가운데를 흰색 원으로 뚫습니다.
    final holePaint = Paint()..color = Colors.white;
    canvas.drawCircle(size.center(Offset.zero), size.shortestSide / 2 * 0.56, holePaint);
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.colors != colors;
}

class _CategoryLegendRow extends StatelessWidget {
  final Color color;
  final String name;
  final int amount;
  final int percent;

  const _CategoryLegendRow({
    required this.color,
    required this.name,
    required this.amount,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.circle, color: color, size: 8),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.small.copyWith(color: _CashDetailScreenState._lineNavy, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 6),
        Text('$percent%', style: AppTextStyles.tiny.copyWith(color: AppColors.textTertiary)),
        const SizedBox(width: 6),
        Text(_formatWon(amount), style: AppTextStyles.tiny.copyWith(color: _CashDetailScreenState._lineNavy, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _RecentRecords extends StatelessWidget {
  final List<AccountRecordModel> records;
  final VoidCallback onViewAll;

  const _RecentRecords({required this.records, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('최근 거래', style: AppTextStyles.caption.copyWith(color: _CashDetailScreenState._lineNavy, fontWeight: FontWeight.w700)),
            InkWell(onTap: onViewAll, child: const Text('전체 보기', style: AppTextStyles.label)),
          ],
        ),
        const SizedBox(height: 12),
        if (records.isEmpty)
          Expanded(child: Center(child: Text('최근 거래가 없어요.', style: AppTextStyles.caption)))
        else
          ...records.map((record) => _RecentRecordTile(record: record)),
      ],
    );
  }
}

class _RecentRecordTile extends StatelessWidget {
  final AccountRecordModel record;

  const _RecentRecordTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final isIncome = record.categoryType == 'INCOME';
    final amountText = isIncome ? '+${_formatNumber(record.amount)}' : '-${_formatNumber(record.amount)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.categoryName, style: AppTextStyles.caption.copyWith(color: _CashDetailScreenState._lineNavy, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(isIncome ? '수입' : '지출', style: AppTextStyles.tiny.copyWith(color: AppColors.textTertiary)),
              ],
            ),
          ),
          Text(
            amountText,
            style: AppTextStyles.small.copyWith(
              color: isIncome ? AppColors.income : AppColors.expense,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetGoalSection extends StatelessWidget {
  final BudgetModel? budget;
  final int monthExpense;
  final VoidCallback onEdit;

  const _BudgetGoalSection({
    required this.budget,
    required this.monthExpense,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final limit = budget?.limitAmount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.flag_outlined, size: 16, color: _CashDetailScreenState._lineNavy),
                const SizedBox(width: 6),
                Text('이번 달 지출 목표', style: AppTextStyles.caption.copyWith(color: _CashDetailScreenState._lineNavy, fontWeight: FontWeight.w700)),
              ],
            ),
            InkWell(
              onTap: onEdit,
              child: Text(limit == null ? '목표 설정' : '수정', style: AppTextStyles.label),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (limit == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text('이번 달 지출 목표를 설정해 보세요.', style: AppTextStyles.caption),
          )
        else ...[
          Builder(builder: (context) {
            final remaining = limit - monthExpense;
            final isOverBudget = remaining < 0;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BudgetProgressBar(spent: monthExpense, limit: limit),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_formatWon(monthExpense)} / ${_formatWon(limit)}',
                      style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700, color: _CashDetailScreenState._lineNavy),
                    ),
                    Text(
                      isOverBudget ? '${_formatWon(-remaining)} 초과' : '${_formatWon(remaining)} 남음',
                      style: AppTextStyles.small.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isOverBudget ? _CashDetailScreenState._red : _CashDetailScreenState._green,
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),
        ],
      ],
    );
  }
}

/// 목표 대비 지출 막대.
///
/// 목표 이내일 때는 지출한 만큼만 핑크로 채우고 나머지는 빈 트랙으로 둡니다.
/// 목표를 넘으면 "얼마나 넘었는지"가 그대로 드러나야 하므로, 막대 전체 폭을
/// 지출액 기준으로 다시 잡고 목표까지는 회색, 넘은 만큼은 빨간색으로 이어 붙입니다.
class _BudgetProgressBar extends StatelessWidget {
  final int spent;
  final int limit;

  const _BudgetProgressBar({required this.spent, required this.limit});

  @override
  Widget build(BuildContext context) {
    final isOverBudget = spent > limit;

    final segments = <Widget>[];
    if (isOverBudget) {
      segments.add(Expanded(flex: limit, child: Container(color: Colors.grey.shade400)));
      segments.add(Expanded(flex: spent - limit, child: Container(color: _CashDetailScreenState._red)));
    } else {
      if (spent > 0) {
        segments.add(Expanded(flex: spent, child: Container(color: _CashDetailScreenState._primaryPink)));
      }
      final remaining = limit - spent;
      if (remaining > 0) {
        segments.add(Expanded(flex: remaining, child: const SizedBox.shrink()));
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 8,
        color: AppColors.inputFill,
        child: Row(children: segments),
      ),
    );
  }
}

class _BudgetGoalDialog extends StatefulWidget {
  final int? initialAmount;

  const _BudgetGoalDialog({this.initialAmount});

  @override
  State<_BudgetGoalDialog> createState() => _BudgetGoalDialogState();
}

class _BudgetGoalDialogState extends State<_BudgetGoalDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialAmount?.toString() ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: '이번 달 지출 목표',
      confirmLabel: '저장',
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(suffixText: '원', hintText: '목표 금액을 입력하세요'),
      ),
      onConfirm: () {
        final amount = int.tryParse(_controller.text.trim());
        if (amount == null || amount <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('올바른 금액을 입력해 주세요.')),
          );
          return;
        }
        Navigator.pop(context, amount);
      },
    );
  }
}

// ─── Add Transaction Dialog ──────────────────────────────────────────────────

class _AddTransactionDialog extends StatefulWidget {
  final List<CategoryModel> expenseCategories;
  // 수입원(=지출 수단) 목록. 수입 추가에서는 카테고리로, 지출 추가에서는 지출 수단으로 쓰인다.
  final List<CategoryModel> incomeCategories;
  final Future<void> Function(
    int amount,
    CategoryModel category,
    CategoryModel? sourceCategory,
    bool isExpense,
    DateTime transactionTime,
  ) onSave;

  const _AddTransactionDialog({
    required this.expenseCategories,
    required this.incomeCategories,
    required this.onSave,
  });

  @override
  State<_AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<_AddTransactionDialog> {
  bool _isExpense = true;
  final _amountCtrl = TextEditingController();
  late CategoryModel _selectedCategory;
  CategoryModel? _selectedSourceCategory;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  List<CategoryModel> get _activeCategories =>
      _isExpense ? widget.expenseCategories : widget.incomeCategories;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.expenseCategories.first;
    _selectedSourceCategory = widget.incomeCategories.firstOrNull;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  // 지출 수단(=돈이 빠져나가는 수입원)은 지출에만 필요합니다.
  // 수입은 수입원 카테고리를 고르는 것만으로 기록되므로 지출 수단을 요구하지 않습니다.
  void _changeType(bool isExpense) {
    setState(() {
      _isExpense = isExpense;
      _selectedCategory = _activeCategories.first;
      if (isExpense) {
        _selectedSourceCategory ??= widget.incomeCategories.firstOrNull;
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  String get _formattedDate =>
      '${_selectedDate.month}월 ${_selectedDate.day}일';

  String get _formattedTime {
    final hour = _selectedTime.hour.toString().padLeft(2, '0');
    final minute = _selectedTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _isExpense ? AppColors.expenseAccent : AppColors.incomeAccent;
    return Dialog(
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.large)),
            child: Row(children: [
              _TypeTab(label: '지출 내역', isActive: _isExpense, activeColor: AppColors.expenseAccent, onTap: () => _changeType(true)),
              _TypeTab(label: '수입 내역', isActive: !_isExpense, activeColor: AppColors.incomeAccent, onTap: () => _changeType(false)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _AmountField(controller: _amountCtrl, isExpense: _isExpense, color: activeColor),
              const SizedBox(height: 18),
              const _DialogLabel('날짜 · 시간'),
              Row(children: [
                Expanded(
                  child: _PickerField(
                    icon: Icons.calendar_today_outlined,
                    label: _formattedDate,
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PickerField(
                    icon: Icons.access_time,
                    label: _formattedTime,
                    onTap: _pickTime,
                  ),
                ),
              ]),
              const SizedBox(height: 18),
              _DialogLabel(_isExpense ? '지출 카테고리' : '수입원 카테고리'),
              _FormDropdown<CategoryModel>(
                icon: Icons.sell_outlined,
                value: _selectedCategory,
                items: _activeCategories,
                labelOf: (category) => category.name,
                onChanged: (category) => setState(() => _selectedCategory = category),
              ),
              if (_isExpense && _selectedSourceCategory != null) ...[
                const SizedBox(height: 18),
                const _DialogLabel('지출 수단'),
                _FormDropdown<CategoryModel>(
                  icon: Icons.account_balance_wallet_outlined,
                  value: _selectedSourceCategory!,
                  items: widget.incomeCategories,
                  labelOf: (source) => source.name,
                  onChanged: (source) => setState(() => _selectedSourceCategory = source),
                ),
              ],
              const SizedBox(height: 22),
              AppPrimaryButton(
                backgroundColor: activeColor,
                label: '기록 저장하기',
                onPressed: () async {
                  final amount = int.tryParse(_amountCtrl.text.trim()) ?? 0;
                  if (amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('금액을 입력해 주세요.')));
                    return;
                  }
                  final transactionTime = DateTime(
                    _selectedDate.year,
                    _selectedDate.month,
                    _selectedDate.day,
                    _selectedTime.hour,
                    _selectedTime.minute,
                  );
                  Navigator.pop(context);
                  await widget.onSave(
                    amount,
                    _selectedCategory,
                    _isExpense ? _selectedSourceCategory : null,
                    _isExpense,
                    transactionTime,
                  );
                },
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _DialogLabel extends StatelessWidget {
  final String text;
  const _DialogLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
  );
}

/// 날짜/시간처럼 탭하면 시스템 피커가 뜨는 입력 필드.
/// 다른 폼 필드와 같은 테두리·모서리를 써서 하나의 폼처럼 보이게 합니다.
class _PickerField extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerField({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.button),
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Row(children: [
          Icon(icon, size: 16, color: AppColors.navyDark),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ]),
      ),
    );
  }
}

/// 카테고리/지출 수단처럼 아이콘 + 드롭다운을 하나의 카드형 필드로 묶어 보여줍니다.
class _FormDropdown<T> extends StatelessWidget {
  final IconData icon;
  final T value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  const _FormDropdown({
    required this.icon,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        isExpanded: true,
        icon: const Icon(Icons.expand_more, size: AppIconSize.inline, color: AppColors.textTertiary),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          prefixIcon: Icon(icon, size: 18, color: AppColors.navyDark),
        ),
        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(labelOf(item))))
            .toList(),
        onChanged: (next) {
          if (next != null) onChanged(next);
        },
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final bool isExpense;
  final Color color;
  const _AmountField({required this.controller, required this.isExpense, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(AppRadius.card), border: Border.all(color: AppColors.inputBorder)),
    child: Row(children: [
      Text(isExpense ? '−' : '+', style: AppTextStyles.amount.copyWith(color: color)),
      const SizedBox(width: 4),
      Expanded(child: TextField(controller: controller, keyboardType: TextInputType.number, textAlign: TextAlign.right, style: AppTextStyles.amount, decoration: InputDecoration(border: InputBorder.none, hintText: '0', hintStyle: TextStyle(fontSize: AppTextStyles.amount.fontSize, color: AppColors.textTertiary)))),
      Text('원', style: TextStyle(fontSize: AppTextStyles.subtitle.fontSize, color: AppColors.textTertiary)),
    ]),
  );
}

class _TypeTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _TypeTab({required this.label, required this.isActive, required this.activeColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isActive ? activeColor.withValues(alpha: 0.08) : AppColors.inputFill,
            border: Border(bottom: BorderSide(color: isActive ? activeColor : Colors.transparent, width: 2)),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
                color: isActive ? activeColor : AppColors.textTertiary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _formatWon(int amount) => '₩${_formatNumber(amount)}';

String _formatNumber(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    if (i != 0 && (text.length - i) % 3 == 0) buffer.write(',');
    buffer.write(text[i]);
  }
  return buffer.toString();
}
