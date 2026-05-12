/// ERD 기준으로 프론트에서 사용하는 임시 데이터 모델과 저장소입니다.
///
/// 백엔드 연동 시 이 파일의 MockErdRepository 내부 목데이터/메서드를 API 호출 레이어로 교체하세요.
/// 화면에서는 ERD 필드명과 동일한 모델을 사용하므로 DTO 매핑 비용을 줄일 수 있습니다.

/// 회원(Member) 테이블 모델입니다.
class Member {
  final int id;
  final String email;
  final String password;

  const Member({required this.id, required this.email, required this.password});
}

/// 지불수단(PaymentMethod) 테이블 모델입니다.
class PaymentMethod {
  final int id;
  final int memberId;
  final String name;

  const PaymentMethod({required this.id, required this.memberId, required this.name});
}

/// 카테고리(Category) 테이블 모델입니다.
class Category {
  final int id;
  final String name;
  final String type;

  const Category({required this.id, required this.name, required this.type});
}

/// 일정(Schedule) 테이블 모델입니다.
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
}

/// 할일(Task) 테이블 모델입니다.
class Task {
  final int id;
  final int scheduleId;
  final String content;
  final bool isCompleted;

  const Task({required this.id, required this.scheduleId, required this.content, required this.isCompleted});
}

/// 수입/지출내역(AccountRecord) 테이블 모델입니다.
class AccountRecord {
  final int id;
  final int memberId;
  final int? scheduleId;
  final int categoryId;
  final int paymentMethodId;
  final int amount;
  final DateTime transactionTime;

  const AccountRecord({
    required this.id,
    required this.memberId,
    required this.scheduleId,
    required this.categoryId,
    required this.paymentMethodId,
    required this.amount,
    required this.transactionTime,
  });
}

/// ERD 관계를 화면에서 바로 보여주기 위해 조인한 수입/지출 뷰 모델입니다.
class AccountRecordView {
  final AccountRecord record;
  final Category category;
  final PaymentMethod paymentMethod;
  final Schedule? schedule;

  const AccountRecordView({
    required this.record,
    required this.category,
    required this.paymentMethod,
    required this.schedule,
  });
}

/// ERD 관계를 화면에서 바로 보여주기 위해 일정과 할 일을 묶은 뷰 모델입니다.
class ScheduleWithTasks {
  final Schedule schedule;
  final List<Task> tasks;

  const ScheduleWithTasks({required this.schedule, required this.tasks});
}

/// CRUD 화면이 백엔드 연결 전에도 동작하도록 만든 인메모리 저장소입니다.
class MockErdRepository {
  MockErdRepository._();

  static final MockErdRepository instance = MockErdRepository._();

  // TODO(backend): 백엔드 연동 후 아래 목 회원 데이터는 실제 로그인 사용자 응답으로 교체하고 삭제하세요.
  final List<Member> _members = const [
    Member(id: 1, email: 'segye@example.com', password: 'mock-password'),
  ];

  // TODO(backend): 백엔드 연동 후 아래 목 지불수단 데이터는 PaymentMethod API 응답으로 교체하고 삭제하세요.
  final List<PaymentMethod> _paymentMethods = const [
    PaymentMethod(id: 1, memberId: 1, name: '체크카드'),
    PaymentMethod(id: 2, memberId: 1, name: '현금'),
  ];

  // TODO(backend): 백엔드 연동 후 아래 목 카테고리 데이터는 Category API 응답으로 교체하고 삭제하세요.
  final List<Category> _categories = const [
    Category(id: 1, name: '월급', type: 'INCOME'),
    Category(id: 2, name: '식비', type: 'EXPENSE'),
    Category(id: 3, name: '교통', type: 'EXPENSE'),
    Category(id: 4, name: '공부', type: 'CARD'),
  ];

  // TODO(backend): 백엔드 연동 후 아래 목 일정 데이터는 Schedule CRUD API 응답으로 교체하고 삭제하세요.
  final List<Schedule> _schedules = [
    Schedule(
      id: 1,
      memberId: 1,
      title: '아침 운동',
      startTime: DateTime.now().copyWith(hour: 7, minute: 0, second: 0, millisecond: 0, microsecond: 0),
      endTime: DateTime.now().copyWith(hour: 9, minute: 30, second: 0, millisecond: 0, microsecond: 0),
    ),
    Schedule(
      id: 2,
      memberId: 1,
      title: '친구 약속',
      startTime: DateTime.now().copyWith(hour: 11, minute: 0, second: 0, millisecond: 0, microsecond: 0),
      endTime: DateTime.now().copyWith(hour: 15, minute: 30, second: 0, millisecond: 0, microsecond: 0),
    ),
    Schedule(
      id: 3,
      memberId: 1,
      title: '내일 회의 준비',
      startTime: DateTime.now().add(const Duration(days: 1)).copyWith(hour: 10, minute: 0, second: 0, millisecond: 0, microsecond: 0),
      endTime: DateTime.now().add(const Duration(days: 1)).copyWith(hour: 11, minute: 0, second: 0, millisecond: 0, microsecond: 0),
    ),
  ];

