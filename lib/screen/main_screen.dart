import 'package:flutter/material.dart';

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
  static final DateTime _initialDate = DateTime(2025, 9, 9);

  late DateTime _selectedDate = _initialDate;
  _MainTab _selectedTab = _MainTab.schedule;

  final List<_ScheduleItem> _scheduleItems = [
    _ScheduleItem(label: '아침 운동', timeRange: '07:00 - 09:30', color: _primaryPink),
    _ScheduleItem(label: '친구 약속', timeRange: '11:00 - 15:30', color: const Color(0xFF1F1F1F)),
  ];

  final List<_AccountRecord> _records = [
    _AccountRecord(title: '월급', category: '수입', amount: 3200000),
    _AccountRecord(title: '점심', category: '지출', amount: -12000),
    _AccountRecord(title: '교통', category: '지출', amount: -3500),
  ];

  final List<_TodoItem> _todoItems = [
    _TodoItem(label: '백준 알고리즘 실버 2문제'),
    _TodoItem(label: '두잉코딩 영어 1일차'),
  ];

  String _formatDate(DateTime date) => '${date.month}월 ${date.day}일';

  DatePickerThemeData _buildDatePickerTheme() {
    return DatePickerThemeData(
      // ✅ 선택된 날짜: 불투명한 원형 배경 + 진한 글자색으로 가시성 개선
      dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _primaryPink.withValues(alpha: 0.45);
        }
        return null;
      }),
      dayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.black87;
        if (states.contains(WidgetState.disabled)) return Colors.black26;
        return Colors.black87;
      }),

      // ✅ 오늘 날짜: 핑크 테두리 + 글자색
      todayBorder: const BorderSide(width: 1.6, color: _primaryPink),
      todayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.black87;
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
                        currentDate: DateTime.now(),
                        onDateChanged: (date) {
                          // ✅ 선택 일자 상태를 갱신하여 하단 날짜 텍스트도 동기화
                          setState(() => _selectedDate = date);
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
                                  arguments: {'loginEmail': widget.loginEmail},
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
    switch (_selectedTab) {
      case _MainTab.schedule:
        return [..._scheduleItems.map((item) => _ScheduleCard(item: item))];
      case _MainTab.todo:
        return [..._todoItems.map((item) => _TodoItemTile(item: item))];
      case _MainTab.consumption:
        return [
          const Text('오늘의 소비', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ..._records.map((record) => _AccountRecordTile(record: record)),
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
  final _ScheduleItem item;
  const _ScheduleCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: item.color, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            item.label,
            style: TextStyle(color: item.textColor, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          Text(item.timeRange, style: TextStyle(color: item.textColor, fontSize: 11)),
        ],
      ),
    );
  }
}

class _AccountRecordTile extends StatelessWidget {
  final _AccountRecord record;
  const _AccountRecordTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final amountText = record.amount >= 0 ? '+${record.amount}' : '${record.amount}';

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
              Text(record.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(record.category, style: const TextStyle(fontSize: 10, color: Colors.black54)),
            ],
          ),
          Text(
            amountText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: record.amount >= 0 ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodoItemTile extends StatelessWidget {
  final _TodoItem item;
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
              border: Border.all(color: Colors.black45, width: 1),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(item.label, style: const TextStyle(fontSize: 12, color: Colors.black87))),
        ],
      ),
    );
  }
}

class _ScheduleItem {
  final String label;
  final String timeRange;
  final Color color;

  const _ScheduleItem({required this.label, required this.timeRange, required this.color});

  Color get textColor => color.computeLuminance() < 0.5 ? Colors.white : Colors.black87;
}

class _AccountRecord {
  final String title;
  final String category;
  final int amount;

  const _AccountRecord({required this.title, required this.category, required this.amount});
}

class _TodoItem {
  final String label;

  const _TodoItem({required this.label});
}
