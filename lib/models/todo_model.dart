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
    date: json['date'] as String,
  );

  Map<String, dynamic> toJson() => {
    'label': label,
    'isDone': isDone,
    'date': date,
    if (scheduleId != null) 'scheduleId': scheduleId,
  };
}
