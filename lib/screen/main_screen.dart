import 'package:flutter/material.dart';
import '../routes/routes.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const _userName = '세계';
  static const _primaryPink = Color(0xFFF7A5A5);
  static const _initialDate = DateTime(2025, 9, 9);

  DateTime _selectedDate = _initialDate;

  final List<_ScheduleItem> _scheduleItems = [
    _ScheduleItem(
      label: '아침 운동',
      timeRange: '07:00 - 09:30',
      color: _primaryPink,
    ),
    _ScheduleItem(
      label: '친구 약속',
      timeRange: '11:00 - 15:30',
      color: const Color(0xFF1F1F1F),
    ),
  ];

  final List<_AccountRecord> _records = [
    _AccountRecord(title: '월급', category: '수입', amount: 3200000),
    _AccountRecord(title: '점심', category: '지출', amount: -12000),
    _AccountRecord(title: '교통', category: '지출', amount: -3500),
  ];

  String _formatDate(DateTime date) {
    return '${date.month}월 ${date.day}일';
  }

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
                    CalendarDatePicker(
                      initialDate: _initialDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      currentDate: _selectedDate,
                      onDateChanged: (date) {
                        setState(() {
                          _selectedDate = date;
                        });
                      },
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
                                Navigator.of(context)
                                    .pushNamed(Routes.dayDetail);
                              },
                            ),
                            const Icon(Icons.notifications_none, size: 18),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _CategoryTabs(primaryPink: _primaryPink),
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
            _BottomNavBar(primaryPink: _primaryPink),
          ],
        ),
      ),
    );
  }
}

class _CategoryTabs extends StatelessWidget {
  final Color primaryPink;

  const _CategoryTabs({required this.primaryPink});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TabChip(label: '일정', isActive: true, activeColor: primaryPink),
        const SizedBox(width: 8),
        _TabChip(label: '수입', isActive: false, activeColor: primaryPink),
        const SizedBox(width: 8),
        _TabChip(label: '소비', isActive: false, activeColor: primaryPink),
      ],
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color activeColor;

  const _TabChip({
    required this.label,
    required this.isActive,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? activeColor : const Color(0xFFF2F2F2),
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
