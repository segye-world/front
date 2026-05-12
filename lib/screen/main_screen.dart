import 'package:flutter/material.dart';

import '../data/mock_backend_data.dart';
import '../routes/routes.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const _primaryPink = Color(0xFFF7A5A5);

  // 앱에 새로 진입하면 홈 캘린더가 항상 오늘 날짜를 선택하도록 초기화합니다.
  late DateTime _selectedDate = _dateOnly(DateTime.now());
  _MainTab _selectedTab = _MainTab.schedule;

  // 시간 값 때문에 같은 날짜 비교가 어긋나지 않도록 날짜만 남깁니다.
  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  String _formatDate(DateTime date) => '${date.month}월 ${date.day}일';

  DatePickerThemeData _buildDatePickerTheme() {
    return DatePickerThemeData(
      // 선택된 날짜는 글씨색만 바꾸지 않고 배경색을 채워 사용자가 선택 이동을 명확히 볼 수 있게 합니다.
      dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return _primaryPink;
        return null;
      }),
      dayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        if (states.contains(WidgetState.disabled)) return Colors.black26;
        return Colors.black87;
      }),
      todayBorder: const BorderSide(width: 1.4, color: _primaryPink),
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
            onPrimary: Colors.white,
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
            Text(
              MockBackendData.currentMember.nickname,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
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
                        // 선택 날짜를 상태로 관리해서 다른 날짜를 누르면 핑크 배경도 해당 날짜로 이동합니다.
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        currentDate: _dateOnly(DateTime.now()),
                        onDateChanged: (date) {
                          setState(() => _selectedDate = _dateOnly(date));
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDate(_selectedDate),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_right, size: 18),
                              onPressed: () {
                                Navigator.of(context).pushNamed(
                                  Routes.dayDetail,
                                  arguments: _selectedDate,
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
            _BottomNavBar(primaryPink: _primaryPink),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTabContent() {
    // TODO(backend): 아래 조회는 임시 목데이터 필터링이므로 백엔드 API 호출로 교체해야 합니다.
    final schedules = MockBackendData.schedulesByDate(_selectedDate);
    final tasks = MockBackendData.tasksByDate(_selectedDate);
    final records = MockBackendData.accountRecordsByDate(_selectedDate);

    switch (_selectedTab) {
      case _MainTab.schedule:
        if (schedules.isEmpty) return [_EmptyState(message: '등록된 일정이 없어요')];
        return schedules
            .asMap()
            .entries
            .map((entry) => _ScheduleCard(schedule: entry.value, index: entry.key))
            .toList();
      case _MainTab.todo:
        if (tasks.isEmpty) return [_EmptyState(message: '등록된 할 일이 없어요')];
        return tasks.map((task) => _TodoItemTile(task: task)).toList();
      case _MainTab.consumption:
        return [
          const Text('오늘의 소비', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (records.isEmpty) const _EmptyState(message: '등록된 수입/지출 내역이 없어요'),
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

  const _CategoryTabs({
    required this.primaryPink,
    required this.selectedTab,
    required this.onTabSelected,
  });

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

  const _TabChip({
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

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
  static const _scheduleColors = [
    Color(0xFFF7A5A5),
    Color(0xFF1F1F1F),
    Color(0xFFFFD1D1),
  ];

  final Schedule schedule;
  final int index;

  const _ScheduleCard({required this.schedule, required this.index});

  @override
  Widget build(BuildContext context) {
    final color = _scheduleColors[index % _scheduleColors.length];
    final textColor =
        color.computeLuminance() < 0.5 ? Colors.white : Colors.black87;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            schedule.title,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            schedule.timeRange,
            style: TextStyle(color: textColor, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _AccountRecordTile extends StatelessWidget {
  final AccountRecord record;
  const _AccountRecordTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final category = MockBackendData.categoryById(record.categoryId);
    final paymentMethod =
        MockBackendData.paymentMethodById(record.paymentMethodId);
    final amountText = record.amount >= 0 ? '+${record.amount}' : '${record.amount}';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category.name,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                paymentMethod.name,
                style: const TextStyle(fontSize: 10, color: Colors.black54),
              ),
            ],
          ),
          Text(
            amountText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: record.amountColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _TodoItemTile extends StatelessWidget {
  final Task task;
  const _TodoItemTile({required this.task});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEFEF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: task.isCompleted
                  ? const Color(0xFFF7A5A5)
                  : Colors.transparent,
              border: Border.all(color: Colors.black45, width: 1),
              borderRadius: BorderRadius.circular(3),
            ),
            child: task.isCompleted
                ? const Icon(Icons.check, size: 10, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              task.content,
              style: TextStyle(
                fontSize: 12,
                color: Colors.black87,
                decoration: task.isCompleted
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
            ),
          ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(fontSize: 12, color: Colors.black45),
        ),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final Color primaryPink;

  const _BottomNavBar({required this.primaryPink});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: primaryPink,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _BottomNavItem(
            label: 'CASH',
            isActive: false,
            onTap: () => Navigator.of(context).pushNamed(Routes.cashDetail),
          ),
          _BottomNavItem(
            label: 'HOME',
            isActive: true,
            onTap: () => Navigator.of(context).pushNamed(Routes.main),
          ),
          _BottomNavItem(
            label: 'MYPAGE',
            isActive: false,
            onTap: () => Navigator.of(context).pushNamed(Routes.mypage),
          ),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFF7A5A5) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
