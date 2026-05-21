import 'package:flutter/material.dart';

import '../../models/account_record_model.dart';
import '../../services/account_record_api.dart';
import '../../services/category_api.dart';
import '../../services/schedule_api.dart';
import '../../services/todo_api.dart';
import '../../widgets/template/base_scaffold.dart';
import '../../widgets/template/bottom_nav_layout.dart';

class DayDetailScreen extends StatefulWidget {
  final DateTime selectedDate;
  const DayDetailScreen({super.key, required this.selectedDate});

  @override
  State<DayDetailScreen> createState() => _DayDetailScreenState();
}

enum _Tab { todo, finance }

enum _FinanceFilter { all, expense, income }

class _DayDetailScreenState extends State<DayDetailScreen> {
  static const _primaryColor = Color(0xFF6F7A9B);
  static const _accentColor = Color(0xFFF7A5A5);
  static const _surfaceColor = Color(0xFFFFFBFB);
  static const double _hourHeight = 48.0;

  static const List<Color> _palette = [
    Color(0xFFF3A3A4),
    Color(0xFF9DB7EA),
    Color(0xFF71B35C),
    Color(0xFFFFB24D),
    Color(0xFFE8A5E8),
    Color(0xFF9FD9C8),
    Color(0xFF5E6BA8),
    Color(0xFF8B65E8),
    Color(0xFFBE8A3A),
    Color(0xFFF8A7D8),
    Color(0xFFF2A4A4),
    Color(0xFFF7D5AF),
  ];

  List<_ScheduleBlock> _scheduleBlocks = [];
  List<_ScheduleCardData> _scheduleCards = [];
  List<_FinanceEntry> _financeEntries = [];
  List<CategoryModel> _allCategories = [];
  List<String> _expenseCategories = ['기타'];
  List<String> _incomeCategories = ['기타'];

  _Tab _activeTab = _Tab.todo;
  int? _activeScheduleId;
  bool _isLoading = true;

