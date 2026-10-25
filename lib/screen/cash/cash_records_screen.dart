import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/account_record_model.dart';
import '../../services/account_record_api.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icon_sizes.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/app_dialog.dart';
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
  // 날짜 흐름을 보기 쉽도록 날짜별 묶음을 기본으로 두고, 필요하면 카테고리별로 전환합니다.
  _ViewMode _viewMode = _ViewMode.date;
  List<AccountRecordModel> _records = [];
  bool _isLoading = false;

  // 3초 이상 꾹 눌러 들어가는 삭제 선택 모드. 선택된 항목이 하나라도 있으면 선택 모드입니다.
  final Set<int> _selectedIds = <int>{};
  bool get _isSelectionMode => _selectedIds.isNotEmpty;

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
    setState(() {
      _isLoading = true;
      _selectedIds.clear();
    });
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

  void _handleRecordTap(AccountRecordModel record) {
    if (_isSelectionMode) {
      _toggleSelected(record.id);
    } else {
      _showRecordDetail(context, record);
    }
  }

  void _handleRecordLongPress(AccountRecordModel record) {
    setState(() => _selectedIds.add(record.id));
  }

  void _toggleSelected(int id) {
    setState(() {
      if (!_selectedIds.remove(id)) {
        _selectedIds.add(id);
      }
    });
  }

  void _cancelSelection() {
    setState(() => _selectedIds.clear());
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    final count = _selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AppDialog(
        title: '내역 삭제',
        content: Text('선택한 $count개 내역을 삭제할까요?'),
        confirmLabel: '삭제',
        confirmColor: AppColors.expenseAccent,
        onConfirm: () => Navigator.pop(context, true),
      ),
    );
    if (confirmed != true) return;

    final idsToDelete = _selectedIds.toList();
    try {
      await Future.wait(idsToDelete.map((id) => AccountRecordApi.delete(id)));
      if (!mounted) return;
      setState(() {
        _records.removeWhere((r) => idsToDelete.contains(r.id));
        _selectedIds.clear();
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('내역 삭제에 실패했습니다.')),
        );
      }
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

  /// 날짜(일 단위)로 묶고, 최신 날짜가 위로 오도록 정렬합니다.
  List<MapEntry<DateTime, List<AccountRecordModel>>> _groupByDate(
      List<AccountRecordModel> records) {
    final grouped = <DateTime, List<AccountRecordModel>>{};
    for (final record in records) {
      final time = record.transactionTime;
      final day = DateTime(time.year, time.month, time.day);
      grouped.putIfAbsent(day, () => []).add(record);
    }
    for (final group in grouped.values) {
      group.sort((a, b) => b.transactionTime.compareTo(a.transactionTime));
    }
    final entries = grouped.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredRecords;
    final isEmpty = filtered.isEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppTopBar(
        title: _isSelectionMode ? '${_selectedIds.length}개 선택' : '전체 보기',
        showBack: !_isSelectionMode,
        actions: _isSelectionMode
            ? [
                IconButton(
                  tooltip: '선택 삭제',
                  icon: const Icon(Icons.delete_outline, color: AppColors.expenseAccent),
                  onPressed: _deleteSelected,
                ),
                IconButton(
                  tooltip: '선택 해제',
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: _cancelSelection,
                ),
              ]
            : null,
      ),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _FilterTabs(
                              selectedFilter: _filter,
                              onChanged: (filter) => setState(() {
                                _filter = filter;
                                _selectedIds.clear();
                              }),
                            ),
                            _ViewModeToggle(
                              selectedMode: _viewMode,
                              onChanged: (mode) => setState(() => _viewMode = mode),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 80),
                            child: Center(child: Text('해당 월의 거래 내역이 없어요.', style: AppTextStyles.caption)),
                          )
                        else if (_viewMode == _ViewMode.date)
                          ..._groupByDate(filtered).map(
                            (entry) => _DateGroup(
                              date: entry.key,
                              records: entry.value,
                              isSelectionMode: _isSelectionMode,
                              selectedIds: _selectedIds,
                              onRecordTap: _handleRecordTap,
                              onRecordLongPress: _handleRecordLongPress,
                            ),
                          )
                        else
                          ..._groupByCategory(filtered).entries.map(
                            (entry) => _CategoryGroup(
                              categoryName: entry.key,
                              records: entry.value,
                              isSelectionMode: _isSelectionMode,
                              selectedIds: _selectedIds,
                              onRecordTap: _handleRecordTap,
                              onRecordLongPress: _handleRecordLongPress,
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

enum _ViewMode {
  date('날짜별'),
  category('카테고리별');

  final String label;

  const _ViewMode(this.label);
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

/// 날짜별 ↔ 카테고리별 묶음을 전환하는 토글.
class _ViewModeToggle extends StatelessWidget {
  final _ViewMode selectedMode;
  final ValueChanged<_ViewMode> onChanged;

  const _ViewModeToggle({required this.selectedMode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _ViewMode.values.map((mode) {
          final isSelected = selectedMode == mode;
          return InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => onChanged(mode),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? _CashRecordsScreenState._primaryPink : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                mode.label,
                style: TextStyle(
                  fontSize: AppTextStyles.small.fontSize,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }
}

class _CategoryGroup extends StatelessWidget {
  final String categoryName;
  final List<AccountRecordModel> records;
  final bool isSelectionMode;
  final Set<int> selectedIds;
  final void Function(AccountRecordModel) onRecordTap;
  final void Function(AccountRecordModel) onRecordLongPress;

  const _CategoryGroup({
    required this.categoryName,
    required this.records,
    required this.isSelectionMode,
    required this.selectedIds,
    required this.onRecordTap,
    required this.onRecordLongPress,
  });

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
          ...records.map((record) => _RecordRow(
                record: record,
                isSelectionMode: isSelectionMode,
                isSelected: selectedIds.contains(record.id),
                onTap: () => onRecordTap(record),
                onLongPressSelect: () => onRecordLongPress(record),
              )),
        ],
      ),
    );
  }
}

/// 날짜별 묶음 섹션. 헤더에 그 날의 합계를 함께 보여줍니다.
class _DateGroup extends StatelessWidget {
  final DateTime date;
  final List<AccountRecordModel> records;
  final bool isSelectionMode;
  final Set<int> selectedIds;
  final void Function(AccountRecordModel) onRecordTap;
  final void Function(AccountRecordModel) onRecordLongPress;

  const _DateGroup({
    required this.date,
    required this.records,
    required this.isSelectionMode,
    required this.selectedIds,
    required this.onRecordTap,
    required this.onRecordLongPress,
  });

  @override
  Widget build(BuildContext context) {
    // 필터로 이미 수입/지출 한쪽만 들어오므로 모든 항목의 부호가 같습니다.
    final isIncome = records.first.categoryType == 'INCOME';
    final total = records.fold<int>(0, (sum, record) => sum + record.amount);
    final totalText = isIncome ? '+${_formatNumber(total)}원' : '-${_formatNumber(total)}원';

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDayHeader(date),
                style: TextStyle(color: AppColors.textPrimary, fontSize: AppTextStyles.caption.fontSize, fontWeight: FontWeight.w700),
              ),
              Text(
                totalText,
                style: TextStyle(
                  color: isIncome ? AppColors.income : AppColors.expense,
                  fontSize: AppTextStyles.caption.fontSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.cardBorder),
          const SizedBox(height: 10),
          ...records.map((record) => _RecordRow(
                record: record,
                isSelectionMode: isSelectionMode,
                isSelected: selectedIds.contains(record.id),
                onTap: () => onRecordTap(record),
                onLongPressSelect: () => onRecordLongPress(record),
              )),
        ],
      ),
    );
  }
}

