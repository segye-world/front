class ScheduleModel {
  final int id;
  final String title;
  final String date;

  /// 하루 시작(00:00)부터의 분. 14:30 이면 870 입니다.
  final int startMinute;

  /// 하루 시작(00:00)부터의 분. 24:00 이면 1440 입니다.
  final int endMinute;
  final String colorHex;

  const ScheduleModel({
    required this.id,
    required this.title,
    required this.date,
    required this.startMinute,
    required this.endMinute,
    required this.colorHex,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) => ScheduleModel(
    id: json['id'] as int,
    title: json['title'] as String,
    date: _parseDate(json['date']),
    // 분 단위를 모르는 이전 서버는 startHour/endHour 만 내려 줍니다.
    startMinute: json['startMinute'] as int? ?? (json['startHour'] as int) * 60,
    endMinute: json['endMinute'] as int? ?? (json['endHour'] as int) * 60,
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
    'startMinute': startMinute,
    'endMinute': endMinute,
    'colorHex': colorHex,
  };
}
