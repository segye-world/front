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
    date: json['date'] as String,
    startHour: json['startHour'] as int,
    endHour: json['endHour'] as int,
    colorHex: json['colorHex'] as String,
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'date': date,
    'startHour': startHour,
    'endHour': endHour,
    'colorHex': colorHex,
  };
}
