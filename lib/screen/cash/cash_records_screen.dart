import 'package:flutter/material.dart';

import '../../models/account_record_model.dart';
import '../../services/account_record_api.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icon_sizes.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/template/app_top_bar.dart';
import '../../widgets/template/bottom_nav_layout.dart';

class CashRecordsScreen extends StatefulWidget {
  const CashRecordsScreen({super.key});

  @override
  State<CashRecordsScreen> createState() => _CashRecordsScreenState();
}

class _CashRecordsScreenState extends State<CashRecordsScreen> {
  static const _primaryPink = AppColors.primaryPink;
  static const _lineNavy = AppColors.navyDark;

  late DateTime _visibleMonth;
  _RecordFilter _filter = _RecordFilter.expense;
  List<AccountRecordModel> _records = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
    _loadData();
  }

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final from = _dateStr(DateTime(_visibleMonth.year, _visibleMonth.month, 1));
      final to = _dateStr(DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0));
      final records = await AccountRecordApi.fetchByDateRange(from, to);
      if (!mounted) return;
      setState(() => _records = records);
    } catch (_) {
      if (mounted) setState(() => _records = []);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<AccountRecordModel> get _filteredRecords =>
      _records.where((r) => r.categoryType == _filter.type).toList();

  Map<String, List<AccountRecordModel>> _groupByCategory(List<AccountRecordModel> records) {
    final grouped = <String, List<AccountRecordModel>>{};
    for (final record in records) {
      grouped.putIfAbsent(record.categoryName, () => []).add(record);
    }
    for (final group in grouped.values) {
      // 최근 거래가 위로 오도록 날짜·시간 역순 정렬합니다.
      group.sort((a, b) => b.transactionTime.compareTo(a.transactionTime));
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByCategory(_filteredRecords);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AppTopBar(title: '전체 보기'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: _primaryPink, strokeWidth: 2))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
                      children: [
                        _MonthSelector(
                          month: _visibleMonth,
                          onPrevious: _changeMonth(-1),
                          onNext: _changeMonth(1),
                        ),
                        const SizedBox(height: 10),
                        _FilterTabs(
                          selectedFilter: _filter,
                          onChanged: (filter) => setState(() => _filter = filter),
                        ),
                        const SizedBox(height: 14),
                        if (grouped.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 80),
                            child: Center(child: Text('해당 월의 거래 내역이 없어요.', style: AppTextStyles.caption)),
                          )
                        else
                          ...grouped.entries.map(
                            (entry) => _CategoryGroup(categoryName: entry.key, records: entry.value),
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

  VoidCallback _changeMonth(int delta) => () {
        setState(() => _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta));
        _loadData();
      };
}

enum _RecordFilter {
  expense('지출', 'EXPENSE'),
  income('수입', 'INCOME');

  final String label;
  final String type;

  const _RecordFilter(this.label, this.type);
}

class _MonthSelector extends StatelessWidget {
  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _MonthSelector({required this.month, required this.onPrevious, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(onTap: onPrevious, child: const Icon(Icons.chevron_left, size: AppIconSize.inline, color: AppColors.textPrimary)),
        const SizedBox(width: 12),
        Text('${month.month}월', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(width: 12),
        InkWell(onTap: onNext, child: const Icon(Icons.chevron_right, size: AppIconSize.inline, color: AppColors.textPrimary)),
      ],
    );
  }
}

class _FilterTabs extends StatelessWidget {
  final _RecordFilter selectedFilter;
  final ValueChanged<_RecordFilter> onChanged;

  const _FilterTabs({required this.selectedFilter, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _RecordFilter.values.map((filter) {
        final isSelected = selectedFilter == filter;
        return InkWell(
          onTap: () => onChanged(filter),
          child: Container(
            width: 54,
            padding: const EdgeInsets.symmetric(vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: isSelected ? _CashRecordsScreenState._lineNavy : AppColors.cardBorder, width: 1)),
            ),
            child: Text(
              filter.label,
              style: TextStyle(
                color: isSelected ? _CashRecordsScreenState._lineNavy : AppColors.textSecondary,
                fontSize: AppTextStyles.body.fontSize,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }
}

class _CategoryGroup extends StatelessWidget {
  final String categoryName;
  final List<AccountRecordModel> records;

  const _CategoryGroup({required this.categoryName, required this.records});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 72),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_categoryIcon(categoryName), size: 14, color: AppColors.textPrimary),
              const SizedBox(width: 4),
              Text(categoryName, style: TextStyle(color: AppColors.textPrimary, fontSize: AppTextStyles.caption.fontSize, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.cardBorder),
          const SizedBox(height: 10),
          ...records.map((record) => _RecordRow(record: record)),
        ],
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  final AccountRecordModel record;

  const _RecordRow({required this.record});

  @override
  Widget build(BuildContext context) {
    final isIncome = record.categoryType == 'INCOME';
    final amountText = isIncome ? '+${_formatNumber(record.amount)}' : '-${_formatNumber(record.amount)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.categoryName,
                  style: TextStyle(color: _CashRecordsScreenState._lineNavy, fontSize: AppTextStyles.caption.fontSize, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(_formatDateTime(record.transactionTime), style: AppTextStyles.caption),
              ],
            ),
          ),
          Text(
            amountText,
            style: TextStyle(
              color: isIncome ? AppColors.income : AppColors.expense,
              fontSize: AppTextStyles.caption.fontSize,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

IconData _categoryIcon(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('식') || lower.contains('밥') || lower.contains('음식') || lower.contains('dining')) {
    return Icons.local_dining;
  }
  if (lower.contains('교통') || lower.contains('버스') || lower.contains('지하철') || lower.contains('택시')) {
    return Icons.directions_bus_outlined;
  }
  if (lower.contains('의류') || lower.contains('쇼핑') || lower.contains('미용')) {
    return Icons.shopping_bag_outlined;
  }
  if (lower.contains('의료') || lower.contains('건강') || lower.contains('병원')) {
    return Icons.local_hospital_outlined;
  }
  if (lower.contains('문화') || lower.contains('여가') || lower.contains('영화')) {
    return Icons.movie_outlined;
  }
  if (lower.contains('교육') || lower.contains('학원') || lower.contains('책')) {
    return Icons.school_outlined;
  }
  if (lower.contains('통신') || lower.contains('인터넷') || lower.contains('폰')) {
    return Icons.phone_outlined;
  }
  if (lower.contains('주거') || lower.contains('관리비') || lower.contains('월세') || lower.contains('집')) {
    return Icons.home_outlined;
  }
  if (lower.contains('급여') || lower.contains('월급')) {
    return Icons.account_balance_outlined;
  }
  if (lower.contains('수입') || lower.contains('income')) {
    return Icons.trending_up;
  }
  return Icons.receipt_outlined;
}

String _formatDateTime(DateTime dateTime) {
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '${dateTime.month}/${dateTime.day} $hour:$minute';
}

String _formatNumber(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    if (i != 0 && (text.length - i) % 3 == 0) buffer.write(',');
    buffer.write(text[i]);
  }
  return buffer.toString();
}
