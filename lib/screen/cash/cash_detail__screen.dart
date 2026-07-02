import 'package:flutter/material.dart';

import '../../models/account_record_model.dart';
import '../../routes/routes.dart';
import '../../services/account_record_api.dart';
import '../../services/category_api.dart';
import '../../widgets/template/bottom_nav_layout.dart';

class CashDetailScreen extends StatefulWidget {
  const CashDetailScreen({super.key});

  @override
  State<CashDetailScreen> createState() => _CashDetailScreenState();
}

class _CashDetailScreenState extends State<CashDetailScreen> {
  static const _primaryPink = Color(0xFFF7A5A5);
  static const _lineNavy = Color(0xFF53627D);
  static const _green = Color(0xFF4CC83D);
  static const _red = Color(0xFFFF4D55);
  static const _blue = Color(0xFF5E77FF);
  static const _purple = Color(0xFFB868FF);

  List<AccountRecordModel> _recentRecords = [];
  Map<String, int> _expenseTotals = {};
  int _todayIncome = 0;
  int _todayExpense = 0;
  bool _isLoading = true;
  List<CategoryModel> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      final today = _dateStr(now);
      final firstOfMonth = _dateStr(DateTime(now.year, now.month, 1));

      final results = await Future.wait([
        AccountRecordApi.fetchByDate(today),
        AccountRecordApi.fetchByDateRange(firstOfMonth, today),
        CategoryApi.fetchAll(),
      ]);

      final todayRecords = results[0] as List<AccountRecordModel>;
      final monthRecords = results[1] as List<AccountRecordModel>;
      final categories = results[2] as List<CategoryModel>;

