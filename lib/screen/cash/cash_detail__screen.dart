import 'package:flutter/material.dart';

import '../../data/mock_erd_repository.dart';
import '../../routes/routes.dart';
import '../../widgets/template/bottom_nav_layout.dart';

/// 소비 상세 페이지입니다. ERD의 AccountRecord/Category/PaymentMethod 관계를 목데이터로 시각화합니다.
class CashDetailScreen extends StatelessWidget {
  final String loginEmail;

  const CashDetailScreen({super.key, this.loginEmail = ''});

  static const _primaryPink = Color(0xFFF7A5A5);
  static const _lineNavy = Color(0xFF53627D);
  static const _green = Color(0xFF4CC83D);
  static const _red = Color(0xFFFF4D55);
  static const _blue = Color(0xFF5E77FF);
  static const _purple = Color(0xFFB868FF);

  @override
  Widget build(BuildContext context) {
    final repository = MockErdRepository.instance;
    final now = DateTime.now();
    final recentRecords = repository.sortedAccountRecordViews().take(4).toList(growable: false);
    final expenseTotals = repository.monthlyExpenseTotalsByCategory(now);
    final todayIncome = repository.todayTotalByType('INCOME');
    final todayExpense = repository.todayTotalByType('EXPENSE');

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
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
                          label: '+ 지출 추가',
                          backgroundColor: _primaryPink,
                          textColor: Colors.white,
                          onTap: () {},
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
                          amount: todayIncome,
                          rateText: '+12.5%',
                          accentColor: _green,
                          chartIcon: Icons.show_chart,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: _TodaySummaryCard(
                          title: '오늘 총 지출',
                          amount: todayExpense,
                          rateText: '-8.2%',
                          accentColor: _red,
                          chartIcon: Icons.trending_down,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _OutlinedSection(
                    child: _CategoryExpenseChart(
                      totals: expenseTotals,
                      colors: const [_blue, _green, _red, _purple],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _OutlinedSection(
                    height: 310,
                    child: _RecentRecords(
                      records: recentRecords,
                      onViewAll: () => _openAllRecords(context),
                    ),
                  ),
                ],
              ),
            ),
            BottomNavLayout(loginEmail: loginEmail, currentTab: BottomNavType.cash),
          ],
        ),
      ),
    );
  }

  /// 최근 거래 섹션과 상단 전체 보기 버튼이 같은 전체 거래 페이지로 이동합니다.
  void _openAllRecords(BuildContext context) {
    Navigator.of(context).pushNamed(Routes.cashRecords, arguments: {'loginEmail': loginEmail});
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
          border: Border.all(color: CashDetailScreen._lineNavy, width: 1),
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
  final String rateText;
  final Color accentColor;
  final IconData chartIcon;

  const _TodaySummaryCard({
    required this.title,
    required this.amount,
    required this.rateText,
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
        border: Border.all(color: CashDetailScreen._lineNavy, width: 1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(chartIcon, size: 18, color: accentColor),
              Text(rateText, style: TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.w700)),
            ],
          ),
          const Spacer(),
          Text(title, style: const TextStyle(color: CashDetailScreen._lineNavy, fontSize: 11, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(_formatWon(amount), style: const TextStyle(color: CashDetailScreen._lineNavy, fontSize: 14, fontWeight: FontWeight.w800)),
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
        border: Border.all(color: CashDetailScreen._lineNavy, width: 1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: child,
    );
  }
}

class _CategoryExpenseChart extends StatelessWidget {
  final Map<Category, int> totals;
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
            Icon(Icons.credit_card, size: 16, color: CashDetailScreen._lineNavy),
            SizedBox(width: 6),
            Text('카테고리별 지출', style: TextStyle(color: CashDetailScreen._lineNavy, fontSize: 12, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 26),
        if (entries.isEmpty)
          const Center(child: Text('이번 달 지출 내역이 없어요.', style: TextStyle(color: Colors.black45, fontSize: 12)))
        else
          ...entries.asMap().entries.map((indexed) {
            final color = colors[indexed.key % colors.length];
            final category = indexed.value.key;
            final amount = indexed.value.value;
            final ratio = amount / maxTotal;
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _ExpenseBar(categoryName: category.name, amount: amount, ratio: ratio, color: color),
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
            Text(categoryName, style: const TextStyle(color: CashDetailScreen._lineNavy, fontSize: 11, fontWeight: FontWeight.w800)),
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
            Text(_formatWon(amount), style: const TextStyle(color: CashDetailScreen._lineNavy, fontSize: 9)),
            const Text('₩', style: TextStyle(color: CashDetailScreen._lineNavy, fontSize: 10)),
          ],
        ),
      ],
    );
  }
}

class _RecentRecords extends StatelessWidget {
  final List<AccountRecordView> records;
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
            const Text('최근 거래', style: TextStyle(color: CashDetailScreen._lineNavy, fontSize: 12, fontWeight: FontWeight.w800)),
            InkWell(onTap: onViewAll, child: const Text('전체 보기', style: TextStyle(color: CashDetailScreen._lineNavy, fontSize: 10))),
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
  final AccountRecordView record;

  const _RecentRecordTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final amount = record.record.amount;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_recordTitle(record), style: const TextStyle(color: CashDetailScreen._lineNavy, fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(record.category.name, style: const TextStyle(color: Colors.black38, fontSize: 10)),
              ],
            ),
          ),
          Text(record.paymentMethod.name, style: const TextStyle(color: CashDetailScreen._lineNavy, fontSize: 10)),
          const SizedBox(width: 8),
          Text(
            _formatSignedAmount(amount),
            style: TextStyle(color: amount >= 0 ? const Color(0xFF1B5E20) : Colors.red, fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

String _recordTitle(AccountRecordView record) => record.schedule?.title ?? record.category.name;

String _formatSignedAmount(int amount) => '${amount < 0 ? '-' : '+'}${_formatNumber(amount.abs())}';

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
