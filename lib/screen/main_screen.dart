import 'package:flutter/material.dart';

import '../data/mock_erd_repository.dart';
import '../routes/routes.dart';
import '../widgets/template/bottom_nav_layout.dart';

class MainScreen extends StatefulWidget {
  // ✅ 로그인 화면에서 전달된 이메일을 받아 MyPage에 전달하기 위한 필드
  final String loginEmail;

  const MainScreen({super.key, this.loginEmail = ''});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const _userName = '세계';
  static const _primaryPink = Color(0xFFF7A5A5);
  final MockErdRepository _repository = MockErdRepository.instance;

  late DateTime _selectedDate;
  _MainTab _selectedTab = _MainTab.schedule;

  @override
  void initState() {
    super.initState();
    // ✅ 앱에 새로 진입할 때마다 홈 캘린더의 선택 날짜를 오늘로 초기화합니다.
    _selectedDate = DateUtils.dateOnly(DateTime.now());
  }

  String _formatDate(DateTime date) => '${date.month}월 ${date.day}일';

  DatePickerThemeData _buildDatePickerTheme() {
    return DatePickerThemeData(
      // ✅ 선택된 날짜: 불투명한 원형 배경 + 진한 글자색으로 가시성 개선
      dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          // ✅ 선택된 날짜 자체의 배경색을 채워 다른 날짜 선택 시 표시가 함께 이동합니다.
          return _primaryPink;
        }
        return null;
      }),
      dayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        if (states.contains(WidgetState.disabled)) return Colors.black26;
        return Colors.black87;
      }),

      // ✅ 오늘 날짜: 핑크 테두리 + 글자색
      todayBorder: const BorderSide(width: 1.6, color: _primaryPink),
      dayShape: WidgetStateProperty.all(const CircleBorder()),
      todayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        return _primaryPink;
      }),

      weekdayStyle: const TextStyle(fontSize: 11, color: Colors.black54),
      dayStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      headerForegroundColor: Colors.black87,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themed = Theme.of(context).copyWith(
      colorScheme: Theme.of(context).colorScheme.copyWith(
        primary: _primaryPink,
        onPrimary: Colors.black87,
        onSurface: Colors.black87,
      ),
      datePickerTheme: _buildDatePickerTheme(),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Text(_userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Theme(
                      data: themed,
                      child: CalendarDatePicker(
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        currentDate: DateUtils.dateOnly(DateTime.now()),
                        onDateChanged: (date) {
                          // ✅ 선택 일자 상태를 갱신하여 배경 표시와 하단 CRUD 목록을 모두 동기화합니다.
                          setState(() => _selectedDate = DateUtils.dateOnly(date));
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDate(_selectedDate),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_right, size: 18),
                              onPressed: () {
                                Navigator.of(context).pushNamed(
                                  Routes.dayDetail,
                                  arguments: {'loginEmail': widget.loginEmail, 'selectedDate': _selectedDate},
                                );
                              },
                            ),
                            const Icon(Icons.notifications_none, size: 18),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _CategoryTabs(
                      primaryPink: _primaryPink,
                      selectedTab: _selectedTab,
                      onTabSelected: (tab) {
                        setState(() => _selectedTab = tab);
                      },
                    ),
                    const SizedBox(height: 10),
                    Expanded(child: ListView(children: _buildTabContent())),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // ✅ 메인/마이페이지/기타 화면에서 같은 하단 탭을 사용합니다.
            BottomNavLayout(loginEmail: widget.loginEmail, currentTab: BottomNavType.home),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTabContent() {
    // ✅ 로그인 이메일로 회원 고유번호(id)를 찾아 일정/할 일/소비 항목을 모두 회원별로 조회합니다.
    final id = _repository.idForEmail(widget.loginEmail);
    final schedules = _repository.schedulesByDate(_selectedDate, id: id);
    final tasks = _repository.tasksByDate(_selectedDate, id: id);
    final records = _repository.accountRecordsByDate(_selectedDate, id: id);

    switch (_selectedTab) {
      case _MainTab.schedule:
        if (schedules.isEmpty) return [_EmptyState(message: '${_formatDate(_selectedDate)} 일정이 없어요.')];
        return [...schedules.map((item) => _ScheduleCard(item: item))];
      case _MainTab.todo:
        if (tasks.isEmpty) return [_EmptyState(message: '${_formatDate(_selectedDate)} 할 일이 없어요.')];
        return [...tasks.map((item) => _TodoItemTile(item: item))];
      case _MainTab.consumption:
        return [
          Text('${_formatDate(_selectedDate)} 소비', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (records.isEmpty)
            _EmptyState(message: '${_formatDate(_selectedDate)} 수입/지출 내역이 없어요.')
          else
            ...records.map((record) => _AccountRecordTile(record: record)),
        ];
    }
  }
}

enum _MainTab { schedule, todo, consumption }

class _CategoryTabs extends StatelessWidget {
  final Color primaryPink;
  final _MainTab selectedTab;
  final ValueChanged<_MainTab> onTabSelected;

  const _CategoryTabs({required this.primaryPink, required this.selectedTab, required this.onTabSelected});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TabChip(
          label: '일정',
          isActive: selectedTab == _MainTab.schedule,
          activeColor: primaryPink,
          onTap: () => onTabSelected(_MainTab.schedule),
        ),
        const SizedBox(width: 16),
        _TabChip(
          label: '할 일',
          isActive: selectedTab == _MainTab.todo,
          activeColor: primaryPink,
          onTap: () => onTabSelected(_MainTab.todo),
        ),
        const SizedBox(width: 16),
        _TabChip(
          label: '소비',
          isActive: selectedTab == _MainTab.consumption,
          activeColor: primaryPink,
          onTap: () => onTabSelected(_MainTab.consumption),
        ),
      ],
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _TabChip({required this.label, required this.isActive, required this.activeColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: isActive ? activeColor : Colors.transparent, width: 2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isActive ? Colors.black87 : Colors.black45,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final ScheduleWithTasks item;
  const _ScheduleCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final timeRange = '${_formatTime(item.schedule.startTime)} - ${_formatTime(item.schedule.endTime)}';
    final color = item.schedule.scheduleId.isOdd ? _MainScreenState._primaryPink : const Color(0xFF1F1F1F);
    final textColor = color.computeLuminance() < 0.5 ? Colors.white : Colors.black87;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            item.schedule.title,
            style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          Text(timeRange, style: TextStyle(color: textColor, fontSize: 11)),
        ],
      ),
    );
  }
}

class _AccountRecordTile extends StatelessWidget {
  final AccountRecordView record;
  const _AccountRecordTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final amount = record.record.amount;
    final amountText = amount >= 0 ? '+$amount' : '$amount';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFFF8F8F8), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(record.category.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(record.paymentMethod.name, style: const TextStyle(fontSize: 10, color: Colors.black54)),
            ],
          ),
          Text(
            amountText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: amount >= 0 ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodoItemTile extends StatelessWidget {
  final Task item;
  const _TodoItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFFFFEFEF), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: item.isCompleted ? const Color(0xFFF7A5A5) : Colors.transparent,
              border: Border.all(color: Colors.black45, width: 1),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(item.content, style: const TextStyle(fontSize: 12, color: Colors.black87))),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18),
      alignment: Alignment.center,
      child: Text(message, style: const TextStyle(fontSize: 12, color: Colors.black45)),
    );
  }
}

String _formatTime(DateTime time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
