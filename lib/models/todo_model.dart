class TodoModel {
  final int id;
  final int? scheduleId;
  final String label;
  final bool isDone;
  final String date;

  const TodoModel({
    required this.id,
    this.scheduleId,
    required this.label,
    required this.isDone,
    required this.date,
  });

  factory TodoModel.fromJson(Map<String, dynamic> json) => TodoModel(
    id: json['id'] as int,
    scheduleId: json['scheduleId'] as int?,
    label: json['label'] as String,
    isDone: json['isDone'] as bool,
    date: _parseDate(json['date']),
  );

  // Jackson 기본 설정은 LocalDate를 [2026,5,25] 배열로 직렬화합니다.
  // 백엔드 설정 변경 없이 두 형식 모두 수용합니다.
  static String _parseDate(dynamic v) {
    if (v is String) return v;
    if (v is List && v.length >= 3) {
      return '${v[0].toString().padLeft(4, '0')}-'
          '${v[1].toString().padLeft(2, '0')}-'
          '${v[2].toString().padLeft(2, '0')}';
    }
    return v.toString();
  }

  Map<String, dynamic> toJson() => {
    'label': label,
    'isDone': isDone,
    'date': date,
    if (scheduleId != null) 'scheduleId': scheduleId,
  };
}