  // TODO(backend): 백엔드 연동 후 아래 목 할일 데이터는 Task CRUD API 응답으로 교체하고 삭제하세요.
  final List<Task> _tasks = const [
    Task(id: 1, scheduleId: 1, content: '백준 알고리즘 실버 2문제', isCompleted: false),
    Task(id: 2, scheduleId: 1, content: '두잉코딩 영어 1일차', isCompleted: true),
    Task(id: 3, scheduleId: 3, content: '회의 자료 초안 작성', isCompleted: false),
  ];

  // TODO(backend): 백엔드 연동 후 아래 목 수입/지출 데이터는 AccountRecord CRUD API 응답으로 교체하고 삭제하세요.
  final List<AccountRecord> _accountRecords = [
    AccountRecord(
      id: 1,
      memberId: 1,
      scheduleId: null,
      categoryId: 1,
      paymentMethodId: 1,
      amount: 3200000,
      transactionTime: DateTime.now().copyWith(hour: 9, minute: 0, second: 0, millisecond: 0, microsecond: 0),
    ),
    AccountRecord(
      id: 2,
      memberId: 1,
      scheduleId: 2,
      categoryId: 2,
      paymentMethodId: 1,
      amount: -12000,
      transactionTime: DateTime.now().copyWith(hour: 12, minute: 20, second: 0, millisecond: 0, microsecond: 0),
    ),
    AccountRecord(
      id: 3,
      memberId: 1,
      scheduleId: null,
      categoryId: 3,
      paymentMethodId: 2,
      amount: -3500,
      transactionTime: DateTime.now().copyWith(hour: 18, minute: 10, second: 0, millisecond: 0, microsecond: 0),
    ),
  ];

  Member get currentMember => _members.first;

  List<Category> get categories => List.unmodifiable(_categories);

  List<PaymentMethod> paymentMethodsByMember(int memberId) =>
      _paymentMethods.where((method) => method.memberId == memberId).toList(growable: false);

  List<ScheduleWithTasks> schedulesByDate(DateTime date, {int? memberId}) {
    final targetMemberId = memberId ?? currentMember.id;
    return _schedules
        .where((schedule) => schedule.memberId == targetMemberId && _isSameDate(schedule.startTime, date))
        .map((schedule) {
          final tasks = _tasks.where((task) => task.scheduleId == schedule.id).toList(growable: false);
          return ScheduleWithTasks(schedule: schedule, tasks: tasks);
        })
        .toList(growable: false);
  }

  List<Task> tasksByDate(DateTime date, {int? memberId}) => schedulesByDate(date, memberId: memberId)
      .expand((scheduleWithTasks) => scheduleWithTasks.tasks)
      .toList(growable: false);

  List<AccountRecordView> accountRecordsByDate(DateTime date, {int? memberId}) {
    final targetMemberId = memberId ?? currentMember.id;
    return _accountRecords
        .where((record) => record.memberId == targetMemberId && _isSameDate(record.transactionTime, date))
        .map(_toAccountRecordView)
        .toList(growable: false);
  }

  List<AccountRecordView> allAccountRecordViews({int? memberId}) {
    final targetMemberId = memberId ?? currentMember.id;
    return _accountRecords
        .where((record) => record.memberId == targetMemberId)
        .map(_toAccountRecordView)
        .toList(growable: false);
  }

  AccountRecordView _toAccountRecordView(AccountRecord record) {
    final category = _categories.firstWhere((category) => category.id == record.categoryId);
    final paymentMethod = _paymentMethods.firstWhere((method) => method.id == record.paymentMethodId);
    final schedule = record.scheduleId == null
        ? null
        : _schedules.firstWhere((schedule) => schedule.id == record.scheduleId);
    return AccountRecordView(record: record, category: category, paymentMethod: paymentMethod, schedule: schedule);
  }

  bool _isSameDate(DateTime left, DateTime right) =>
      left.year == right.year && left.month == right.month && left.day == right.day;
}
