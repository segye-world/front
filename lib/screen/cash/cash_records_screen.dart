import 'package:flutter/material.dart';

import '../../models/account_record_model.dart';
import '../../services/account_record_api.dart';
import '../../widgets/template/bottom_nav_layout.dart';

class CashRecordsScreen extends StatefulWidget {
  const CashRecordsScreen({super.key});

  @override
  State<CashRecordsScreen> createState() => _CashRecordsScreenState();
}

class _CashRecordsScreenState extends State<CashRecordsScreen> {
  static const _primaryPink = Color(0xFFFFA4A9);
  static const _softPink = Color(0xFFFFF1EF);
  static const _lineNavy = Color(0xFF53627D);

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
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByCategory(_filteredRecords);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => Navigator.of(context).pop()),
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
                            child: Center(child: Text('해당 월의 거래 내역이 없어요.', style: TextStyle(color: Colors.black45, fontSize: 12))),
                          )
                        else
                          ...grouped.entries.map(
                            (entry) => _CategoryGroup(categoryName: entry.key, records: entry.value),
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

class _Header extends StatelessWidget {
  final VoidCallback onBack;

  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      color: _CashRecordsScreenState._softPink,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.chevron_left, color: _CashRecordsScreenState._primaryPink),
              onPressed: onBack,
            ),
          ),
          const Text('전체 보기', style: TextStyle(color: _CashRecordsScreenState._lineNavy, fontSize: 14, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
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
        InkWell(onTap: onPrevious, child: const Icon(Icons.chevron_left, size: 20, color: Colors.black87)),
        const SizedBox(width: 12),
        Text('${month.month}월', style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w700)),
        const SizedBox(width: 12),
        InkWell(onTap: onNext, child: const Icon(Icons.chevron_right, size: 20, color: Colors.black87)),
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
              border: Border(bottom: BorderSide(color: isSelected ? _CashRecordsScreenState._lineNavy : Colors.black12, width: 1)),
            ),
            child: Text(
              filter.label,
              style: TextStyle(
                color: isSelected ? _CashRecordsScreenState._lineNavy : Colors.black45,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
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
              Icon(_categoryIcon(categoryName), size: 14, color: Colors.black),
              const SizedBox(width: 4),
              Text(categoryName, style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFE2E2E2)),
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
        children: [
          Expanded(
            child: Text(
              record.categoryName,
              style: const TextStyle(color: _CashRecordsScreenState._lineNavy, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            amountText,
            style: TextStyle(
              color: isIncome ? const Color(0xFF1B5E20) : Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.w800,
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

String _formatNumber(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    if (i != 0 && (text.length - i) % 3 == 0) buffer.write(',');
    buffer.write(text[i]);
  }
  return buffer.toString();
}
