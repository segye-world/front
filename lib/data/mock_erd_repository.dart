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
  /// 로그인/가입 후 발급되는 회원 고유번호입니다.
  final int id;
  final int paymentMethodId;
  final String name;

  const PaymentMethod({required this.id, required this.paymentMethodId, required this.name});
}

/// 카테고리(Category) 테이블 모델입니다.
class Category {
  /// 로그인/가입 후 발급되는 회원 고유번호입니다.
  final int id;
  final int categoryId;
  final String name;
  final String type;

  const Category({required this.id, required this.categoryId, required this.name, required this.type});
}

/// 일정(Schedule) 테이블 모델입니다.
class Schedule {
  /// 로그인/가입 후 발급되는 회원 고유번호입니다.
  final int id;
  final int scheduleId;
  final String title;
  final DateTime startTime;
  final DateTime endTime;

  const Schedule({
    required this.id,
    required this.scheduleId,
    required this.title,
    required this.startTime,
    required this.endTime,
  });
}

/// 할일(Task) 테이블 모델입니다.
class Task {
  /// 로그인/가입 후 발급되는 회원 고유번호입니다.
  final int id;
  final int taskId;
  final int scheduleId;
  final String content;
  final bool isCompleted;

  const Task({
    required this.id,
    required this.taskId,
    required this.scheduleId,
    required this.content,
    required this.isCompleted,
  });
}

/// 수입/지출내역(AccountRecord) 테이블 모델입니다.
class AccountRecord {
  /// 로그인/가입 후 발급되는 회원 고유번호입니다.
  final int id;
  final int accountRecordId;
  final int? scheduleId;
  final int categoryId;
  final int paymentMethodId;
  final int amount;
  final DateTime transactionTime;