/// 3초 이상 꾹 누르면 삭제 선택 모드로 들어가는 거래 행.
///
/// 기본 [GestureDetector.onLongPress]는 바로 반응하므로 쓰지 않고, 누른 순간부터
/// 직접 타이머를 돌려 3초가 지날 때만 선택 콜백을 부릅니다. 그 전에 손을 떼면
/// 평소처럼 상세 보기(혹은 선택 토글)로 이어지는 탭으로 처리합니다.
class _RecordRow extends StatefulWidget {
  final AccountRecordModel record;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPressSelect;

  const _RecordRow({
    required this.record,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onTap,
    required this.onLongPressSelect,
  });

  @override
  State<_RecordRow> createState() => _RecordRowState();
}

class _RecordRowState extends State<_RecordRow> {
  static const _holdDuration = Duration(seconds: 3);

  Timer? _holdTimer;
  bool _holdFired = false;

  void _startHold() {
    _holdFired = false;
    _holdTimer = Timer(_holdDuration, () {
      _holdFired = true;
      widget.onLongPressSelect();
    });
  }

  void _cancelHold() {
    _holdTimer?.cancel();
    _holdTimer = null;
  }

  void _handleTap() {
    // 3초 타이머가 이미 선택을 처리했다면, 손을 뗄 때 따라오는 탭은 무시합니다.
    if (_holdFired) {
      _holdFired = false;
      return;
    }
    widget.onTap();
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    final isIncome = record.categoryType == 'INCOME';
    final amountText = isIncome ? '+${_formatNumber(record.amount)}' : '-${_formatNumber(record.amount)}';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _startHold(),
      onTapUp: (_) => _cancelHold(),
      onTapCancel: _cancelHold,
      onTap: _handleTap,
      child: Container(
        color: widget.isSelected ? AppColors.primaryPinkTint : Colors.transparent,
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.isSelectionMode) ...[
              Padding(
                padding: const EdgeInsets.only(right: 10, top: 1),
                child: Icon(
                  widget.isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 20,
                  color: widget.isSelected ? AppColors.primaryPink : AppColors.textTertiary,
                ),
              ),
            ],
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
                  if (record.memo != null && record.memo!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      record.memo!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
                    ),
                  ],
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
      ),
    );
  }
}

