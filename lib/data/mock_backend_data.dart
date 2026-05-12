import 'package:flutter/material.dart';

/// ERD 기준의 백엔드 계약을 프런트에서 먼저 맞춰보기 위한 임시 데이터 레이어입니다.
/// TODO(backend): 백엔드 API 연동 완료 후 이 파일의 mock* 컬렉션과 조회 함수를 제거하세요.
class MockBackendData {
  const MockBackendData._();

  /// TODO(backend): 로그인/회원 조회 API 응답으로 교체해야 하는 목 회원 데이터입니다.
  static const Member currentMember = Member(
    id: 1,
    email: 'segye@example.com',
    password: 'mock-password',
  );

  /// TODO(backend): 결제수단 CRUD API 응답으로 교체해야 하는 목 결제수단 데이터입니다.
  static const List<PaymentMethod> paymentMethods = [
    PaymentMethod(id: 1, memberId: 1, name: '체크카드'),
    PaymentMethod(id: 2, memberId: 1, name: '현금'),
  ];

  /// TODO(backend): 카테고리 CRUD API 응답으로 교체해야 하는 목 카테고리 데이터입니다.
  static const List<Category> categories = [
    Category(id: 1, name: '식비', type: CategoryType.card),
    Category(id: 2, name: '교통', type: CategoryType.card),
    Category(id: 3, name: '월급', type: CategoryType.card),
    Category(id: 4, name: '운동', type: CategoryType.schedule),
    Category(id: 5, name: '약속', type: CategoryType.schedule),
  ];

  /// TODO(backend): 일정 CRUD API 응답으로 교체해야 하는 목 일정 데이터입니다.
  static final List<Schedule> schedules = [
    Schedule(
      id: 1,
      memberId: 1,
      title: '아침 운동',
      startTime: _todayAt(hour: 7),
      endTime: _todayAt(hour: 9, minute: 30),
    ),
    Schedule(
      id: 2,
      memberId: 1,
      title: '친구 약속',
      startTime: _todayAt(hour: 11),
      endTime: _todayAt(hour: 15, minute: 30),
    ),
    Schedule(
      id: 3,
      memberId: 1,
      title: '프로젝트 회의',
      startTime: _todayAt(dayOffset: 1, hour: 10),
      endTime: _todayAt(dayOffset: 1, hour: 11),
    ),
  ];

  /// TODO(backend): 할 일 CRUD API 응답으로 교체해야 하는 목 할 일 데이터입니다.
  static const List<Task> tasks = [
    Task(id: 1, scheduleId: 1, content: '스트레칭 10분', isCompleted: false),
    Task(id: 2, scheduleId: 1, content: '러닝 30분', isCompleted: true),
    Task(id: 3, scheduleId: 2, content: '카페 예약 확인', isCompleted: false),
    Task(id: 4, scheduleId: 3, content: '회의 자료 정리', isCompleted: false),
  ];

  /// TODO(backend): 수입/지출 CRUD API 응답으로 교체해야 하는 목 가계부 데이터입니다.
  static final List<AccountRecord> accountRecords = [
    AccountRecord(
      id: 1,
      memberId: 1,
      amount: 3200000,
      transactionTime: _todayAt(hour: 9),
      paymentMethodId: 1,
      categoryId: 3,
    ),
    AccountRecord(
      id: 2,
      memberId: 1,
      amount: -12000,
      transactionTime: _todayAt(hour: 12, minute: 20),
      paymentMethodId: 1,
      categoryId: 1,
    ),
    AccountRecord(
      id: 3,
      memberId: 1,
      amount: -3500,
      transactionTime: _todayAt(hour: 18, minute: 10),
      paymentMethodId: 2,
      categoryId: 2,
    ),
    AccountRecord(
      id: 4,
      memberId: 1,
      amount: -5600,
      transactionTime: _todayAt(dayOffset: 1, hour: 8, minute: 40),
      paymentMethodId: 1,
      categoryId: 1,
    ),
  ];

  static List<Schedule> schedulesByDate(DateTime date) => schedules
      .where((schedule) => _isSameDate(schedule.startTime, date))
      .toList();

  static List<Task> tasksByDate(DateTime date) {
    final scheduleIds = schedulesByDate(date)
        .map((schedule) => schedule.id)
        .toSet();
    return tasks.where((task) => scheduleIds.contains(task.scheduleId)).toList();
  }

  static List<AccountRecord> accountRecordsByDate(DateTime date) => accountRecords
      .where((record) => _isSameDate(record.transactionTime, date))
      .toList();

  static Category categoryById(int categoryId) => categories.firstWhere(
        (category) => category.id == categoryId,
        orElse: () =>
            const Category(id: 0, name: '미분류', type: CategoryType.card),
      );

  static PaymentMethod paymentMethodById(int paymentMethodId) =>
      paymentMethods.firstWhere(
        (method) => method.id == paymentMethodId,
        orElse: () => const PaymentMethod(id: 0, memberId: 0, name: '미등록'),
      );

  static DateTime _todayAt({
    int dayOffset = 0,
    required int hour,
    int minute = 0,
  }) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + dayOffset, hour, minute);
  }

  static bool _isSameDate(DateTime left, DateTime right) =>
      left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

class Member {
  final int id;
  final String email;
  final String password;

  const Member({required this.id, required this.email, required this.password});

  String get nickname => email.split('@').first;
}

class PaymentMethod {
  final int id;
  final int memberId;
  final String name;

  const PaymentMethod({
    required this.id,
    required this.memberId,
    required this.name,
  });
}

enum CategoryType { card, schedule }

class Category {
  final int id;
  final String name;
  final CategoryType type;

  const Category({required this.id, required this.name, required this.type});
}

class Schedule {
  final int id;
  final int memberId;
  final String title;
  final DateTime startTime;
  final DateTime endTime;

  const Schedule({
    required this.id,
    required this.memberId,
    required this.title,
    required this.startTime,
    required this.endTime,
  });

  String get timeRange => '${_timeText(startTime)} - ${_timeText(endTime)}';

  static String _timeText(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';
}

class Task {
  final int id;
  final int scheduleId;
  final String content;
  final bool isCompleted;

  const Task({
    required this.id,
    required this.scheduleId,
    required this.content,
    required this.isCompleted,
  });
}

class AccountRecord {
  final int id;
  final int memberId;
  final int amount;
  final DateTime transactionTime;
  final int paymentMethodId;
  final int categoryId;

  const AccountRecord({
    required this.id,
    required this.memberId,
    required this.amount,
    required this.transactionTime,
    required this.paymentMethodId,
    required this.categoryId,
  });

  Color get amountColor =>
      amount >= 0 ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C);
}