  const AccountRecord({
    required this.id,
    required this.accountRecordId,
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
  final List<Member> _members = [
    const Member(id: 1, email: 'segye@example.com', password: 'mock-password'),
    const Member(id: 2, email: 'hana@example.com', password: 'mock-password'),
  ];

  // 화면별 조회가 로그인 회원 기준으로 동작하도록 현재 선택된 회원 고유번호(id)를 보관합니다.
  int _currentId = 1;

  // TODO(backend): 백엔드 연동 후 아래 목 지불수단 데이터는 PaymentMethod API 응답으로 교체하고 삭제하세요.
  final List<PaymentMethod> _paymentMethods = [
    const PaymentMethod(id: 1, paymentMethodId: 1, name: '세계카드'),
    const PaymentMethod(id: 1, paymentMethodId: 2, name: '현금'),
    const PaymentMethod(id: 1, paymentMethodId: 3, name: '체크카드'),
    const PaymentMethod(id: 2, paymentMethodId: 4, name: '하나카드'),
    const PaymentMethod(id: 2, paymentMethodId: 5, name: '하나현금'),
  ];

  // TODO(backend): 백엔드 연동 후 아래 목 카테고리 데이터는 Category API 응답으로 교체하고 삭제하세요.
  final List<Category> _categories = [
    const Category(id: 1, categoryId: 1, name: '이달 총 수입', type: 'INCOME'),
    const Category(id: 1, categoryId: 2, name: '식비', type: 'EXPENSE'),
    const Category(id: 1, categoryId: 3, name: '교통비', type: 'EXPENSE'),
    const Category(id: 1, categoryId: 4, name: '쇼핑', type: 'EXPENSE'),
    const Category(id: 1, categoryId: 5, name: '문화생활', type: 'EXPENSE'),
    const Category(id: 1, categoryId: 6, name: '부수입', type: 'INCOME'),
    const Category(id: 1, categoryId: 7, name: '카페', type: 'EXPENSE'),
    const Category(id: 2, categoryId: 8, name: '하나 월급', type: 'INCOME'),
    const Category(id: 2, categoryId: 9, name: '하나 식비', type: 'EXPENSE'),
  ];

  // TODO(backend): 백엔드 연동 후 아래 목 일정 데이터는 Schedule CRUD API 응답으로 교체하고 삭제하세요.
  final List<Schedule> _schedules = [
    Schedule(
      id: 1,
      scheduleId: 1,
      title: '아침 운동',
      startTime: DateTime.now().copyWith(hour: 7, minute: 0, second: 0, millisecond: 0, microsecond: 0),
      endTime: DateTime.now().copyWith(hour: 9, minute: 30, second: 0, millisecond: 0, microsecond: 0),
    ),
    Schedule(
      id: 1,
      scheduleId: 2,
      title: '클릭까스 태릉점',
      startTime: DateTime.now().copyWith(hour: 11, minute: 0, second: 0, millisecond: 0, microsecond: 0),
      endTime: DateTime.now().copyWith(hour: 15, minute: 30, second: 0, millisecond: 0, microsecond: 0),
    ),
    Schedule(
      id: 1,
      scheduleId: 3,
      title: '내일 회의 준비',
      startTime: DateTime.now().add(const Duration(days: 1)).copyWith(hour: 10, minute: 0, second: 0, millisecond: 0, microsecond: 0),
      endTime: DateTime.now().add(const Duration(days: 1)).copyWith(hour: 11, minute: 0, second: 0, millisecond: 0, microsecond: 0),
    ),
    Schedule(
      id: 2,
      scheduleId: 4,
      title: '하나 독서 모임',
      startTime: DateTime.now().copyWith(hour: 18, minute: 0, second: 0, millisecond: 0, microsecond: 0),
      endTime: DateTime.now().copyWith(hour: 19, minute: 30, second: 0, millisecond: 0, microsecond: 0),
    ),
  ];

  // TODO(backend): 백엔드 연동 후 아래 목 할일 데이터는 Task CRUD API 응답으로 교체하고 삭제하세요.
  final List<Task> _tasks = const [
    Task(id: 1, taskId: 1, scheduleId: 1, content: '백준 알고리즘 실버 2문제', isCompleted: false),
    Task(id: 1, taskId: 2, scheduleId: 1, content: '두잉코딩 영어 1일차', isCompleted: true),
    Task(id: 1, taskId: 3, scheduleId: 3, content: '회의 자료 초안 작성', isCompleted: false),
    Task(id: 2, taskId: 4, scheduleId: 4, content: '책 챕터 정리', isCompleted: false),
  ];

  // TODO(backend): 백엔드 연동 후 아래 목 수입/지출 데이터는 AccountRecord CRUD API 응답으로 교체하고 삭제하세요.
  final List<AccountRecord> _accountRecords = [
    AccountRecord(
      id: 1,
      accountRecordId: 1,
      scheduleId: null,
      categoryId: 1,
      paymentMethodId: 1,
      amount: 280000,
      transactionTime: DateTime.now().copyWith(hour: 9, minute: 0, second: 0, millisecond: 0, microsecond: 0),
    ),
    AccountRecord(
      id: 1,
      accountRecordId: 2,
      scheduleId: 2,
      categoryId: 2,
      paymentMethodId: 1,
      amount: -12900,
      transactionTime: DateTime.now().copyWith(hour: 12, minute: 20, second: 0, millisecond: 0, microsecond: 0),
    ),
    AccountRecord(
      id: 1,
      accountRecordId: 3,
      scheduleId: null,
      categoryId: 3,
      paymentMethodId: 1,
      amount: -6900,
      transactionTime: DateTime.now().copyWith(hour: 8, minute: 40, second: 0, millisecond: 0, microsecond: 0),
    ),
    AccountRecord(
      id: 1,
      accountRecordId: 4,
      scheduleId: null,
      categoryId: 7,
      paymentMethodId: 1,
      amount: -6900,
      transactionTime: DateTime.now().subtract(const Duration(days: 1)).copyWith(hour: 15, minute: 10, second: 0, millisecond: 0, microsecond: 0),
    ),
    AccountRecord(
      id: 1,
      accountRecordId: 5,
      scheduleId: null,
      categoryId: 4,
      paymentMethodId: 3,
      amount: -84000,
      transactionTime: DateTime.now().subtract(const Duration(days: 2)).copyWith(hour: 19, minute: 30, second: 0, millisecond: 0, microsecond: 0),
    ),
    AccountRecord(
      id: 1,
      accountRecordId: 6,
      scheduleId: null,
      categoryId: 5,
      paymentMethodId: 2,
      amount: -42000,
      transactionTime: DateTime.now().subtract(const Duration(days: 3)).copyWith(hour: 20, minute: 0, second: 0, millisecond: 0, microsecond: 0),
    ),
    AccountRecord(
      id: 1,
      accountRecordId: 7,
      scheduleId: null,
      categoryId: 6,
      paymentMethodId: 2,
      amount: 120000,
      transactionTime: DateTime.now().subtract(const Duration(days: 5)).copyWith(hour: 18, minute: 0, second: 0, millisecond: 0, microsecond: 0),
    ),
    AccountRecord(
      id: 1,
      accountRecordId: 8,
      scheduleId: null,
      categoryId: 2,
      paymentMethodId: 1,
      amount: -18500,
      transactionTime: DateTime.now().subtract(const Duration(days: 8)).copyWith(hour: 13, minute: 5, second: 0, millisecond: 0, microsecond: 0),
    ),
    AccountRecord(
      id: 2,
      accountRecordId: 9,
      scheduleId: 4,
      categoryId: 9,
      paymentMethodId: 4,
      amount: -24000,
      transactionTime: DateTime.now().copyWith(hour: 18, minute: 10, second: 0, millisecond: 0, microsecond: 0),
    ),
    AccountRecord(
      id: 2,
      accountRecordId: 10,
      scheduleId: null,
      categoryId: 8,
      paymentMethodId: 5,
      amount: 320000,
      transactionTime: DateTime.now().copyWith(hour: 10, minute: 0, second: 0, millisecond: 0, microsecond: 0),
    ),
  ];

  Member get currentMember => _members.firstWhere((member) => member.id == _currentId);

  // 현재 로그인 회원의 카테고리만 반환해 다른 회원의 설정 항목이 섞이지 않도록 합니다.
  List<Category> get categories => categoriesById(_currentId);

  Member? findMemberByEmail(String email) {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty) return null;

    for (final member in _members) {
      if (member.email == normalizedEmail) return member;
    }
    return null;
  }

  Member? login(String email, String password) {
    final normalizedEmail = email.trim();
    final member = findMemberByEmail(normalizedEmail);

    // 로그인은 아이디(이메일)와 비밀번호가 모두 맞을 때만 현재 회원 id를 변경합니다.
    if (member == null || member.password != password) return null;

    _currentId = member.id;
    return member;
  }

  Member registerMember(String email, String password) {
    final normalizedEmail = email.trim();
    final existing = findMemberByEmail(normalizedEmail);
    if (existing != null) {
      _currentId = existing.id;
      return existing;
    }

    // 목 저장소에서도 새 회원에게 독립된 id를 발급해 이후 모든 항목의 회원 구분 기준으로 사용합니다.
    final member = Member(id: _nextId(), email: normalizedEmail, password: password);
    _members.add(member);
    _currentId = member.id;
    _seedDefaultSettings(member.id);
    return member;
  }

  int idForEmail(String email) {
    final member = findMemberByEmail(email);
    if (member == null) return _currentId;
    return member.id;
  }

  List<Category> categoriesById(int id) => _categories.where((category) => category.id == id).toList(growable: false);

  List<PaymentMethod> paymentMethodsById(int id) =>
      _paymentMethods.where((method) => method.id == id).toList(growable: false);

  List<ScheduleWithTasks> schedulesByDate(DateTime date, {int? id}) {
    final targetId = id ?? currentMember.id;
    return _schedules
        .where((schedule) => schedule.id == targetId && _isSameDate(schedule.startTime, date))
        .map((schedule) {
          // 할 일은 일정 번호뿐 아니라 회원 고유번호(id)도 확인해 다른 회원의 항목이 섞이지 않게 합니다.
          final tasks = _tasks
              .where((task) => task.id == targetId && task.scheduleId == schedule.scheduleId)
              .toList(growable: false);
          return ScheduleWithTasks(schedule: schedule, tasks: tasks);
        })
        .toList(growable: false);
  }

  List<Task> tasksByDate(DateTime date, {int? id}) => schedulesByDate(date, id: id)
      .expand((scheduleWithTasks) => scheduleWithTasks.tasks)
      .toList(growable: false);

  List<AccountRecordView> accountRecordsByDate(DateTime date, {int? id}) {
    final targetId = id ?? currentMember.id;
    return _accountRecords
        .where((record) => record.id == targetId && _isSameDate(record.transactionTime, date))
        .map(_toAccountRecordView)
        .toList(growable: false);
  }

  List<AccountRecordView> allAccountRecordViews({int? id}) {
    final targetId = id ?? currentMember.id;
    return _accountRecords
        .where((record) => record.id == targetId)
        .map(_toAccountRecordView)
        .toList(growable: false);
  }

  /// 소비 상세/전체보기에서 최근 거래 순서로 사용할 수입·지출 조인 목록입니다.
  List<AccountRecordView> sortedAccountRecordViews({int? id}) {
    final records = allAccountRecordViews(id: id);
    records.sort((left, right) => right.record.transactionTime.compareTo(left.record.transactionTime));
    return records;
  }

  /// ERD Category.type 값으로 수입/지출을 구분해 월별 거래를 필터링합니다.
  List<AccountRecordView> accountRecordsByMonth(DateTime month, {String? type, int? id}) {
    return sortedAccountRecordViews(id: id)
        .where((view) =>
            view.record.transactionTime.year == month.year &&
            view.record.transactionTime.month == month.month &&
            (type == null || view.category.type == type))
        .toList(growable: false);
  }

  /// 상단 요약 카드에서 사용하는 오늘 수입/지출 합계를 계산합니다.
  int todayTotalByType(String type, {int? id}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return accountRecordsByDate(today, id: id)
        .where((view) => view.category.type == type)
        .fold(0, (sum, view) => sum + view.record.amount.abs());
  }

  /// 카테고리별 지출 막대 차트에 사용할 월간 지출 합계를 계산합니다.
  Map<Category, int> monthlyExpenseTotalsByCategory(DateTime month, {int? id}) {
    final totals = <Category, int>{};
    for (final view in accountRecordsByMonth(month, type: 'EXPENSE', id: id)) {
      totals.update(view.category, (value) => value + view.record.amount.abs(), ifAbsent: () => view.record.amount.abs());
    }
    return totals;
  }

  AccountRecordView _toAccountRecordView(AccountRecord record) {
    // 조인 시에도 회원 고유번호(id)를 함께 검증해 다른 회원의 항목이 연결되지 않게 합니다.
    final category = _categories.firstWhere(
      (category) => category.categoryId == record.categoryId && category.id == record.id,
    );
    final paymentMethod = _paymentMethods.firstWhere(
      (method) => method.paymentMethodId == record.paymentMethodId && method.id == record.id,
    );
    final schedule = record.scheduleId == null
        ? null
        : _schedules.firstWhere(
            (schedule) => schedule.scheduleId == record.scheduleId && schedule.id == record.id,
          );
    return AccountRecordView(record: record, category: category, paymentMethod: paymentMethod, schedule: schedule);
  }

  int _nextId() => _members.map((member) => member.id).reduce((left, right) => left > right ? left : right) + 1;

  int _nextPaymentMethodId() =>
      _paymentMethods.map((method) => method.paymentMethodId).reduce((left, right) => left > right ? left : right) + 1;

  int _nextCategoryId() =>
      _categories.map((category) => category.categoryId).reduce((left, right) => left > right ? left : right) + 1;

  void _seedDefaultSettings(int id) {
    // 신규 회원은 공용 데이터가 아니라 해당 회원 고유번호(id)를 가진 기본 설정만 별도로 받습니다.
    var nextCategoryId = _nextCategoryId();
    _categories.addAll([
      Category(id: id, categoryId: nextCategoryId++, name: '이달 총 수입', type: 'INCOME'),
      Category(id: id, categoryId: nextCategoryId++, name: '식비', type: 'EXPENSE'),
      Category(id: id, categoryId: nextCategoryId, name: '교통비', type: 'EXPENSE'),
    ]);

    var nextPaymentMethodId = _nextPaymentMethodId();
    _paymentMethods.addAll([
      PaymentMethod(id: id, paymentMethodId: nextPaymentMethodId++, name: '기본카드'),
      PaymentMethod(id: id, paymentMethodId: nextPaymentMethodId, name: '현금'),
    ]);
  }

  bool _isSameDate(DateTime left, DateTime right) =>
      left.year == right.year && left.month == right.month && left.day == right.day;
}