/// 거래 행을 탭하면 메모와 날짜·시간을 포함한 상세 정보를 바텀시트로 보여줍니다.
void _showRecordDetail(BuildContext context, AccountRecordModel record) {
  final isIncome = record.categoryType == 'INCOME';
  final amountColor = isIncome ? AppColors.income : AppColors.expense;
  final amountText = isIncome ? '+${_formatNumber(record.amount)}원' : '-${_formatNumber(record.amount)}원';

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_categoryIcon(record.categoryName), size: 18, color: AppColors.textPrimary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      record.categoryName,
                      style: AppTextStyles.title.copyWith(color: _CashRecordsScreenState._lineNavy),
                    ),
                  ),
                  Text(
                    amountText,
                    style: AppTextStyles.body.copyWith(color: amountColor, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _DetailRow(label: '구분', value: isIncome ? '수입' : '지출'),
              const SizedBox(height: 10),
              _DetailRow(label: '날짜', value: _formatFullDate(record.transactionTime)),
              const SizedBox(height: 10),
              _DetailRow(label: '시간', value: _formatTime(record.transactionTime)),
              if (record.sourceCategoryName != null && record.sourceCategoryName!.isNotEmpty) ...[
                const SizedBox(height: 10),
                _DetailRow(label: '지출 수단', value: record.sourceCategoryName!),
              ],
              const SizedBox(height: 14),
              const Divider(height: 1, color: AppColors.cardBorder),
              const SizedBox(height: 14),
              Text('메모', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700, color: _CashRecordsScreenState._lineNavy)),
              const SizedBox(height: 6),
              Text(
                record.memo != null && record.memo!.isNotEmpty ? record.memo! : '메모가 없습니다.',
                style: AppTextStyles.body.copyWith(
                  color: record.memo != null && record.memo!.isNotEmpty
                      ? AppColors.textPrimary
                      : AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.body.copyWith(color: _CashRecordsScreenState._lineNavy, fontWeight: FontWeight.w600),
          ),
        ),
      ],
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

const List<String> _weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];

String _formatDayHeader(DateTime date) {
  final weekday = _weekdayLabels[date.weekday - 1];
  return '${date.month}월 ${date.day}일 ($weekday)';
}

String _formatFullDate(DateTime dateTime) {
  final weekday = _weekdayLabels[dateTime.weekday - 1];
  return '${dateTime.year}년 ${dateTime.month}월 ${dateTime.day}일 ($weekday)';
}

String _formatTime(DateTime dateTime) {
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
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
