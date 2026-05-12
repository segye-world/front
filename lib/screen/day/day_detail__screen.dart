import 'package:flutter/material.dart';

import '../../data/mock_erd_repository.dart';
import '../../widgets/template/base_scaffold.dart';
import '../../widgets/template/bottom_nav_layout.dart';

class DayDetailScreen extends StatelessWidget {
  final String loginEmail;
  final DateTime? selectedDate;

  const DayDetailScreen({super.key, this.loginEmail = '', this.selectedDate});

  @override
  Widget build(BuildContext context) {
    final date = DateUtils.dateOnly(selectedDate ?? DateTime.now());
    final schedules = MockErdRepository.instance.schedulesByDate(date);

    return BaseScaffold(
      title: 'Day Detail',
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  '${date.month}월 ${date.day}일 일정',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                // ✅ ERD의 Schedule(일정)과 Task(할일) 관계를 목데이터로 먼저 노출합니다.
                if (schedules.isEmpty)
                  const _EmptyDetailCard(message: '선택한 날짜의 일정이 없습니다.')
                else
                  ...schedules.map((scheduleWithTasks) => _ScheduleDetailCard(item: scheduleWithTasks)),
              ],
            ),
          ),
          // ✅ 모든 화면에서 하단 탭을 공통으로 유지
          BottomNavLayout(loginEmail: loginEmail, currentTab: BottomNavType.home),
        ],
      ),
    );
  }
}

class _ScheduleDetailCard extends StatelessWidget {
  final ScheduleWithTasks item;

  const _ScheduleDetailCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.schedule.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            '${_formatTime(item.schedule.startTime)} - ${_formatTime(item.schedule.endTime)}',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 10),
          if (item.tasks.isEmpty)
            const Text('연결된 할 일이 없습니다.', style: TextStyle(fontSize: 12, color: Colors.black45))
          else
            ...item.tasks.map(
              (task) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                      size: 16,
                      color: const Color(0xFFF7A5A5),
                    ),
                    const SizedBox(width: 6),
                    Expanded(child: Text(task.content, style: const TextStyle(fontSize: 12))),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyDetailCard extends StatelessWidget {
  final String message;

  const _EmptyDetailCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Text(message, style: const TextStyle(color: Colors.black45)),
    );
  }
}

String _formatTime(DateTime time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
