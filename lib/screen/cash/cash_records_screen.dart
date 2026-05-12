import 'package:flutter/material.dart';

import '../../data/mock_erd_repository.dart';
import '../../widgets/template/bottom_nav_layout.dart';

/// 최근 거래의 전체 보기 화면입니다. 월/수입·지출 필터는 ERD Category.type과 transactionTime을 기준으로 동작합니다.
class CashRecordsScreen extends StatefulWidget {
  final String loginEmail;

  const CashRecordsScreen({super.key, this.loginEmail = ''});

  @override
  State<CashRecordsScreen> createState() => _CashRecordsScreenState();
}

class _CashRecordsScreenState extends State<CashRecordsScreen> {
  static const _primaryPink = Color(0xFFFFA4A9);
  static const _softPink = Color(0xFFFFF1EF);
  static const _lineNavy = Color(0xFF53627D);

  final MockErdRepository _repository = MockErdRepository.instance;
  late DateTime _visibleMonth;
  _RecordFilter _filter = _RecordFilter.expense;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // ✅ 전체보기 진입 시 현재 월부터 보여주고 좌우 버튼으로 월을 이동합니다.
    _visibleMonth = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 현재 화면의 로그인 이메일에서 회원 고유번호(id)를 확인해 전체보기 거래도 회원별로 분리합니다.
    final id = _repository.idForEmail(widget.loginEmail);
    final records = _repository.accountRecordsByMonth(_visibleMonth, type: _filter.type, id: id);
    final grouped = _groupRecordsByCategory(records);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => Navigator.of(context).pop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
                children: [
                  _MonthSelector(
                    month: _visibleMonth,
                    onPrevious: () => _changeMonth(-1),
                    onNext: () => _changeMonth(1),
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
            BottomNavLayout(loginEmail: widget.loginEmail, currentTab: BottomNavType.cash),
          ],
        ),
      ),
    );
  }

  void _changeMonth(int delta) {
    setState(() => _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta));
  }

  /// 전체 거래 목록은 이미지 시안처럼 카테고리 제목 아래 거래가 모이도록 그룹핑합니다.
  Map<String, List<AccountRecordView>> _groupRecordsByCategory(List<AccountRecordView> records) {
    final grouped = <String, List<AccountRecordView>>{};
    for (final record in records) {
      grouped.putIfAbsent(record.category.name, () => []).add(record);
    }
    return grouped;
  }
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
  final List<AccountRecordView> records;

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
              const Icon(Icons.local_dining, size: 14, color: Colors.black),
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
  final AccountRecordView record;

  const _RecordRow({required this.record});

  @override
  Widget build(BuildContext context) {
    final amount = record.record.amount;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _recordTitle(record),
              style: const TextStyle(color: _CashRecordsScreenState._lineNavy, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          Text(record.paymentMethod.name, style: const TextStyle(color: _CashRecordsScreenState._lineNavy, fontSize: 10)),
          const SizedBox(width: 4),
          const Icon(Icons.credit_card, size: 13, color: _CashRecordsScreenState._lineNavy),
          const SizedBox(width: 8),
          Text(
            _formatSignedAmount(amount),
            style: TextStyle(color: amount >= 0 ? const Color(0xFF1B5E20) : Colors.red, fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

String _recordTitle(AccountRecordView record) => record.schedule?.title ?? _fallbackTitle(record);

String _fallbackTitle(AccountRecordView record) {
  switch (record.category.name) {
    case '카페':
      return '스타벅스 노원역';
    case '교통비':
      return '역전우동';
    case '쇼핑':
      return '온라인 쇼핑';
    case '문화생활':
      return '영화 예매';
    default:
      return record.category.name;
  }
}

String _formatSignedAmount(int amount) => '${amount < 0 ? '-' : '+'}${_formatNumber(amount.abs())}';

String _formatNumber(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    if (i != 0 && (text.length - i) % 3 == 0) buffer.write(',');
    buffer.write(text[i]);
  }
  return buffer.toString();
}
