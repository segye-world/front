class ScheduleModel {
  final int id;
  final String title;
  final String date;
  final int startHour;
  final int endHour;
  final String colorHex;

  const ScheduleModel({
    required this.id,
    required this.title,
    required this.date,
    required this.startHour,
    required this.endHour,
    required this.colorHex,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) => ScheduleModel(
    id: json['id'] as int,
    title: json['title'] as String,
    date: _parseDate(json['date']),
    startHour: json['startHour'] as int,
    endHour: json['endHour'] as int,
    colorHex: json['colorHex'] as String,
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
    'title': title,
    'date': date,
    'startHour': startHour,
    'endHour': endHour,
    'colorHex': colorHex,
  };
}
