import 'package:flutter/material.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  static const _userName = '세계';
  static const _selectedDate = '9월 9일';

  static final List<_ScheduleItem> _scheduleItems = [
    _ScheduleItem(
      label: '아침 운동',
      timeRange: '07:00 - 09:30',
      color: const Color(0xFFF28B82),
    ),
    _ScheduleItem(
      label: '친구 약속',
      timeRange: '11:00 - 15:30',
      color: const Color(0xFF1F1F1F),
    ),
  ];

  static final List<_AccountRecord> _records = [
    _AccountRecord(title: '월급', category: '수입', amount: 3200000),
    _AccountRecord(title: '점심', category: '지출', amount: -12000),
    _AccountRecord(title: '교통', category: '지출', amount: -3500),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Text(
              _userName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
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
                    _CalendarHeader(),
                    const SizedBox(height: 12),
                    _CalendarGrid(),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedDate,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Icon(Icons.notifications_none, size: 18),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _CategoryTabs(),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView(
                        children: [
                          ..._scheduleItems.map(
                            (item) => _ScheduleCard(item: item),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '오늘의 수입/지출',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._records.map(
                            (record) => _AccountRecordTile(record: record),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const _BottomNavBar(),
          ],
        ),
      ),
    );
  }
}

class _CalendarHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Icon(Icons.chevron_left, size: 20),
        Row(
          children: [
            _DropdownChip(label: 'Sep'),
            const SizedBox(width: 8),
            _DropdownChip(label: '2025'),
          ],
        ),
        const Icon(Icons.chevron_right, size: 20),
      ],
    );
  }
}

class _DropdownChip extends StatelessWidget {
  final String label;
  const _DropdownChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const Icon(Icons.expand_more, size: 14),
        ],
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const weekdays = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
    const days = [
      '',
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '10',
      '11',
      '12',
      '13',
      '14',
      '15',
      '16',
      '17',
      '18',
      '19',
      '20',
      '21',
      '22',
      '23',
      '24',
      '25',
      '26',
      '27',
      '28',
      '29',
      '30',
      '1',
      '2',
      '3',
      '4',
    ];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: weekdays
              .map(
                (day) => Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 0,
          runSpacing: 6,
          children: days.asMap().entries.map((entry) {
            final index = entry.key;
            final day = entry.value;
            final isSelected = day == '9';
            final isMuted = day.isEmpty || index >= 30;
            return SizedBox(
              width: 36,
              child: Center(
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFF28B82) : null,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 12,
                      color: isMuted
                          ? Colors.black26
                          : isSelected
                              ? Colors.white
                              : Colors.black87,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _CategoryTabs extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TabChip(label: '일정', isActive: true),
        const SizedBox(width: 8),
        _TabChip(label: '수입', isActive: false),
        const SizedBox(width: 8),
        _TabChip(label: '소비', isActive: false),
      ],
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool isActive;

  const _TabChip({required this.label, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFF28B82) : const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isActive ? Colors.white : Colors.black54,
          fontWeight: FontWeight.w500,
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
      decoration: BoxDecoration(
        color: item.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            item.label,
            style: TextStyle(
              color: item.textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            item.timeRange,
            style: TextStyle(
              color: item.textColor,
              fontSize: 11,
            ),
          ),
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
    final amountText = record.amount >= 0
        ? '+${record.amount.toString()}'
        : record.amount.toString();

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
                record.title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                record.category,
                style: const TextStyle(fontSize: 10, color: Colors.black54),
              ),
            ],
          ),
          Text(
            amountText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: record.amount >= 0
                  ? const Color(0xFF1B5E20)
                  : const Color(0xFFB71C1C),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF28B82),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: const [
          _BottomNavItem(label: 'CASH', isActive: false),
          _BottomNavItem(label: 'HOME', isActive: true),
          _BottomNavItem(label: 'MYPAGE', isActive: false),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final String label;
  final bool isActive;

  const _BottomNavItem({required this.label, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEF7D75) : Colors.transparent,
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
    );
  }
}

class _ScheduleItem {
  final String label;
  final String timeRange;
  final Color color;

  const _ScheduleItem({
    required this.label,
    required this.timeRange,
    required this.color,
  });

  Color get textColor {
    if (color.computeLuminance() < 0.5) {
      return Colors.white;
    }
    return Colors.black87;
  }
}

class _AccountRecord {
  final String title;
  final String category;
  final int amount;

  const _AccountRecord({
    required this.title,
    required this.category,
    required this.amount,
  });
}