  final _todoScrollCtrl = ScrollController();
  final Map<int, GlobalKey> _cardKeys = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _todoScrollCtrl.dispose();
    super.dispose();
  }

  // ── Date helpers ──────────────────────────────────────────────────────────

  String get _dateString {
    final y = widget.selectedDate.year.toString();
    final m = widget.selectedDate.month.toString().padLeft(2, '0');
    final d = widget.selectedDate.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String get _formattedDate {
    final m = widget.selectedDate.month.toString().padLeft(2, '0');
    final d = widget.selectedDate.day.toString().padLeft(2, '0');
    return '${widget.selectedDate.year}년 $m월 $d일';
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final date = _dateString;

      final catFuture = CategoryApi.fetchAll();
      final schFuture = ScheduleApi.fetchByDate(date);
      final todoFuture = TodoApi.fetchByDate(date);
      final recFuture = AccountRecordApi.fetchByDate(date);

      final categories = await catFuture;
      final schedules = await schFuture;
      final todos = await todoFuture;
      final records = await recFuture;

      _allCategories = categories;
      final expCats =
          categories.where((c) => c.type == 'EXPENSE').map((c) => c.name).toList();
      final incCats =
          categories.where((c) => c.type == 'INCOME').map((c) => c.name).toList();
      _expenseCategories = expCats.isNotEmpty ? expCats : ['기타'];
      _incomeCategories = incCats.isNotEmpty ? incCats : ['기타'];

      _scheduleBlocks = schedules
          .map(
            (s) => _ScheduleBlock(
              id: s.id,
              title: s.title,
              startHour: s.startHour,
              endHour: s.endHour,
              color: _hexToColor(s.colorHex),
            ),
          )
          .toList();

      _cardKeys.clear();
      _scheduleCards = schedules.map((s) {
        _cardKeys[s.id] = GlobalKey();
        final items = todos
            .where((t) => t.scheduleId == s.id)
            .map((t) => _TodoItem(id: t.id, label: t.label, isDone: t.isDone))
            .toList();
        return _ScheduleCardData(
          id: s.id,
          title: s.title,
          startHour: s.startHour,
          endHour: s.endHour,
          color: _hexToColor(s.colorHex),
          items: items,
        );
      }).toList();

      _cardKeys[-1] = GlobalKey();
      final standaloneItems = todos
          .where((t) => t.scheduleId == null)
          .map((t) => _TodoItem(id: t.id, label: t.label, isDone: t.isDone))
          .toList();
      _scheduleCards.add(
        _ScheduleCardData(
          id: -1,
          title: '일정 외 할일',
          startHour: -1,
          endHour: -1,
          color: const Color(0xFFC6D0D6),
          items: standaloneItems,
          isStandalone: true,
        ),
      );

      final scheduleMap = {for (final s in schedules) s.id: s};
      _financeEntries = records.map((r) {
        final s = r.scheduleId != null ? scheduleMap[r.scheduleId] : null;
        final blockTitle = s != null
            ? '${s.title}  ${_fmtHour(s.startHour)}–${_fmtHour(s.endHour)}'
            : '일정 외';
        return _FinanceEntry(
          category: r.categoryName,
          amount: r.categoryType == 'INCOME' ? r.amount : -r.amount,
          isIncome: r.categoryType == 'INCOME',
          blockTitle: blockTitle,
        );
      }).toList();

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('데이터 로드 실패: $e')),
        );
      }
    }
  }

  // ── Todo actions ──────────────────────────────────────────────────────────

  void _toggleTodo(int scheduleId, int todoId, bool? checked) {
    final card = _cardById(scheduleId);
    final item = card.items.firstWhere((i) => i.id == todoId);
    final newDone = checked ?? false;
    setState(() => item.isDone = newDone);
    TodoApi.update(todoId, isDone: newDone).catchError((_) {
      if (mounted) setState(() => item.isDone = !newDone);
    });
  }

  Future<void> _addTodo(int scheduleId, String text) async {
    if (text.trim().isEmpty) return;
    try {
      final newTodo = await TodoApi.create(
        label: text.trim(),
        date: _dateString,
        scheduleId: scheduleId > 0 ? scheduleId : null,
      );
      if (mounted) {
        setState(() {
          _cardById(scheduleId).items.add(
            _TodoItem(id: newTodo.id, label: text.trim()),
          );
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('할 일 추가에 실패했습니다.')),
        );
      }
    }
  }

  void _deleteTodo(int scheduleId, int todoId) {
    setState(() {
      _cardById(scheduleId).items.removeWhere((i) => i.id == todoId);
    });
    TodoApi.delete(todoId).catchError((_) {
      if (mounted) _loadData();
    });
  }

  // ── Schedule actions ──────────────────────────────────────────────────────

  void _onTimelineBlockTap(int scheduleId) {
    setState(() {
      _activeScheduleId = scheduleId;
      _activeTab = _Tab.todo;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _cardKeys[scheduleId]?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
          alignment: 0.1,
        );
      }
    });
  }

  void _showAddScheduleDialog({int defaultHour = 9}) {
    showDialog<void>(
      context: context,
      builder: (_) => _AddScheduleDialog(
        defaultHour: defaultHour,
        palette: _palette,
        onSave: (title, start, end, color) async {
          try {
            await ScheduleApi.create(
              title: title,
              date: _dateString,
              startHour: start,
              endHour: end,
              colorHex: _colorToHex(color),
            );
            await _loadData();
          } catch (_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('일정 추가에 실패했습니다.')),
              );
            }
          }
        },
      ),
    );
  }

  void _showEditScheduleDialog(int scheduleId) {
    final card = _scheduleCards.firstWhere((c) => c.id == scheduleId);
    showDialog<void>(
      context: context,
      builder: (_) => _EditScheduleDialog(
        card: card,
        onDelete: () async {
          try {
            await ScheduleApi.delete(scheduleId);
            if (mounted && _activeScheduleId == scheduleId) {
              setState(() => _activeScheduleId = null);
            }
            await _loadData();
          } catch (_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('일정 삭제에 실패했습니다.')),
              );
            }
          }
        },
      ),
    );
  }

  void _showAddTransactionDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => _AddTransactionDialog(
        scheduleCards:
            _scheduleCards.where((c) => !c.isStandalone).toList(),
        expenseCategories: _expenseCategories,
        incomeCategories: _incomeCategories,
        onSave: (amount, categoryName, scheduleId) async {
          if (_allCategories.isEmpty) return;
          final cat = _allCategories.firstWhere(
            (c) => c.name == categoryName,
            orElse: () => _allCategories.first,
          );
          try {
            await AccountRecordApi.create(
              amount: amount,
              categoryId: cat.id,
              scheduleId: scheduleId,
              date: _dateString,
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

  // ── Computed stats ────────────────────────────────────────────────────────

  int get _doneTasks => _scheduleCards.fold(
        0,
        (sum, c) => sum + c.items.where((i) => i.isDone).length,
      );

  int get _totalTasks =>
      _scheduleCards.fold(0, (sum, c) => sum + c.items.length);

  int get _totalIncome => _financeEntries
      .where((e) => e.isIncome)
      .fold(0, (sum, e) => sum + e.amount);

  int get _totalExpense => _financeEntries
      .where((e) => !e.isIncome)
      .fold(0, (sum, e) => sum + e.amount.abs());

  int get _netBalance => _totalIncome - _totalExpense;

  // ── Helpers ───────────────────────────────────────────────────────────────

  _ScheduleCardData _cardById(int id) =>
      _scheduleCards.firstWhere((c) => c.id == id);

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 820;

    Widget content;
    if (_isLoading) {
      content =
          const Center(child: CircularProgressIndicator(color: _accentColor));
    } else if (isWide) {
      content = Row(
        children: [
          SizedBox(
            width: 92,
            child: _TimelinePanel(
              blocks: _scheduleBlocks,
              activeScheduleId: _activeScheduleId,
              onBlockTap: _onTimelineBlockTap,
              onEmptyHourTap: (h) => _showAddScheduleDialog(defaultHour: h),
            ),
          ),
          Expanded(child: _buildRightPanel()),
        ],
      );
    } else {
      content = Column(
        children: [
          SizedBox(
            height: 288,
            child: _TimelinePanel(
              blocks: _scheduleBlocks,
              activeScheduleId: _activeScheduleId,
              onBlockTap: _onTimelineBlockTap,
              onEmptyHourTap: (h) => _showAddScheduleDialog(defaultHour: h),
            ),
          ),
          Expanded(child: _buildRightPanel()),
        ],
      );
    }

    return BaseScaffold(
      backgroundColor: _surfaceColor,
      useSafeArea: false,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF1F1),
        elevation: 0,
        centerTitle: true,
        title: Text(
          _formattedDate,
          style: const TextStyle(
            color: Color(0xFF667195),
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _accentColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(child: content),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _primaryColor,
        onPressed: _showFabSheet,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: const AppBottomNavBar(
        currentItem: AppNavItem.home,
        margin: EdgeInsets.fromLTRB(12, 0, 12, 12),
      ),
    );
  }

  void _showFabSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _FabMenuItem(
                icon: Icons.calendar_today_outlined,
                label: '일정 새로 만들기',
                color: _accentColor,
                onTap: () {
                  Navigator.pop(context);
                  _showAddScheduleDialog();
                },
              ),
              const SizedBox(height: 4),
              _FabMenuItem(
                icon: Icons.account_balance_wallet_outlined,
                label: '수입 · 지출 기입',
                color: const Color(0xFF71B35C),
                onTap: () {
                  Navigator.pop(context);
                  _showAddTransactionDialog();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRightPanel() {
    return Column(
      children: [
        _TabRow(
          activeTab: _activeTab,
          onTabChanged: (t) => setState(() => _activeTab = t),
          todoCount: _totalTasks,
          financeCount: _financeEntries.length,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: _DailyStatsRow(
            doneTasks: _doneTasks,
            totalTasks: _totalTasks,
            income: _totalIncome,
            expense: _totalExpense,
            net: _netBalance,
          ),
        ),
        Expanded(
          child: _activeTab == _Tab.todo
              ? _TodoPanel(
                  cards: _scheduleCards,
                  activeScheduleId: _activeScheduleId,
                  cardKeys: _cardKeys,
                  scrollController: _todoScrollCtrl,
                  onToggleTodo: _toggleTodo,
                  onAddTodo: _addTodo,
                  onDeleteTodo: _deleteTodo,
                  onEditSchedule: _showEditScheduleDialog,
                )
              : _FinancePanel(entries: _financeEntries),
        ),
      ],
    );
  }
}

// ─── Timeline Panel ───────────────────────────────────────────────────────────

class _TimelinePanel extends StatelessWidget {
  final List<_ScheduleBlock> blocks;
  final int? activeScheduleId;
  final ValueChanged<int> onBlockTap;
  final ValueChanged<int> onEmptyHourTap;

  const _TimelinePanel({
    required this.blocks,
    required this.activeScheduleId,
    required this.onBlockTap,
    required this.onEmptyHourTap,
  });

  static const double _hourHeight = _DayDetailScreenState._hourHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        border: Border.all(color: const Color(0xFFDDE0E8)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          child: SizedBox(
            width: double.infinity,
            height: 25 * _hourHeight,
            child: Stack(
              children: [
                // Hour grid rows
                ...List.generate(25, (i) {
                  return Positioned(
                    top: i * _hourHeight,
                    left: 0,
                    right: 0,
                    height: _hourHeight,
                    child: GestureDetector(
                      onTap: () => onEmptyHourTap(i),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Colors.blueGrey.shade100,
                              width: 0.8,
                            ),
                          ),
                        ),
                        padding: const EdgeInsets.only(left: 5, top: 3),
                        child: Text(
                          '${i.toString().padLeft(2, '0')}:00',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.blueGrey.shade400,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                // Schedule blocks
                ...blocks.map((block) {
                  final isActive = activeScheduleId == block.id;
                  final duration = block.endHour - block.startHour;
                  return Positioned(
                    top: block.startHour * _hourHeight + 1,
                    left: 4,
                    right: 4,
                    height: duration * _hourHeight - 2,
                    child: GestureDetector(
                      onTap: () => onBlockTap(block.id),
                      child: Container(
                        decoration: BoxDecoration(
                          color: block.color.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(6),
                          border: Border(
                            left: BorderSide(color: block.color, width: 3),
                          ),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: block.color.withValues(alpha: 0.5),
                                    blurRadius: 6,
                                  ),
                                ]
                              : null,
                        ),
                        padding: const EdgeInsets.fromLTRB(5, 4, 4, 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              block.title,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _fmtHour(block.startHour),
                              style: const TextStyle(
                                fontSize: 8,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Tab Row ──────────────────────────────────────────────────────────────────

class _TabRow extends StatelessWidget {
  final _Tab activeTab;
  final ValueChanged<_Tab> onTabChanged;
  final int todoCount;
  final int financeCount;

  const _TabRow({
    required this.activeTab,
    required this.onTabChanged,
    required this.todoCount,
    required this.financeCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0F0),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _TabChip(
            label: '할 일',
            badge: todoCount,
            badgeColor: const Color(0xFFE05353),
            isActive: activeTab == _Tab.todo,
            onTap: () => onTabChanged(_Tab.todo),
          ),
          _TabChip(
            label: '수입 · 지출',
            badge: financeCount,
            badgeColor: const Color(0xFF5AAD72),
            isActive: activeTab == _Tab.finance,
            onTap: () => onTabChanged(_Tab.finance),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final int badge;
  final Color badgeColor;
  final bool isActive;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.badge,
    required this.badgeColor,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                boxShadow: isActive
                    ? const [BoxShadow(color: Colors.black12, blurRadius: 4)]
                    : null,
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isActive
                        ? const Color(0xFF390B0F)
                        : Colors.black45,
                  ),
                ),
              ),
            ),
            if (badge > 0)
              Positioned(
                top: 2,
                right: 8,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$badge',
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Daily Stats Row ──────────────────────────────────────────────────────────

class _DailyStatsRow extends StatelessWidget {
  final int doneTasks;
  final int totalTasks;
  final int income;
  final int expense;
  final int net;

  const _DailyStatsRow({
    required this.doneTasks,
    required this.totalTasks,
    required this.income,
    required this.expense,
    required this.net,
  });

  @override
  Widget build(BuildContext context) {
    final pct = totalTasks > 0
        ? (doneTasks / totalTasks * 100).round()
        : 0;
    return Row(
      children: [
        Expanded(
          child: _StatsCard(
            label: '오늘 할 일 진행',
            mainValue: '$doneTasks',
            unit: '/ ${totalTasks}개',
            icon: Icons.check_circle_outline,
            iconColor: const Color(0xFFE05353),
            iconBg: const Color(0xFFFEE8E8),
            footer: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: totalTasks > 0 ? doneTasks / totalTasks : 0,
                      backgroundColor: const Color(0xFFE0E0E0),
                      color: const Color(0xFFF3A3A4),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$pct%',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE05353),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatsCard(
            label: '일간 가계부 잔액',
            mainValue: net >= 0 ? '+${_fmtNum(net)}' : _fmtNum(net),
            unit: '원',
            icon: Icons.savings_outlined,
            iconColor: net >= 0
                ? const Color(0xFF5AAD72)
                : const Color(0xFFE8A030),
            iconBg: net >= 0
                ? const Color(0xFFE8F7EC)
                : const Color(0xFFFFF3E0),
            footer: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '수입 +${_fmtNum(income)}원',
                        style: const TextStyle(
                          fontSize: 9,
                          color: Color(0xFF5AAD72),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '지출 -${_fmtNum(expense)}원',
                        style: const TextStyle(
                          fontSize: 9,
                          color: Color(0xFFE05353),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatsCard extends StatelessWidget {
  final String label;
  final String mainValue;
  final String unit;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final Widget footer;

  const _StatsCard({
    required this.label,
    required this.mainValue,
    required this.unit,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        border: Border.all(color: const Color(0xFFE4E7EB)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.black45,
                      ),
                    ),
                    const SizedBox(height: 2),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: mainValue,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          TextSpan(
                            text: ' $unit',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.black38,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          footer,
        ],
      ),
    );
  }
}

// ─── Todo Panel ───────────────────────────────────────────────────────────────

class _TodoPanel extends StatelessWidget {
  final List<_ScheduleCardData> cards;
  final int? activeScheduleId;
  final Map<int, GlobalKey> cardKeys;
  final ScrollController scrollController;
  final void Function(int scheduleId, int todoId, bool? checked) onToggleTodo;
  final Future<void> Function(int scheduleId, String text) onAddTodo;
  final void Function(int scheduleId, int todoId) onDeleteTodo;
  final void Function(int scheduleId) onEditSchedule;

  const _TodoPanel({
    required this.cards,
    required this.activeScheduleId,
    required this.cardKeys,
    required this.scrollController,
    required this.onToggleTodo,
    required this.onAddTodo,
    required this.onDeleteTodo,
    required this.onEditSchedule,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      itemCount: cards.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final card = cards[i];
        return _ScheduleCard(
          key: cardKeys[card.id],
          card: card,
          isActive: activeScheduleId == card.id,
          onToggleTodo: onToggleTodo,
          onAddTodo: onAddTodo,
          onDeleteTodo: onDeleteTodo,
          onEditSchedule: card.isStandalone ? null : onEditSchedule,
        );
      },
    );
  }
}

class _ScheduleCard extends StatefulWidget {
  final _ScheduleCardData card;
  final bool isActive;
  final void Function(int scheduleId, int todoId, bool? checked) onToggleTodo;
  final Future<void> Function(int scheduleId, String text) onAddTodo;
  final void Function(int scheduleId, int todoId) onDeleteTodo;
  final void Function(int scheduleId)? onEditSchedule;

  const _ScheduleCard({
    super.key,
    required this.card,
    required this.isActive,
    required this.onToggleTodo,
    required this.onAddTodo,
    required this.onDeleteTodo,
    this.onEditSchedule,
  });

  @override
  State<_ScheduleCard> createState() => _ScheduleCardState();
}

class _ScheduleCardState extends State<_ScheduleCard> {
  final _inputCtrl = TextEditingController();

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final headerColor = card.isStandalone
        ? const Color(0xFFD9C9B0)
        : card.color.withValues(alpha: 0.85);
    final bgColor = card.isStandalone
        ? const Color(0xFFFCF8F2)
        : Color.lerp(card.color, Colors.white, 0.86) ?? Colors.white;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isActive
              ? const Color(0xFFE05353)
              : card.color.withValues(alpha: 0.4),
          width: widget.isActive ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.isActive
                ? const Color(0xFFE05353).withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: widget.isActive ? 10 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(19),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.isStandalone ? 'STANDALONE' : 'SCHEDULE BLOCK',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.8),
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        card.isStandalone
                            ? card.title
                            : '${card.title}  ${_fmtHour(card.startHour)} ~ ${_fmtHour(card.endHour)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.onEditSchedule != null)
                  IconButton(
                    onPressed: () => widget.onEditSchedule!(card.id),
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: Colors.white,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
              ],
            ),
          ),
          // Card body
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (card.items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_box_outline_blank,
                            size: 32,
                            color: Colors.black.withValues(alpha: 0.14),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            '등록된 할 일이 없습니다.',
                            style: TextStyle(fontSize: 12, color: Colors.black38),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...card.items.map(
                    (item) => _TodoItemRow(
                      scheduleId: card.id,
                      item: item,
                      onToggle: widget.onToggleTodo,
                      onDelete: widget.onDeleteTodo,
                    ),
                  ),
                const SizedBox(height: 10),
                // Inline add
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 5, 6, 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _inputCtrl,
                          style: const TextStyle(fontSize: 12),
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            hintText: '새로운 할 일 적어보세요...',
                            hintStyle: TextStyle(
                              fontSize: 12,
                              color: Colors.black38,
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                          onSubmitted: (text) async {
                            await widget.onAddTodo(card.id, text);
                            _inputCtrl.clear();
                          },
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          final text = _inputCtrl.text;
                          await widget.onAddTodo(card.id, text);
                          _inputCtrl.clear();
                        },
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E3A59),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.add,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TodoItemRow extends StatelessWidget {
  final int scheduleId;
  final _TodoItem item;
  final void Function(int scheduleId, int todoId, bool? checked) onToggle;
  final void Function(int scheduleId, int todoId) onDelete;

  const _TodoItemRow({
    required this.scheduleId,
    required this.item,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: item.isDone,
              onChanged: (v) => onToggle(scheduleId, item.id, v),
              activeColor: const Color(0xFF6F7A9B),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.label,
              style: TextStyle(
                fontSize: 12,
                color: item.isDone ? Colors.black38 : Colors.black87,
                decoration: item.isDone ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => onDelete(scheduleId, item.id),
            child: const Icon(
              Icons.remove_circle_outline,
              size: 16,
              color: Colors.black26,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Finance Panel ────────────────────────────────────────────────────────────

class _FinancePanel extends StatefulWidget {
  final List<_FinanceEntry> entries;
  const _FinancePanel({required this.entries});

  @override
  State<_FinancePanel> createState() => _FinancePanelState();
}

class _FinancePanelState extends State<_FinancePanel> {
  _FinanceFilter _filter = _FinanceFilter.all;

  @override
  Widget build(BuildContext context) {
    final filtered = widget.entries.where((e) {
      if (_filter == _FinanceFilter.income) return e.isIncome;
      if (_filter == _FinanceFilter.expense) return !e.isIncome;
      return true;
    }).toList();

    final grouped = <String, List<_FinanceEntry>>{};
    for (final e in filtered) {
      grouped.putIfAbsent(e.blockTitle, () => []).add(e);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: _FilterBar(
            current: _filter,
            onChanged: (f) => setState(() => _filter = f),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 40,
                        color: Colors.black.withValues(alpha: 0.12),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        '작성된 수입·지출 내역이 없습니다.',
                        style: TextStyle(fontSize: 12, color: Colors.black38),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                  children: grouped.entries.map((group) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFEEE0E0)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A000000),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF6B7B7),
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(15),
                              ),
                            ),
                            child: Text(
                              group.key,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          ...group.value.map((e) => _FinanceRow(entry: e)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  final _FinanceFilter current;
  final ValueChanged<_FinanceFilter> onChanged;

  const _FilterBar({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const filters = [
      (_FinanceFilter.all, '전체 보기'),
      (_FinanceFilter.expense, '지출만'),
      (_FinanceFilter.income, '수입만'),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E7EB)),
      ),
      child: Row(
        children: filters.map((pair) {
          final (filter, label) = pair;
          final isActive = current == filter;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isActive
                      ? const [
                          BoxShadow(color: Colors.black12, blurRadius: 3),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isActive ? const Color(0xFF1A1A2E) : Colors.black38,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FinanceRow extends StatelessWidget {
  final _FinanceEntry entry;
  const _FinanceRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: entry.isIncome
                  ? const Color(0xFFE8F7EC)
                  : const Color(0xFFFEE8E8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              entry.isIncome ? Icons.trending_up : Icons.shopping_bag_outlined,
              size: 16,
              color: entry.isIncome
                  ? const Color(0xFF5AAD72)
                  : const Color(0xFFE05353),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              entry.category,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ),
          Text(
            '${entry.isIncome ? '+' : '-'}${_fmtNum(entry.amount.abs())}원',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: entry.isIncome
                  ? const Color(0xFF5AAD72)
                  : const Color(0xFFE05353),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── FAB Menu Item ────────────────────────────────────────────────────────────

class _FabMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _FabMenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Add Schedule Dialog ──────────────────────────────────────────────────────

class _AddScheduleDialog extends StatefulWidget {
  final int defaultHour;
  final List<Color> palette;
  final Future<void> Function(String title, int start, int end, Color color)
  onSave;

  const _AddScheduleDialog({
    required this.defaultHour,
    required this.palette,
    required this.onSave,
  });

  @override
  State<_AddScheduleDialog> createState() => _AddScheduleDialogState();
}

class _AddScheduleDialogState extends State<_AddScheduleDialog> {
  final _titleCtrl = TextEditingController();
  late int _startHour;
  late int _endHour;
  late int _colorIndex;

  @override
  void initState() {
    super.initState();
    _startHour = widget.defaultHour.clamp(0, 23);
    _endHour = (_startHour + 2).clamp(0, 24);
    _colorIndex = widget.defaultHour % widget.palette.length;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF0F0),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    color: Color(0xFFE05353),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '새 일정 추가',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF390B0F),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _DLabel('일정명'),
                  _StyledTextField(
                    controller: _titleCtrl,
                    hint: '예: 아침 공부, 저녁 운동',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _DLabel('시작 시간'),
                            _HourDropdown(
                              value: _startHour,
                              onChanged: (v) => setState(() => _startHour = v),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _DLabel('종료 시간'),
                            _HourDropdown(
                              value: _endHour,
                              onChanged: (v) => setState(() => _endHour = v),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _DLabel('테마 색상'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(widget.palette.length, (i) {
                      return GestureDetector(
                        onTap: () => setState(() => _colorIndex = i),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: widget.palette[i],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: i == _colorIndex
                                  ? Colors.black87
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: i == _colorIndex
                              ? const Icon(
                                  Icons.check,
                                  size: 14,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: () async {
                        final title = _titleCtrl.text.trim();
                        if (title.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('일정 제목을 입력해 주세요.'),
                            ),
                          );
                          return;
                        }
                        final end =
                            _endHour <= _startHour ? _startHour + 1 : _endHour;
                        Navigator.pop(context);
                        await widget.onSave(
                          title,
                          _startHour,
                          end,
                          widget.palette[_colorIndex],
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2E3A59),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('일정 추가하기'),
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

// ─── Edit Schedule Dialog ─────────────────────────────────────────────────────

class _EditScheduleDialog extends StatelessWidget {
  final _ScheduleCardData card;
  final VoidCallback onDelete;

  const _EditScheduleDialog({
    required this.card,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: card.color.withValues(alpha: 0.2),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      Text(
                        '${_fmtHour(card.startHour)} ~ ${_fmtHour(card.endHour)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              children: [
                const Text(
                  '이 일정과 연결된 할 일도 함께 삭제됩니다.',
                  style: TextStyle(fontSize: 12, color: Colors.black45),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onDelete();
                    },
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Color(0xFFE05353),
                    ),
                    label: const Text(
                      '이 일정 삭제하기',
                      style: TextStyle(color: Color(0xFFE05353)),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFFCDD2)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Add Transaction Dialog ───────────────────────────────────────────────────

class _AddTransactionDialog extends StatefulWidget {
  final List<_ScheduleCardData> scheduleCards;
  final List<String> expenseCategories;
  final List<String> incomeCategories;
  final Future<void> Function(int amount, String categoryName, int? scheduleId)
  onSave;

  const _AddTransactionDialog({
    required this.scheduleCards,
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
  int? _linkedScheduleId;

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
            // Type selector tabs
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              child: Row(
                children: [
                  _TypeTab(
                    label: '지출 내역',
                    icon: Icons.trending_down,
                    isActive: _isExpense,
                    activeColor: const Color(0xFFE05353),
                    onTap: () => setState(() {
                      _isExpense = true;
                      _selectedCategory =
                          widget.expenseCategories.isNotEmpty
                              ? widget.expenseCategories.first
                              : '기타';
                    }),
                  ),
                  _TypeTab(
                    label: '수입 내역',
                    icon: Icons.trending_up,
                    isActive: !_isExpense,
                    activeColor: const Color(0xFF5AAD72),
                    onTap: () => setState(() {
                      _isExpense = false;
                      _selectedCategory =
                          widget.incomeCategories.isNotEmpty
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
                  // Amount input
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE0E3E8)),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _isExpense ? '−' : '+',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: activeColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: TextField(
                            controller: _amountCtrl,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A2E),
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: '0',
                              hintStyle: TextStyle(
                                fontSize: 22,
                                color: Colors.black26,
                              ),
                            ),
                          ),
                        ),
                        const Text(
                          '원',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black38,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _DLabel('카테고리'),
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
                  if (widget.scheduleCards.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const _DLabel('연결 일정 (선택)'),
                    DropdownButtonFormField<int?>(
                      value: _linkedScheduleId,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF8F9FB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE0E3E8)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE0E3E8)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text(
                            '연결 없음 (일정 외)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black45,
                            ),
                          ),
                        ),
                        ...widget.scheduleCards.map(
                          (c) => DropdownMenuItem<int?>(
                            value: c.id,
                            child: Text(
                              '${c.title} (${_fmtHour(c.startHour)}~${_fmtHour(c.endHour)})',
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _linkedScheduleId = v),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: () async {
                        final amount =
                            int.tryParse(_amountCtrl.text.trim()) ?? 0;
                        if (amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('금액을 입력해 주세요.')),
                          );
                          return;
                        }
                        Navigator.pop(context);
                        await widget.onSave(
                          amount,
                          _selectedCategory,
                          _linkedScheduleId,
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: activeColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _TypeTab({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isActive
                ? activeColor.withValues(alpha: 0.08)
                : const Color(0xFFF5F7F8),
            border: Border(
              bottom: BorderSide(
                color: isActive ? activeColor : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive ? activeColor : Colors.black38,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isActive ? activeColor : Colors.black38,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Shared dialog widgets ────────────────────────────────────────────────────

class _DLabel extends StatelessWidget {
  final String text;
  const _DLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.black54,
        ),
      ),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const _StyledTextField({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black26),
        filled: true,
        fillColor: const Color(0xFFF8F9FB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E3E8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E3E8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF3A3A4), width: 1.5),
        ),
      ),
    );
  }
}

class _HourDropdown extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _HourDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      value: value,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF8F9FB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E3E8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E3E8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF3A3A4), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
      items: List.generate(
        25,
        (i) => DropdownMenuItem(value: i, child: Text(_fmtHour(i))),
      ),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

// ─── Data classes ─────────────────────────────────────────────────────────────

class _ScheduleBlock {
  final int id;
  final String title;
  final int startHour;
  final int endHour;
  final Color color;

  const _ScheduleBlock({
    required this.id,
    required this.title,
    required this.startHour,
    required this.endHour,
    required this.color,
  });
}

class _ScheduleCardData {
  final int id;
  final String title;
  final int startHour;
  final int endHour;
  final Color color;
  final List<_TodoItem> items;
  final bool isStandalone;

  _ScheduleCardData({
    required this.id,
    required this.title,
    required this.startHour,
    required this.endHour,
    required this.color,
    required this.items,
    this.isStandalone = false,
  });
}

class _TodoItem {
  final int id;
  String label;
  bool isDone;

  _TodoItem({required this.id, required this.label, this.isDone = false});
}

class _FinanceEntry {
  final String category;
  final int amount;
  final bool isIncome;
  final String blockTitle;

  const _FinanceEntry({
    required this.category,
    required this.amount,
    required this.isIncome,
    required this.blockTitle,
  });
}

// ─── Global helpers ───────────────────────────────────────────────────────────

String _fmtHour(int hour) => '${hour.toString().padLeft(2, '0')}:00';

String _fmtNum(int n) {
  final s = n.abs().toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

Color _hexToColor(String hex) {
  final clean = hex.replaceAll('#', '');
  final value = int.parse(
    clean.length == 6 ? 'FF$clean' : clean,
    radix: 16,
  );
  return Color(value);
}

String _colorToHex(Color color) {
  final rgb = color.toARGB32() & 0xFFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}