      final todayIncome = todayRecords
          .where((r) => r.categoryType == 'INCOME')
          .fold(0, (sum, r) => sum + r.amount);
      final todayExpense = todayRecords
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
        _todayIncome = todayIncome;
        _todayExpense = todayExpense;
        _categories = categories;
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
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: _primaryPink, strokeWidth: 2))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                      children: [
                        const Center(
                          child: Text(
                            '소비 상세 페이지',
                            style: TextStyle(color: _lineNavy, fontSize: 15, fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(height: 28),
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
                              child: _TodaySummaryCard(
                                title: '오늘 총 수입',
                                amount: _todayIncome,
                                accentColor: _green,
                                chartIcon: Icons.show_chart,
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: _TodaySummaryCard(
                                title: '오늘 총 지출',
                                amount: _todayExpense,
                                accentColor: _red,
                                chartIcon: Icons.trending_down,
                              ),
                            ),
                          ],
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
            const AppBottomNavBar(currentItem: AppNavItem.cash),
          ],
        ),
      ),
    );
  }

  void _openAllRecords(BuildContext context) {
    Navigator.of(context).pushNamed(Routes.cashRecords);
  }

  void _showAddTransactionDialog() {
    final expenseCats = _categories.where((c) => c.type == 'EXPENSE').map((c) => c.name).toList();
    final incomeCats = _categories.where((c) => c.type == 'INCOME').map((c) => c.name).toList();
    if (expenseCats.isEmpty && incomeCats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카테고리가 없습니다. 먼저 카테고리를 추가해 주세요.')),
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (_) => _AddTransactionDialog(
        expenseCategories: expenseCats.isNotEmpty ? expenseCats : ['기타'],
        incomeCategories: incomeCats.isNotEmpty ? incomeCats : ['기타'],
        onSave: (amount, categoryName, isExpense) async {
          if (_categories.isEmpty) return;
          final cat = _categories.firstWhere(
            (c) => c.name == categoryName,
            orElse: () => _categories.first,
          );
          try {
            await AccountRecordApi.create(
              amount: amount,
              categoryId: cat.id,
              date: _dateStr(DateTime.now()),
            );
            await _loadData();
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
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: _CashDetailScreenState._lineNavy, width: 1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label, style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _TodaySummaryCard extends StatelessWidget {
  final String title;
  final int amount;
  final Color accentColor;
  final IconData chartIcon;

  const _TodaySummaryCard({
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
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(chartIcon, size: 18, color: accentColor),
          const Spacer(),
          Text(title, style: const TextStyle(color: _CashDetailScreenState._lineNavy, fontSize: 11, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(_formatWon(amount), style: const TextStyle(color: _CashDetailScreenState._lineNavy, fontSize: 14, fontWeight: FontWeight.w800)),
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
        borderRadius: BorderRadius.circular(6),
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
    final maxTotal = entries.fold<int>(1, (max, entry) => entry.value > max ? entry.value : max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.credit_card, size: 16, color: _CashDetailScreenState._lineNavy),
            SizedBox(width: 6),
            Text('카테고리별 지출', style: TextStyle(color: _CashDetailScreenState._lineNavy, fontSize: 12, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 26),
        if (entries.isEmpty)
          const Center(child: Text('이번 달 지출 내역이 없어요.', style: TextStyle(color: Colors.black45, fontSize: 12)))
        else
          ...entries.asMap().entries.map((indexed) {
            final color = colors[indexed.key % colors.length];
            final name = indexed.value.key;
            final amount = indexed.value.value;
            final ratio = amount / maxTotal;
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _ExpenseBar(categoryName: name, amount: amount, ratio: ratio, color: color),
            );
          }),
      ],
    );
  }
}

class _ExpenseBar extends StatelessWidget {
  final String categoryName;
  final int amount;
  final double ratio;
  final Color color;

  const _ExpenseBar({required this.categoryName, required this.amount, required this.ratio, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.circle, color: color, size: 8),
            const SizedBox(width: 4),
            Text(categoryName, style: const TextStyle(color: _CashDetailScreenState._lineNavy, fontSize: 11, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 4),
        Stack(
          children: [
            Container(height: 6, decoration: BoxDecoration(color: const Color(0xFFE6E6E6), borderRadius: BorderRadius.circular(8))),
            FractionallySizedBox(
              widthFactor: ratio.clamp(0.08, 1.0).toDouble(),
              child: Container(height: 6, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8))),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_formatWon(amount), style: const TextStyle(color: _CashDetailScreenState._lineNavy, fontSize: 9)),
            const Text('₩', style: TextStyle(color: _CashDetailScreenState._lineNavy, fontSize: 10)),
          ],
        ),
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
            const Text('최근 거래', style: TextStyle(color: _CashDetailScreenState._lineNavy, fontSize: 12, fontWeight: FontWeight.w800)),
            InkWell(onTap: onViewAll, child: const Text('전체 보기', style: TextStyle(color: _CashDetailScreenState._lineNavy, fontSize: 10))),
          ],
        ),
        const SizedBox(height: 12),
        if (records.isEmpty)
          const Expanded(child: Center(child: Text('최근 거래가 없어요.', style: TextStyle(color: Colors.black45, fontSize: 12))))
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
                Text(record.categoryName, style: const TextStyle(color: _CashDetailScreenState._lineNavy, fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(isIncome ? '수입' : '지출', style: const TextStyle(color: Colors.black38, fontSize: 10)),
              ],
            ),
          ),
          Text(
            amountText,
            style: TextStyle(
              color: isIncome ? const Color(0xFF1B5E20) : Colors.red,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Add Transaction Dialog ──────────────────────────────────────────────────

class _AddTransactionDialog extends StatefulWidget {
  final List<String> expenseCategories;
  final List<String> incomeCategories;
  final Future<void> Function(int amount, String categoryName, bool isExpense) onSave;

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
  late String _selectedCategory;

  List<String> get _activeCategories =>
      _isExpense ? widget.expenseCategories : widget.incomeCategories;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.expenseCategories.isNotEmpty
        ? widget.expenseCategories.first
        : '기타';
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor =
        _isExpense ? const Color(0xFFE05353) : const Color(0xFF5AAD72);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: Row(
                children: [
                  _TypeTab(
                    label: '지출 내역',
                    isActive: _isExpense,
                    activeColor: const Color(0xFFE05353),
                    onTap: () => setState(() {
                      _isExpense = true;
                      _selectedCategory = widget.expenseCategories.isNotEmpty
                          ? widget.expenseCategories.first
                          : '기타';
                    }),
                  ),
                  _TypeTab(
                    label: '수입 내역',
                    isActive: !_isExpense,
                    activeColor: const Color(0xFF5AAD72),
                    onTap: () => setState(() {
                      _isExpense = false;
                      _selectedCategory = widget.incomeCategories.isNotEmpty
                          ? widget.incomeCategories.first
                          : '기타';
                    }),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE0E3E8)),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _isExpense ? '−' : '+',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: activeColor),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: TextField(
                            controller: _amountCtrl,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: '0',
                              hintStyle: TextStyle(fontSize: 22, color: Colors.black26),
                            ),
                          ),
                        ),
                        const Text('원', style: TextStyle(fontSize: 14, color: Colors.black38)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Text('카테고리', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
                  ),
                  ..._activeCategories.map(
                    (cat) => RadioListTile<String>(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: cat,
                      groupValue: _selectedCategory,
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedCategory = v);
                      },
                      activeColor: const Color(0xFF6F7A9B),
                      title: Text(cat, style: const TextStyle(fontSize: 13)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: () async {
                        final amount = int.tryParse(_amountCtrl.text.trim()) ?? 0;
                        if (amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('금액을 입력해 주세요.')),
                          );
                          return;
                        }
                        Navigator.pop(context);
                        await widget.onSave(amount, _selectedCategory, _isExpense);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: activeColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('기록 저장하기'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
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
            color: isActive ? activeColor.withValues(alpha: 0.08) : const Color(0xFFF5F7F8),
            border: Border(bottom: BorderSide(color: isActive ? activeColor : Colors.transparent, width: 2)),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? activeColor : Colors.black38,
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
