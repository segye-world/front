import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/account_record_model.dart';
import '../../models/schedule_model.dart';
import '../../models/todo_model.dart';
import '../../routes/routes.dart';
import '../../services/account_record_api.dart';
import '../../services/category_api.dart';
import '../../services/schedule_api.dart';
import '../../services/todo_api.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icon_sizes.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/app_dialog.dart';
import '../../widgets/common/app_primary_button.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/template/app_top_bar.dart';
import '../../widgets/template/bottom_nav_layout.dart';

class DayDetailScreen extends StatefulWidget {
  final DateTime selectedDate;

  const DayDetailScreen({super.key, required this.selectedDate});

  @override
  State<DayDetailScreen> createState() => _DayDetailScreenState();
}

enum _DetailMode { todo, finance, add }

enum _FinanceType { expense, income }

class _DayDetailScreenState extends State<DayDetailScreen> {
  static const _accentColor = AppColors.primary;
  static const _surfaceColor = AppColors.surface;
  static const _panelBorder = AppColors.cardBorder;
  /// 색을 지정하지 않은 할 일 섹션("일정 외 할일")의 기본 색.
  static const _defaultSectionColor = Color(0xFFD6D6D6);

  /// 타임라인에 칠할 날짜별 일정 블록. 키는 yyyy-MM-dd 입니다.
  /// 위아래로 이어지는 타임라인이 앞뒤 날짜도 보여 주므로, 선택된 날짜뿐 아니라
  /// [_loadTimelineRange] 로 불러온 앞뒤 며칠 치를 함께 들고 있습니다.
  final Map<String, List<_ScheduleBlock>> _timelineBlocks = {};

  /// 선택된 날짜의 일정 블록. [_timelineBlocks] 안의 그 날짜 목록을 그대로 가리키므로
  /// 여기에 더하거나 지우면 타임라인에도 바로 반영됩니다.
  List<_ScheduleBlock> get _scheduleBlocks =>
      _timelineBlocks.putIfAbsent(_dateString, () => <_ScheduleBlock>[]);

  List<_ScheduleBlock> _blocksForDate(DateTime date) =>
      _timelineBlocks[_dateKey(date)] ?? const <_ScheduleBlock>[];

  /// 타임라인 스크롤의 기준 날짜(이 날짜의 00시가 스크롤 0). 달력·HOME 으로 날짜를 바꿀 때만
  /// 바뀌고, 타임라인을 스크롤해 날짜가 넘어갈 때는 그대로라서 스크롤 위치가 튀지 않습니다.
  late DateTime _timelineAnchorDate;

  /// [_timelineBlocks] 를 채워 둔 구간. 선택 날짜가 이 구간 끝에 가까워지면 다시 불러옵니다.
  DateTime? _loadedRangeFrom;
  DateTime? _loadedRangeTo;

  /// 타임라인 스크롤로 날짜가 넘어갈 때, 지나가는 날마다 조회하지 않도록 잠시 기다렸다 부릅니다.
  Timer? _scrollDateLoadTimer;

  late final List<_TodoSectionState> _sections;
  late final List<AccountRecordModel> _financeEntries;

  /// 직전에 성공적으로 불러온 일정·할 일 목록.
  /// 둘 중 한쪽 조회가 실패해도 성공한 쪽만 새로 반영하고, 실패한 쪽은
  /// 이 값을 그대로 써서 화면에 이미 떠 있던 내용이 사라지지 않게 합니다.
  List<ScheduleModel> _lastLoadedSchedules = const [];
  List<TodoModel> _lastLoadedTodos = const [];
  List<CategoryModel> _categories = const [];
  // 지출 수단(=수입원)은 별도 목록이 아니라 수입원 카테고리를 그대로 가리킨다.
  int? _selectedSourceCategoryId;

  // 홈 화면이 된 이후로는 뒤로가기 대신 캘린더로 날짜를 갈아끼우므로
  // 화면이 살아있는 동안 바뀔 수 있는 상태로 둡니다.
  late DateTime _selectedDate;

  _DetailMode _detailMode = _DetailMode.todo;
  int? _editingSectionId;

  /// 타임라인을 접기 위해 워크스페이스의 상태에 직접 닿아야 합니다.
  /// 시간을 고르고 나면 상세 패널(추가 폼)이 보이도록 되돌려 줘야 하기 때문입니다.
  final _timelineKey = GlobalKey<_TimelineWorkspaceState>();

  /// 타임라인에서 칠해 둔 시간대. 탭한 칸이 anchor, 드래그를 따라오는 칸이 focus 입니다.
  /// 위로 드래그하면 focus < anchor 가 되므로 실제 범위는 두 값을 정렬해서 씁니다.
  int? _selectionAnchorHour;
  int? _selectionFocusHour;

  /// 롱프레스가 시작된 지점이 칸 안에서 몇 px 이었는지. 드래그 중 몇 칸을 지났는지
  /// 정확히 계산하려면 이동량만으로는 부족하고 시작 위치가 함께 필요합니다.
  double _dragOriginDy = 0;

  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _memoController = TextEditingController();
  final _newTodoController = TextEditingController();

  int _selectedColorIndex = 0;
  // 추가 폼의 시작·종료 시각. 00:00부터의 분입니다.
  int _startMinute = 13 * 60;
  int _endMinute = 15 * 60;
  _FinanceType _financeType = _FinanceType.expense;
  final List<String> _draftTodos = <String>[];

  final List<Color> _palette = const [
    Color(0xFF5E6BA8),
    Color(0xFF5A79E6),
    Color(0xFF8B65E8),
    Color(0xFF71B35C),
    Color(0xFFBE8A3A),
    Color(0xFFD1832F),
    Color(0xFF9DB7EA),
    Color(0xFFFFB24D),
    Color(0xFFF8A7D8),
    Color(0xFF9FD9C8),
    Color(0xFFF2A4A4),
    Color(0xFFF7D5AF),
  ];

  String? _selectedFinanceCategory;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
    _timelineAnchorDate = _selectedDate;
    _sections = <_TodoSectionState>[
      _TodoSectionState(
        id: 0,
        title: '일정 외 할일',
        color: _defaultSectionColor,
        items: <_TodoItemState>[],
      ),
    ];

    _financeEntries = <AccountRecordModel>[];
    _loadFinanceData();
    _loadScheduleAndTodos();
    _loadTimelineRange(_selectedDate);
  }

  @override
  void dispose() {
    _scrollDateLoadTimer?.cancel();
    _titleController.dispose();
    _amountController.dispose();
    _memoController.dispose();
    _newTodoController.dispose();
    super.dispose();
  }

  String get _formattedDate {
    final month = _selectedDate.month.toString().padLeft(2, '0');
    final day = _selectedDate.day.toString().padLeft(2, '0');
    return '${_selectedDate.year}년 $month월 $day일';
  }

  DatePickerThemeData _buildDatePickerTheme() {
    return DatePickerThemeData(
      dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return _accentColor;
        return null;
      }),
      dayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        if (states.contains(WidgetState.disabled)) return AppColors.textTertiary;
        return AppColors.textPrimary;
      }),
      todayBorder: const BorderSide(width: 1.6, color: _accentColor),
      todayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        return _accentColor;
      }),
      weekdayStyle: AppTextStyles.small.copyWith(color: AppColors.textSecondary),
      // dayForegroundColor가 색을 따로 관리하므로 크기만 가져다 씁니다.
      dayStyle: TextStyle(fontSize: AppTextStyles.caption.fontSize, fontWeight: FontWeight.w500),
      headerForegroundColor: AppColors.textPrimary,
    );
  }

  /// 앱바의 캘린더 아이콘 → 기존 대시보드와 같은 달력을 바텀시트로 띄웁니다.
  Future<void> _openCalendarSheet() async {
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        final themed = Theme.of(sheetContext).copyWith(
          colorScheme: Theme.of(sheetContext).colorScheme.copyWith(
            primary: _accentColor,
            onPrimary: Colors.white,
            onSurface: AppColors.textPrimary,
          ),
          datePickerTheme: _buildDatePickerTheme(),
        );

        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.large),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Theme(
                  data: themed,
                  child: CalendarDatePicker(
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    currentDate: DateTime.now(),
                    onDateChanged: (date) =>
                        Navigator.of(sheetContext).pop(date),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (picked != null && mounted) {
      _changeDate(picked);
    }
  }

  /// 선택된 날짜를 바꾸고 그 날짜의 일정·할 일·소비를 다시 조회합니다.
  ///
  /// 날짜가 바뀌면 직전 날짜에서 불러온 값을 그대로 이어 쓰면 안 되므로,
  /// 캐시해 둔 마지막 조회 결과도 함께 비웁니다.
  ///
  /// 새 날짜의 조회가 끝나기 전(또는 실패했을 때) 이전 날짜의 일정 블록·할 일·수입지출이
  /// 새 날짜 아래에 그대로 남아 보이지 않도록 화면 상태도 먼저 비웁니다. (#41)
  ///
  /// [fromTimeline] 은 타임라인을 스크롤해 날짜가 넘어간 경우입니다. (#57)
  /// 이때는 스크롤 기준 날짜와 이미 불러 둔 앞뒤 날짜의 일정 블록을 그대로 두고,
  /// 할 일·수입지출만 새 날짜로 바꿉니다. 지나가는 날마다 조회하지 않도록 잠시 기다렸다 부릅니다.
  void _changeDate(DateTime date, {bool fromTimeline = false}) {
    final day = DateTime(date.year, date.month, date.day);
    if (fromTimeline && _dateKey(day) == _dateString) return;

    setState(() {
      _selectedDate = day;
      _lastLoadedSchedules = const [];
      _lastLoadedTodos = const [];
      if (!fromTimeline) {
        _timelineAnchorDate = day;
        _timelineBlocks.clear();
        _loadedRangeFrom = null;
        _loadedRangeTo = null;
      }
      _sections
        ..clear()
        ..add(_TodoSectionState(
          id: 0,
          title: '일정 외 할일',
          color: _defaultSectionColor,
          items: [],
        ));
      _financeEntries.clear();
      _editingSectionId = null;
      _selectionAnchorHour = null;
      _selectionFocusHour = null;
    });

    _scrollDateLoadTimer?.cancel();
    if (!fromTimeline) {
      _loadFinanceData();
      _loadScheduleAndTodos();
      _loadTimelineRange(day);
      return;
    }
    _scrollDateLoadTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _loadFinanceData();
      _loadScheduleAndTodos();
      if (_needsTimelineRange(day)) _loadTimelineRange(day);
    });
  }

  String get _dateString => _dateKey(_selectedDate);

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// 타임라인이 미리 불러 둘 앞뒤 일수. 서버 한도(31일) 안에서 [center] 기준 ±7일을 읽습니다.
  static const int _timelineRangeRadius = 7;

  /// 선택 날짜가 불러 둔 구간 밖이거나 끝에서 2일 안쪽이면 다시 불러와야 합니다.
  bool _needsTimelineRange(DateTime day) {
    final from = _loadedRangeFrom;
    final to = _loadedRangeTo;
    if (from == null || to == null) return true;
    return day.isBefore(from.add(const Duration(days: 2))) ||
        day.isAfter(to.subtract(const Duration(days: 2)));
  }

  /// [center] 앞뒤 [_timelineRangeRadius]일의 일정을 한 번에 불러와 타임라인 블록을 채웁니다.
  /// 실패해도 화면을 막지 않습니다. 선택된 날짜는 [_loadScheduleAndTodos] 가 따로 채우고,
  /// 나머지 날짜는 비어 보일 뿐입니다.
  Future<void> _loadTimelineRange(DateTime center) async {
    final anchor = _timelineAnchorDate;
    final from = DateTime(center.year, center.month, center.day - _timelineRangeRadius);
    final to = DateTime(center.year, center.month, center.day + _timelineRangeRadius);
    try {
      final schedules = await ScheduleApi.fetchRange(_dateKey(from), _dateKey(to));
      // 기다리는 사이 달력으로 다른 날짜로 옮겼다면 이 결과는 버립니다.
      if (!mounted || anchor != _timelineAnchorDate) return;
      final byDate = <String, List<_ScheduleBlock>>{};
      for (final schedule in schedules) {
        byDate.putIfAbsent(schedule.date, () => []).add(_blockFromSchedule(schedule));
      }
      setState(() {
        for (var d = from; !d.isAfter(to); d = DateTime(d.year, d.month, d.day + 1)) {
          final key = _dateKey(d);
          // 선택된 날짜는 [_loadScheduleAndTodos] 가 할 일과 함께 관리하므로 건드리지 않습니다.
          if (key == _dateString) continue;
          _timelineBlocks[key] = byDate[key] ?? <_ScheduleBlock>[];
        }
        _loadedRangeFrom = from;
        _loadedRangeTo = to;
      });
    } catch (_) {
      // 앞뒤 날짜 미리보기는 부가 기능이라 오류 안내를 띄우지 않습니다.
    }
  }

  _ScheduleBlock _blockFromSchedule(ScheduleModel schedule) => _ScheduleBlock(
        id: schedule.id,
        title: schedule.title,
        startMinute: schedule.startMinute,
        endMinute: schedule.endMinute,
        color: _colorFromHex(schedule.colorHex).withValues(alpha: 0.45),
      );

  Future<void> _loadFinanceData() async {
    final date = _dateString;
    try {
      final results = await Future.wait([
        AccountRecordApi.fetchByDate(date),
        CategoryApi.fetchAll(),
      ]);
      // 기다리는 사이 날짜를 또 바꿨다면 늦게 도착한 이전 날짜 결과는 버립니다.
      if (!mounted || date != _dateString) return;
      setState(() {
        _financeEntries
          ..clear()
          ..addAll(results[0] as List<AccountRecordModel>);
        _categories = results[1] as List<CategoryModel>;
        final activeCategories = _activeCategories;
        if (!activeCategories.contains(_selectedFinanceCategory)) {
          _selectedFinanceCategory = activeCategories.firstOrNull;
        }
        final sourceCategories = _incomeCategoryModels;
        if (!sourceCategories.any(
          (category) => category.id == _selectedSourceCategoryId,
        )) {
          _selectedSourceCategoryId = sourceCategories.firstOrNull?.id;
        }
      });
    } catch (e, stackTrace) {
      if (mounted) {
        showErrorSnackBar(
          context,
          e,
          fallback: '수입·지출 내역을 불러오지 못했습니다.',
          stackTrace: stackTrace,
        );
      }
    }
  }

  /// 일정과 할 일을 각각 따로 불러옵니다. 하나를 Future.wait로 묶으면 한쪽이
  /// 실패할 때 다른 쪽까지 통째로 표시되지 않으므로, 둘을 분리해 한쪽이
  /// 실패해도 나머지는 그대로 화면에 보이게 합니다.
  ///
  /// 조회가 실패한 쪽은 빈 목록이 아니라 직전에 불러온 값을 그대로 씁니다.
  /// 빈 목록으로 덮어쓰면, 방금 추가한 일정이 떠 있는 상태에서 새로고침했을 때
  /// 일시적인 오류만으로도 화면에서 일정이 사라져 버립니다.
  Future<void> _loadScheduleAndTodos() async {
    List<ScheduleModel> schedules = _lastLoadedSchedules;
    List<TodoModel> todos = _lastLoadedTodos;
    Object? firstError;
    StackTrace? firstStackTrace;

    // 일정과 할 일을 같은 날짜로 묻도록 시작할 때의 날짜를 잡아 둡니다.
    final date = _dateString;

    try {
      schedules = await ScheduleApi.fetchByDate(date);
    } catch (e, stackTrace) {
      firstError = e;
      firstStackTrace = stackTrace;
    }

    try {
      todos = await TodoApi.fetchByDate(date);
    } catch (e, stackTrace) {
      firstError ??= e;
      firstStackTrace ??= stackTrace;
    }

    // 기다리는 사이 날짜를 또 바꿨다면 늦게 도착한 이전 날짜 결과로 화면을 덮지 않습니다.
    if (!mounted || date != _dateString) return;

    _lastLoadedSchedules = schedules;
    _lastLoadedTodos = todos;

    final blocks = schedules.map(_blockFromSchedule).toList();
    final sections = schedules.map((schedule) => _TodoSectionState(
      id: schedule.id,
      title: '${schedule.title} ${_formatMinute(schedule.startMinute)}-${_formatMinute(schedule.endMinute)}',
      color: _colorFromHex(schedule.colorHex).withValues(alpha: 0.35),
      items: todos.where((todo) => todo.scheduleId == schedule.id).map(
        (todo) => _TodoItemState(id: todo.id, label: todo.label, isDone: todo.isDone),
      ).toList(),
    )).toList()
      ..add(_TodoSectionState(
        id: 0,
        title: '일정 외 할일',
        color: _defaultSectionColor,
        items: todos.where((todo) => todo.scheduleId == null).map(
          (todo) => _TodoItemState(id: todo.id, label: todo.label, isDone: todo.isDone),
        ).toList(),
      ));
    setState(() {
      _scheduleBlocks
        ..clear()
        ..addAll(blocks);
      _sections
        ..clear()
        ..addAll(sections);
    });

    if (firstError != null) {
      showErrorSnackBar(
        context,
        firstError,
        fallback: '일정 또는 할 일을 불러오지 못했습니다.',
        stackTrace: firstStackTrace,
      );
    }
  }

  Color _colorFromHex(String value) {
    final hex = value.replaceFirst('#', '');
    final rgb = hex.length == 8 ? hex.substring(2) : hex;
    return Color(int.parse('FF$rgb', radix: 16));
  }

  void _setMode(_DetailMode mode) {
    setState(() {
      _detailMode = mode;
      if (mode != _DetailMode.todo) {
        _editingSectionId = null;
      }
      // 추가 폼을 벗어나면 칠해 둔 시간대도 함께 지웁니다.
      if (mode != _DetailMode.add) {
        _selectionAnchorHour = null;
        _selectionFocusHour = null;
      }
    });
  }

  // ── 타임라인 시간대 선택 ────────────────────────────────────────────────

  /// 칠해진 구간의 시작 시(포함). 선택이 없으면 null.
  int? get _selectionStartHour {
    final anchor = _selectionAnchorHour;
    final focus = _selectionFocusHour;
    if (anchor == null || focus == null) return null;
    return anchor < focus ? anchor : focus;
  }

  /// 칠해진 구간의 끝 시(제외). 13시 한 칸만 골랐으면 14 입니다.
  int? get _selectionEndHour {
    final anchor = _selectionAnchorHour;
    final focus = _selectionFocusHour;
    if (anchor == null || focus == null) return null;
    return (anchor > focus ? anchor : focus) + 1;
  }

  /// 탭 한 번은 그 시간 한 칸을 고릅니다. 이미 그 한 칸만 골라져 있으면 선택을 해제해,
  /// 잘못 누른 경우 같은 자리를 다시 눌러 되돌릴 수 있게 합니다.
  void _onTimelineHourTap(int hour) {
    setState(() {
      if (_selectionAnchorHour == hour && _selectionFocusHour == hour) {
        _selectionAnchorHour = null;
        _selectionFocusHour = null;
      } else {
        _selectionAnchorHour = hour;
        _selectionFocusHour = hour;
      }
    });
  }

  void _onTimelineHourDragStart(int hour, double localDy) {
    _dragOriginDy = localDy;
    setState(() {
      _selectionAnchorHour = hour;
      _selectionFocusHour = hour;
    });
  }

  /// 롱프레스는 시작한 칸이 계속 이동 이벤트를 받으므로, 시작 칸을 기준으로
  /// 현재 손가락이 몇 칸 아래(위)에 있는지 계산해 focus 를 옮깁니다.
  void _onTimelineHourDragUpdate(int originHour, double dyFromOrigin) {
    final y = _dragOriginDy + dyFromOrigin;
    final delta = (y / _kTimelineRowHeight).floor();
    final next = (originHour + delta).clamp(0, 23);
    if (next == _selectionFocusHour) return;
    setState(() => _selectionFocusHour = next);
  }

  void _clearTimelineSelection() {
    setState(() {
      _selectionAnchorHour = null;
      _selectionFocusHour = null;
    });
  }

  /// 칠한 구간을 그대로 추가 폼의 시작·종료 시간으로 넘깁니다.
  /// 타임라인이 펼쳐진 상태에서는 폼이 화면 밖으로 밀려 있으므로 같이 접어 줍니다.
  void _startAddFromSelection() {
    final start = _selectionStartHour;
    final end = _selectionEndHour;
    if (start == null || end == null) return;

    final anchor = _selectionAnchorHour;
    final focus = _selectionFocusHour;

    _prepareAddMode();
    setState(() {
      _startMinute = start * 60;
      _endMinute = end * 60;
      // 접힌 레일에서도 어느 구간을 담았는지 보이도록 칠한 상태를 유지합니다.
      _selectionAnchorHour = anchor;
      _selectionFocusHour = focus;
    });
    _timelineKey.currentState?.collapse();
  }

  Future<void> _toggleTodo(int sectionId, int itemId, bool? checked) async {
    final item = _sectionById(sectionId).items.firstWhere((element) => element.id == itemId);
    final isDone = checked ?? false;
    setState(() => item.isDone = isDone);
    try {
      await TodoApi.update(itemId, isDone: isDone);
    } catch (e, stackTrace) {
      if (mounted) {
        setState(() => item.isDone = !isDone);
        showErrorSnackBar(
          context,
          e,
          fallback: '할 일 상태 변경에 실패했습니다.',
          stackTrace: stackTrace,
        );
      }
    }
  }

  /// 우측 패널이 일정 추가 폼이거나 할 일 섹션을 편집 중인지 여부.
  bool get _isFormOpen => _detailMode == _DetailMode.add || _editingSectionId != null;

  void _openEditMode(int sectionId) {
    setState(() {
      _detailMode = _DetailMode.todo;
      _editingSectionId = sectionId;
    });
  }

  void _closeEditMode() {
    setState(() => _editingSectionId = null);
  }

  Future<void> _updateTodoLabel(int sectionId, int itemId, String value) async {
    final item = _sectionById(sectionId).items.firstWhere((element) => element.id == itemId);
    final previous = item.label;
    setState(() => item.label = value);
    try {
      await TodoApi.update(itemId, label: value);
    } catch (e, stackTrace) {
      if (mounted) {
        setState(() => item.label = previous);
        showErrorSnackBar(
          context,
          e,
          fallback: '할 일 수정에 실패했습니다.',
          stackTrace: stackTrace,
        );
      }
    }
  }

  /// 일정 삭제 확인 다이얼로그를 띄우고, 확인하면 서버에서 일정을 지운 뒤
  /// 타임라인·할 일 섹션을 다시 불러옵니다.
  ///
  /// `sectionId`는 "일정 외 할일"(id 0)이 아니라 실제 일정의 id여야 합니다.
  Future<void> _deleteSchedule(int sectionId) async {
    if (sectionId == 0) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AppDialog(
        title: '일정 삭제',
        content: const Text(
          '이 일정을 삭제하면 연결된 할 일과 수입·지출 내역도 함께 삭제됩니다.\n계속하시겠습니까?',
        ),
        confirmLabel: '삭제',
        confirmColor: AppColors.expenseAccent,
        onConfirm: () => Navigator.pop(ctx, true),
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ScheduleApi.delete(sectionId);
      if (!mounted) return;
      setState(() => _editingSectionId = null);
      await _loadScheduleAndTodos();
      await _loadFinanceData();
    } catch (e, stackTrace) {
      if (mounted) {
        showErrorSnackBar(
          context,
          e,
          fallback: '일정 삭제에 실패했습니다.',
          stackTrace: stackTrace,
        );
      }
    }
  }

  Future<void> _removeTodo(int sectionId, int itemId) async {
    final section = _sectionById(sectionId);
    final item = section.items.firstWhere((element) => element.id == itemId);
    setState(() => section.items.remove(item));
    try {
      await TodoApi.delete(itemId);
    } catch (e, stackTrace) {
      if (mounted) {
        setState(() => section.items.add(item));
        showErrorSnackBar(
          context,
          e,
          fallback: '할 일 삭제에 실패했습니다.',
          stackTrace: stackTrace,
        );
      }
    }
  }

  /// 입력칸의 글자로 할 일을 만듭니다. 저장에 실패하면 false 를 돌려주고 입력은 그대로 둡니다.
  Future<bool> _addTodoToSection(int sectionId) async {
    final text = _newTodoController.text.trim();
    if (text.isEmpty) return true;
    try {
      final todo = await TodoApi.create(
        label: text,
        date: _dateString,
        scheduleId: sectionId == 0 ? null : sectionId,
      );
      if (!mounted) return true;
      setState(() {
        _sectionById(sectionId).items.add(
          _TodoItemState(id: todo.id, label: todo.label, isDone: todo.isDone),
        );
        _newTodoController.clear();
      });
      return true;
    } catch (e, stackTrace) {
      if (mounted) {
        showErrorSnackBar(
          context,
          e,
          fallback: '할 일 저장에 실패했습니다.',
          stackTrace: stackTrace,
        );
      }
      return false;
    }
  }

  /// 편집을 마칩니다. `+` 를 누르지 않고 입력칸에 남겨 둔 할 일도 먼저 저장합니다. (#70)
  /// 그 저장이 실패하면 편집 모드와 입력을 유지해 다시 시도할 수 있게 합니다.
  Future<void> _saveSectionEdits() async {
    final sectionId = _editingSectionId;
    if (sectionId != null) {
      final saved = await _addTodoToSection(sectionId);
      if (!saved || !mounted) return;
    }
    setState(() {
      _editingSectionId = null;
      _newTodoController.clear();
    });
  }

  void _prepareAddMode() {
    setState(() {
      _detailMode = _DetailMode.add;
      _editingSectionId = null;
      _titleController.clear();
      _amountController.clear();
      _memoController.clear();
      _newTodoController.clear();
      _draftTodos.clear();
      _selectedColorIndex = 0;
      _startMinute = 13 * 60;
      _endMinute = 15 * 60;
      _financeType = _FinanceType.expense;
      _selectedFinanceCategory = _expenseCategories.firstOrNull;
      // FAB 로 빈 폼을 열 때는 타임라인에 칠해 둔 구간도 같이 지웁니다.
      // 타임라인에서 시작한 경우에는 _startAddFromSelection 이 다시 칠해 줍니다.
      _selectionAnchorHour = null;
      _selectionFocusHour = null;
    });
  }

  void _addDraftTodo() {
    final text = _newTodoController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _draftTodos.add(text);
      _newTodoController.clear();
    });
  }

  void _removeDraftTodo(String todo) {
    setState(() {
      _draftTodos.remove(todo);
    });
  }

  void _changeFinanceType(_FinanceType type) {
    setState(() {
      _financeType = type;
      _selectedFinanceCategory = _activeCategories.firstOrNull;
    });
  }

  Future<void> _submitNewSchedule() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      showAppSnackBar(context, '일정 제목을 입력해 주세요.');
      return;
    }

    final start = _startMinute;
    final end = _endMinute;
    if (end <= start) {
      showAppSnackBar(context, '종료 시간은 시작 시간보다 늦어야 합니다.');
      return;
    }
    final color = _palette[_selectedColorIndex];

    final amount = int.tryParse(_amountController.text.trim());
    final selectedCategory = _categories.where(
      (category) => category.name == _selectedFinanceCategory &&
          category.type == (_financeType == _FinanceType.expense ? 'EXPENSE' : 'INCOME'),
    ).firstOrNull;

    // 지출 수단(=지출이 빠져나가는 수입원)은 지출에만 필요합니다. 수입은 수입원 카테고리만으로 기록됩니다.
    final requiresSourceCategory = _financeType == _FinanceType.expense;
    final selectedSourceCategory =
        _incomeCategoryModels.where((category) => category.id == _selectedSourceCategoryId).firstOrNull;

    if (amount != null &&
        amount > 0 &&
        (selectedCategory == null || (requiresSourceCategory && selectedSourceCategory == null))) {
      showAppSnackBar(
        context,
        requiresSourceCategory
            ? '지출 카테고리와 수입원을 먼저 추가해 주세요.'
            : '수입원을 먼저 추가해 주세요.',
        action: SnackBarAction(
          label: '카테고리 관리',
          onPressed: () async {
            if (!mounted) return;
            await Navigator.of(context).pushNamed(Routes.myExpenseCategory);
            if (mounted) await _loadFinanceData();
          },
        ),
      );
      return;
    }

    try {
      final schedule = await ScheduleApi.create(
        title: title,
        date: _dateString,
        startMinute: start,
        endMinute: end,
        colorHex: '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
      );

      AccountRecordModel? createdRecord;
      if (amount != null &&
          amount > 0 &&
          selectedCategory != null &&
          (!requiresSourceCategory || selectedSourceCategory != null)) {
        createdRecord = await AccountRecordApi.create(
          amount: amount,
          categoryId: selectedCategory.id,
          sourceCategoryId: requiresSourceCategory ? selectedSourceCategory!.id : null,
          scheduleId: schedule.id,
          // 일정과 함께 기록하는 거래는 일정 시작 시각을 기본 거래 시각으로 저장합니다. (#44)
          transactionTime: scheduleTransactionTime(_selectedDate, start),
          memo: _memoController.text.trim(),
        );
      }

      // `+` 를 누르지 않고 입력칸에 남겨 둔 할 일도 함께 저장합니다. (#70, #88)
      final todoLabels = scheduleTodosToSave(_draftTodos, _newTodoController.text);
      final createdTodos = await Future.wait(todoLabels.map(
        (todo) => TodoApi.create(label: todo, date: _dateString, scheduleId: schedule.id),
      ));

      if (!mounted) return;
      setState(() {
      _newTodoController.clear();
      _draftTodos.clear();
      _scheduleBlocks.add(
        _ScheduleBlock(
          id: schedule.id,
          title: title,
          startMinute: start,
          endMinute: end,
          color: color.withValues(alpha: 0.45),
        ),
      );

      _sections.insert(
        _sections.length - 1,
        _TodoSectionState(
          id: schedule.id,
          title: '$title ${_formatMinute(start)}-${_formatMinute(end)}',
          color: color.withValues(alpha: 0.35),
          items: createdTodos
              .map((todo) => _TodoItemState(id: todo.id, label: todo.label, isDone: todo.isDone))
              .toList(),
        ),
      );

      if (createdRecord != null) {
        _financeEntries.insert(0, createdRecord);
      }

      // 저장된 구간은 이제 일정 블록으로 칠해지므로 선택 표시는 지웁니다.
      _selectionAnchorHour = null;
      _selectionFocusHour = null;

      _detailMode = _DetailMode.todo;
      });
    } catch (e, stackTrace) {
      if (mounted) {
        showErrorSnackBar(
          context,
          e,
          fallback: '일정 또는 수입·지출 저장에 실패했습니다.',
          stackTrace: stackTrace,
        );
      }
    }
  }

  List<String> get _expenseCategories => _categories
      .where((category) => category.type == 'EXPENSE')
      .map((category) => category.name)
      .toList();

  List<String> get _incomeCategories => _categories
      .where((category) => category.type == 'INCOME')
      .map((category) => category.name)
      .toList();

  List<String> get _activeCategories => _financeType == _FinanceType.expense
      ? _expenseCategories
      : _incomeCategories;

  // 지출 수단(=수입원) 드롭다운은 이름이 아니라 id가 필요하므로 모델 그대로 둔다.
  List<CategoryModel> get _incomeCategoryModels =>
      _categories.where((category) => category.type == 'INCOME').toList();

  _TodoSectionState _sectionById(int sectionId) {
    return _sections.firstWhere((section) => section.id == sectionId);
  }

  Widget _buildDetailPanel() {
    return _DetailPanel(
      mode: _detailMode,
      sections: _sections,
      editingSectionId: _editingSectionId,
      financeEntries: _financeEntries,
      palette: _palette,
      selectedColorIndex: _selectedColorIndex,
      titleController: _titleController,
      amountController: _amountController,
      memoController: _memoController,
      newTodoController: _newTodoController,
      startMinute: _startMinute,
      endMinute: _endMinute,
      financeType: _financeType,
      activeCategories: _activeCategories,
      selectedFinanceCategory: _selectedFinanceCategory ?? '',
      sourceCategories: _incomeCategoryModels,
      selectedSourceCategoryId: _selectedSourceCategoryId,
      onSourceCategoryChanged: (value) =>
          setState(() => _selectedSourceCategoryId = value),
      draftTodos: _draftTodos,
      onModeSelected: _setMode,
      onSectionLongPress: _openEditMode,
      onTodoChanged: _toggleTodo,
      onTodoLabelChanged: _updateTodoLabel,
      onTodoDeleted: _removeTodo,
      onSectionTodoAdded: _addTodoToSection,
      onSectionEditCanceled: _closeEditMode,
      onSectionEditSaved: _saveSectionEdits,
      onSectionDeleted: _deleteSchedule,
      onPrepareAddMode: _prepareAddMode,
      onDraftTodoAdded: _addDraftTodo,
      onDraftTodoRemoved: _removeDraftTodo,
      onColorSelected: (index) {
        setState(() => _selectedColorIndex = index);
      },
      onStartMinuteChanged: (value) {
        setState(() {
          _startMinute = value;
          // 시작을 종료보다 늦게 옮기면 길이를 유지하지 않고 종료를 시작 바로 뒤로 밀어 줍니다.
          if (_endMinute <= value) {
            _endMinute = (value + _kTimeStepMinutes).clamp(_kTimeStepMinutes, 24 * 60);
          }
        });
      },
      onEndMinuteChanged: (value) {
        setState(() => _endMinute = value);
      },
      onFinanceTypeChanged: _changeFinanceType,
      onFinanceCategoryChanged: (value) {
        setState(() => _selectedFinanceCategory = value);
      },
      onSubmitNewSchedule: _submitNewSchedule,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 하단 바가 본문 위에 떠 있도록 본문을 바 뒤까지 늘립니다.
      extendBody: true,
      backgroundColor: _surfaceColor,
      // 홈 화면이므로 뒤로가기 대신 날짜 선택용 캘린더를 엽니다.
      appBar: AppTopBar(
        title: _formattedDate,
        showBack: false,
        leading: IconButton(
          tooltip: '날짜 선택',
          icon: const Icon(Icons.calendar_month, size: AppIconSize.action, color: _accentColor),
          onPressed: _openCalendarSheet,
        ),
      ),
      body: SafeArea(
        child: _TimelineWorkspace(
          key: _timelineKey,
          blocks: _scheduleBlocks,
          baseDate: _selectedDate,
          anchorDate: _timelineAnchorDate,
          blocksForDate: _blocksForDate,
          // 타임라인을 스크롤해 다른 날짜가 맨 위로 오면 화면의 선택 날짜도 그 날짜로 바꿉니다. (#57)
          onVisibleDateChanged: (date) => _changeDate(date, fromTimeline: true),
          onBlockLongPress: _openEditMode,
          selectionStartHour: _selectionStartHour,
          selectionEndHour: _selectionEndHour,
          onHourTap: _onTimelineHourTap,
          onHourDragStart: _onTimelineHourDragStart,
          onHourDragUpdate: _onTimelineHourDragUpdate,
          // 드래그를 놓으면 확인 바를 거치지 않고 바로 추가 폼을 엽니다. (#42)
          onHourDragEnd: _startAddFromSelection,
          onSelectionCleared: _clearTimelineSelection,
          onSelectionConfirmed: _startAddFromSelection,
          panel: _buildDetailPanel(),
        ),
      ),
      // 추가/편집 폼을 여는 동안에는 FAB 가 폼(카테고리 목록·저장 버튼)을 가리지 않도록 숨깁니다(#79).
      // 위치는 Scaffold 가 떠 있는 하단 바 위로 자동으로 올려 줍니다.
      floatingActionButton: _isFormOpen
          ? null
          : FloatingActionButton(
              backgroundColor: AppColors.primary,
              onPressed: _prepareAddMode,
              child: const Icon(Icons.add, size: AppIconSize.action, color: Colors.white),
            ),
      bottomNavigationBar: AppBottomNavBar(
        currentItem: AppNavItem.home,
        // 이 화면이 곧 홈이므로, HOME 탭을 다시 누르면 오늘 날짜로 되돌립니다.
        onReselected: () => _changeDate(DateTime.now()),
      ),
    );
  }
}

/// 상세 타임라인에서 한 시간이 차지하는 높이.
/// 드래그로 몇 칸을 지났는지 계산할 때도 같은 값을 써야 하므로 상수로 둡니다.
const double _kTimelineRowHeight = 28;

/// 시간 입력에서 고를 수 있는 분 간격.
const int _kTimeStepMinutes = 10;

/// 해당 한 시간 칸과 조금이라도 겹치는 일정 블록을 찾습니다.
/// 14:30~16:00 일정은 14시·15시 칸에 걸립니다.
_ScheduleBlock? _blockForHour(List<_ScheduleBlock> blocks, int hour) {
  final rowStart = hour * 60;
  final rowEnd = rowStart + 60;
  for (final block in blocks) {
    if (block.startMinute < rowEnd && block.endMinute > rowStart) {
      return block;
    }
  }
  return null;
}

/// 좌측 타임라인과 우측 상세 패널(할 일 / 수입지출)을 함께 배치합니다.
///
/// 평소에는 하루 24시간을 세로로 압축한 납작한 바(rail)와 상세 패널이 나란히 놓입니다.
/// 타임라인을 오른쪽으로 밀면 타임라인이 펼쳐지는 만큼 상세 패널도 같이 오른쪽으로
/// 밀려 화면 밖으로 나가고, 우측 끝에 얇은 화살표 버튼만 남습니다.
/// 그 버튼을 누르면 패널이 다시 제자리로 돌아옵니다.
class _TimelineWorkspace extends StatefulWidget {
  /// 접혀 있을 때 타임라인이 차지하는 폭.
  static const double railWidth = 44;

  /// 펼쳐졌을 때 우측 끝에 남는 화살표 버튼의 폭.
  static const double handleWidth = 26;

  /// 선택된 날짜의 일정 블록. 접힌 납작한 레일에 칠합니다.
  final List<_ScheduleBlock> blocks;

  /// 화면에서 선택된 날짜.
  final DateTime baseDate;

  /// 상세 타임라인 스크롤의 기준 날짜. 위아래로 이 날짜부터 하루씩 이어집니다.
  final DateTime anchorDate;

  /// 상세 타임라인의 날짜별 일정 블록.
  final List<_ScheduleBlock> Function(DateTime date) blocksForDate;

  /// 상세 타임라인을 스크롤해 맨 위에 걸린 날짜가 바뀌었을 때.
  final ValueChanged<DateTime> onVisibleDateChanged;
  final ValueChanged<int> onBlockLongPress;

  /// 칠해 둔 시간대. start 는 포함, end 는 제외입니다.
  final int? selectionStartHour;
  final int? selectionEndHour;

  final ValueChanged<int> onHourTap;
  final void Function(int hour, double localDy) onHourDragStart;
  final void Function(int originHour, double dyFromOrigin) onHourDragUpdate;
  /// 롱프레스 드래그를 놓았을 때. 고른 구간으로 바로 추가 폼을 엽니다.
  final VoidCallback onHourDragEnd;
  final VoidCallback onSelectionCleared;
  final VoidCallback onSelectionConfirmed;

  final Widget panel;

  const _TimelineWorkspace({
    super.key,
    required this.blocks,
    required this.baseDate,
    required this.anchorDate,
    required this.blocksForDate,
    required this.onVisibleDateChanged,
    required this.onBlockLongPress,
    required this.selectionStartHour,
    required this.selectionEndHour,
    required this.onHourTap,
    required this.onHourDragStart,
    required this.onHourDragUpdate,
    required this.onHourDragEnd,
    required this.onSelectionCleared,
    required this.onSelectionConfirmed,
    required this.panel,
  });

  @override
  State<_TimelineWorkspace> createState() => _TimelineWorkspaceState();
}

class _TimelineWorkspaceState extends State<_TimelineWorkspace>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );

  /// 접힌 폭에서 펼친 폭까지 이동해야 하는 거리. 레이아웃 단계에서 갱신됩니다.
  double _travel = 0;

  bool get _isOpen => _controller.value > 0.5;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _open() => _controller.forward();

  void _close() => _controller.reverse();

  /// 시간대를 고른 뒤 상세 패널(추가 폼)이 보이도록 화면 쪽에서 접어 달라고 부를 수 있습니다.
  void collapse() => _close();

  void _onDragUpdate(DragUpdateDetails details) {
    if (_travel <= 0) return;
    _controller.value += (details.primaryDelta ?? 0) / _travel;
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dx;
    if (velocity.abs() > 300) {
      velocity > 0 ? _open() : _close();
    } else {
      _isOpen ? _open() : _close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        // 펼친 타임라인은 화살표 버튼 자리만 남기고 화면을 모두 차지합니다.
        final expandedWidth =
            (maxWidth - _TimelineWorkspace.handleWidth)
                .clamp(_TimelineWorkspace.railWidth, maxWidth);
        _travel = expandedWidth - _TimelineWorkspace.railWidth;

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            final timelineWidth = _TimelineWorkspace.railWidth + _travel * t;
            final panelWidth = maxWidth - _TimelineWorkspace.railWidth;

            return ClipRect(
              child: Stack(
                children: [
                  // 상세 패널. 타임라인이 펼쳐지는 만큼 오른쪽으로 밀려 화면을 벗어납니다.
                  Positioned(
                    left: timelineWidth,
                    top: 0,
                    bottom: 0,
                    width: panelWidth > 0 ? panelWidth : 0,
                    child: widget.panel,
                  ),
                  // 좌측 타임라인.
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: timelineWidth,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      // 접혀 있을 때 탭하면 펼칩니다. 되돌리기는 우측 화살표 버튼이 담당합니다.
                      onTap: _isOpen ? null : _open,
                      onHorizontalDragUpdate: _onDragUpdate,
                      onHorizontalDragEnd: _onDragEnd,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: t == 0
                              ? const []
                              : AppShadows.animatedEdgePanel(t),
                        ),
                        child: ClipRect(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // 상세 타임라인은 항상 펼친 폭으로 그려두고, 보이는 만큼만 잘라냅니다.
                              OverflowBox(
                                alignment: Alignment.centerLeft,
                                minWidth: expandedWidth,
                                maxWidth: expandedWidth,
                                child: _DetailedTimeline(
                                  anchorDate: widget.anchorDate,
                                  selectedDate: widget.baseDate,
                                  blocksForDate: widget.blocksForDate,
                                  onVisibleDateChanged: widget.onVisibleDateChanged,
                                  // 접혀 있으면 납작한 레일에 가려 보이지 않으므로,
                                  // 그 위에서의 세로 드래그가 몰래 스크롤되지 않게 막습니다.
                                  scrollEnabled: t > 0,
                                  // 가려진 동안에는 시간대 선택도 받지 않습니다.
                                  selectionEnabled: t > 0.99,
                                  selectionStartHour: widget.selectionStartHour,
                                  selectionEndHour: widget.selectionEndHour,
                                  onHourTap: widget.onHourTap,
                                  onHourDragStart: widget.onHourDragStart,
                                  onHourDragUpdate: widget.onHourDragUpdate,
                                  onHourDragEnd: widget.onHourDragEnd,
                                  onBlockLongPress: widget.onBlockLongPress,
                                ),
                              ),
                              // 접혀 있을 때는 납작한 타임라인이 그 위를 덮습니다.
                              if (t < 1)
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  bottom: 0,
                                  width: _TimelineWorkspace.railWidth,
                                  child: IgnorePointer(
                                    child: Opacity(
                                      opacity: 1 - t,
                                      child: _CompactTimelineRail(
                                        blocks: widget.blocks,
                                        selectionStartHour:
                                            widget.selectionStartHour,
                                        selectionEndHour:
                                            widget.selectionEndHour,
                                      ),
                                    ),
                                  ),
                                ),
                              // 오른쪽으로 밀 수 있음을 알려주는 손잡이.
                              if (t < 1)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Opacity(
                                    opacity: 1 - t,
                                    child: Container(
                                      width: 4,
                                      height: 40,
                                      margin: const EdgeInsets.only(right: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.7),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // 칠한 시간대를 확인하고 일정 추가로 넘어가는 바.
                  // 펼쳐진 타임라인 위에만 뜹니다.
                  if (t > 0.99 &&
                      widget.selectionStartHour != null &&
                      widget.selectionEndHour != null)
                    Positioned(
                      left: 0,
                      right: _TimelineWorkspace.handleWidth,
                      bottom: 0,
                      child: _SelectionConfirmBar(
                        startHour: widget.selectionStartHour!,
                        endHour: widget.selectionEndHour!,
                        onCleared: widget.onSelectionCleared,
                        onConfirmed: widget.onSelectionConfirmed,
                      ),
                    ),
                  // 패널을 밀어낸 자리에 남는 얇은 화살표 버튼.
                  if (t > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      width: _TimelineWorkspace.handleWidth,
                      child: Opacity(
                        opacity: t,
                        child: _PanelRevealHandle(
                          onTap: _close,
                          onDragUpdate: _onDragUpdate,
                          onDragEnd: _onDragEnd,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// 밀려나간 상세 패널을 다시 불러오는 우측 끝의 얇은 버튼.
/// 탭 외에 왼쪽으로 미는 제스처로도 되돌릴 수 있습니다.
class _PanelRevealHandle extends StatelessWidget {
  final VoidCallback onTap;
  final ValueChanged<DragUpdateDetails> onDragUpdate;
  final ValueChanged<DragEndDetails> onDragEnd;

  const _PanelRevealHandle({
    required this.onTap,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onHorizontalDragUpdate: onDragUpdate,
      onHorizontalDragEnd: onDragEnd,
      child: Semantics(
        button: true,
        label: '할 일 / 수입지출 패널 열기',
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primaryTint,
            border: const Border(left: BorderSide(color: AppColors.cardBorder)),
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(AppRadius.card),
            ),
            boxShadow: AppShadows.edgePanel,
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.chevron_left,
            size: 18,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

/// 하루 24시간을 화면 높이에 맞춰 압축한 납작한 타임라인.
/// 스크롤이 없어 하루 전체의 일정 분포가 한눈에 들어옵니다.
class _CompactTimelineRail extends StatelessWidget {
  final List<_ScheduleBlock> blocks;

  /// 타임라인을 접은 뒤에도 어느 구간을 골랐는지 보이도록 함께 칠합니다.
  final int? selectionStartHour;
  final int? selectionEndHour;

  const _CompactTimelineRail({
    required this.blocks,
    required this.selectionStartHour,
    required this.selectionEndHour,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Column(
        children: List.generate(24, (hour) {
          final block = _blockForHour(blocks, hour);
          final isMajorTick = hour % 6 == 0;
          final isSelected = selectionStartHour != null &&
              selectionEndHour != null &&
              hour >= selectionStartHour! &&
              hour < selectionEndHour!;

          return Expanded(
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? _DayDetailScreenState._accentColor
                    : block?.color,
                border: Border(
                  top: BorderSide(
                    color: isMajorTick
                        ? Colors.blueGrey.shade200
                        : Colors.blueGrey.shade50,
                    width: 0.6,
                  ),
                ),
              ),
              child: isMajorTick
                  ? Text(
                      '$hour',
                      style: AppTextStyles.micro.copyWith(
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : null,
            ),
          );
        }),
      ),
    );
  }
}

/// 시간 눈금과 일정 제목이 모두 보이는 상세 타임라인.
///
/// 23시에서 끊기지 않고 아래로는 다음 일자, 위로는 전날로 계속 이어집니다. (#57)
/// 날짜가 바뀌는 자리마다 날짜 머리글이 들어갑니다.
///
/// 스크롤 0 은 [anchorDate] 의 날짜 머리글이 맨 위에 온 위치입니다. 화면 맨 위에 걸린 날짜가
/// 바뀔 때마다(그날 머리글·00시가 맨 위로 올라오면) [onVisibleDateChanged] 로 알려,
/// 화면의 선택 날짜도 그 날짜로 바꿀 수 있게 합니다.
class _DetailedTimeline extends StatefulWidget {
  /// 하루가 차지하는 항목 수. 날짜 머리글 1개 + 24시간.
  static const int slotsPerDay = 25;

  /// 하루가 차지하는 높이. 날짜 머리글([_TimelineDayHeader.height]) + 24시간.
  static const double dayHeight =
      _TimelineDayHeader.height + 24 * _kTimelineRowHeight;

  /// 스크롤 0 의 기준 날짜. 달력으로 날짜를 바꿀 때만 바뀌며, 바뀌면 스크롤도 0 으로 돌아갑니다.
  final DateTime anchorDate;

  /// 화면에서 선택된 날짜. 강조 표시와 시간대 선택·일정 편집은 이 날짜에서만 받습니다.
  final DateTime selectedDate;

  final List<_ScheduleBlock> Function(DateTime date) blocksForDate;

  /// 타임라인이 접혀 보이지 않을 때는 스크롤을 잠급니다.
  final bool scrollEnabled;

  /// 완전히 펼쳐졌을 때만 시간대 선택을 받습니다.
  final bool selectionEnabled;

  /// 칠해 둔 시간대. start 포함, end 제외.
  final int? selectionStartHour;
  final int? selectionEndHour;

  final ValueChanged<int> onHourTap;
  final void Function(int hour, double localDy) onHourDragStart;
  final void Function(int originHour, double dyFromOrigin) onHourDragUpdate;
  /// 롱프레스 드래그를 놓았을 때. 고른 구간으로 바로 추가 폼을 엽니다.
  final VoidCallback onHourDragEnd;
  final ValueChanged<int> onBlockLongPress;

  /// 화면 맨 위에 걸린 날짜가 바뀌었을 때.
  final ValueChanged<DateTime> onVisibleDateChanged;

  const _DetailedTimeline({
    required this.anchorDate,
    required this.selectedDate,
    required this.blocksForDate,
    required this.scrollEnabled,
    required this.selectionEnabled,
    required this.selectionStartHour,
    required this.selectionEndHour,
    required this.onHourTap,
    required this.onHourDragStart,
    required this.onHourDragUpdate,
    required this.onHourDragEnd,
    required this.onBlockLongPress,
    required this.onVisibleDateChanged,
  });

  @override
  State<_DetailedTimeline> createState() => _DetailedTimelineState();
}

class _DetailedTimelineState extends State<_DetailedTimeline> {
  final _scrollController = ScrollController();
  final _centerKey = UniqueKey();

  /// 마지막으로 알린 날짜(기준 날짜로부터 며칠째인지).
  int _visibleDayOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant _DetailedTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 달력·HOME 으로 날짜를 바꾸면 새 날짜의 00시부터 보이게 되돌립니다. (#41)
    // 스크롤로 넘어간 경우에는 기준 날짜가 그대로라 위치가 유지됩니다.
    if (!_isSameDay(oldWidget.anchorDate, widget.anchorDate)) {
      _visibleDayOffset = 0;
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = visibleDayOffsetFor(_scrollController.offset);
    if (offset == _visibleDayOffset) return;
    _visibleDayOffset = offset;
    widget.onVisibleDateChanged(_dateAt(offset));
  }

  DateTime _dateAt(int dayOffset) => DateTime(
        widget.anchorDate.year,
        widget.anchorDate.month,
        widget.anchorDate.day + dayOffset,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.cardBorder),
      ),
      // 기준 날짜를 가운데(center) 두고, 아래 목록은 다음 일자로, 위 목록은 전날로 끝없이 이어집니다.
      child: CustomScrollView(
        controller: _scrollController,
        center: _centerKey,
        physics: widget.scrollEnabled ? null : const NeverScrollableScrollPhysics(),
        slivers: [
          // 위쪽(전날들). center 위의 목록은 아래에서 위로 쌓이므로 index 0 이 전날 23시 칸입니다.
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final dayOffset = -(index ~/ _DetailedTimeline.slotsPerDay) - 1;
              final slot = _DetailedTimeline.slotsPerDay - 1 - index % _DetailedTimeline.slotsPerDay;
              return _buildSlot(dayOffset, slot);
            }),
          ),
          // 아래쪽(기준 날짜부터). index 0 이 기준 날짜의 머리글입니다.
          SliverList(
            key: _centerKey,
            delegate: SliverChildBuilderDelegate((context, index) {
              return _buildSlot(
                index ~/ _DetailedTimeline.slotsPerDay,
                index % _DetailedTimeline.slotsPerDay,
              );
            }),
          ),
        ],
      ),
    );
  }

  /// [dayOffset] 날의 [slot] 번째 칸. slot 0 은 날짜 머리글, 1~24 는 0~23시입니다.
  Widget _buildSlot(int dayOffset, int slot) {
    final date = _dateAt(dayOffset);
    final isSelectedDate = _isSameDay(date, widget.selectedDate);

    if (slot == 0) {
      return _TimelineDayHeader(date: date, isBaseDate: isSelectedDate);
    }

    final hourValue = slot - 1;
    final block = _blockForHour(widget.blocksForDate(date), hourValue);
    // 블록이 시작하는 행에만 제목을 적어 겹쳐 보이지 않게 합니다.
    final isBlockStart = block != null && block.startMinute ~/ 60 == hourValue;

    // 화면의 나머지(할 일·수입지출·추가 폼)가 모두 선택된 날짜 기준이므로,
    // 선택된 날짜에서만 시간대를 고르거나 일정 편집을 열 수 있게 둡니다.
    final isSelected = isSelectedDate &&
        widget.selectionStartHour != null &&
        widget.selectionEndHour != null &&
        hourValue >= widget.selectionStartHour! &&
        hourValue < widget.selectionEndHour!;

    return _TimelineHourRow(
      hour: hourValue,
      block: block,
      isBlockStart: isBlockStart,
      isSelected: isSelected,
      isSelectionStart: isSelected && hourValue == widget.selectionStartHour,
      // 이미 일정이 있는 칸은 선택 대상에서 빼고, 기존 롱프레스(편집)를 살립니다.
      interactive: widget.selectionEnabled && isSelectedDate && block == null,
      onTap: widget.onHourTap,
      onDragStart: widget.onHourDragStart,
      onDragUpdate: widget.onHourDragUpdate,
      onDragEnd: widget.onHourDragEnd,
      onBlockLongPress: isSelectedDate ? widget.onBlockLongPress : (_) {},
    );
  }
}

/// 스크롤 위치(기준 날짜 머리글이 맨 위일 때 0)에서 화면 맨 위에 걸린 날짜가
/// 기준 날짜로부터 며칠째인지 계산합니다. 위로 올려 전날이 보이면 음수입니다.
/// 그날의 머리글이 맨 위에 닿는 순간부터 그날로 칩니다.
@visibleForTesting
int visibleDayOffsetFor(double scrollOffset) =>
    // 부동소수 오차로 경계에서 하루 앞 날짜가 잡히지 않도록 아주 조금 더해 줍니다.
    ((scrollOffset + 0.5) / _DetailedTimeline.dayHeight).floor();

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// 상세 타임라인의 한 시간 칸.
///
/// 빈 칸은 탭하면 그 한 시간이 칠해지고, 길게 눌러 위아래로 끌면 여러 시간이
/// 이어서 칠해지고, 손을 떼는 즉시 그 구간으로 일정 추가 폼이 열립니다.
/// 세로 드래그를 바로 쓰지 않고 롱프레스를 거치는 이유는
/// 타임라인이 ListView 안에 있어서, 그냥 드래그를 잡으면 스크롤이 죽기 때문입니다.
class _TimelineHourRow extends StatelessWidget {
  final int hour;
  final _ScheduleBlock? block;
  final bool isBlockStart;
  final bool isSelected;

  /// 칠해진 구간의 첫 칸에만 시간 범위를 적습니다.
  final bool isSelectionStart;

  /// 이 칸이 시간대 선택을 받는지. 다음 일자이거나 이미 일정이 있으면 false.
  final bool interactive;

  final ValueChanged<int> onTap;
  final void Function(int hour, double localDy) onDragStart;
  final void Function(int originHour, double dyFromOrigin) onDragUpdate;
  final VoidCallback onDragEnd;
  final ValueChanged<int> onBlockLongPress;

  const _TimelineHourRow({
    required this.hour,
    required this.block,
    required this.isBlockStart,
    required this.isSelected,
    required this.isSelectionStart,
    required this.interactive,
    required this.onTap,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onBlockLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final label = hour.toString().padLeft(2, '0');
    final currentBlock = block;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: interactive ? () => onTap(hour) : null,
      // 일정이 있는 칸의 롱프레스는 기존처럼 그 일정의 할 일 편집을 엽니다.
      onLongPress: currentBlock == null ? null : () => onBlockLongPress(currentBlock.id),
      onLongPressStart:
          interactive ? (details) => onDragStart(hour, details.localPosition.dy) : null,
      onLongPressMoveUpdate: interactive
          ? (details) => onDragUpdate(hour, details.localOffsetFromOrigin.dy)
          : null,
      // 손을 떼면 칠한 구간으로 바로 추가 폼을 엽니다. (#42)
      onLongPressEnd: interactive ? (_) => onDragEnd() : null,
      child: Container(
        height: _kTimelineRowHeight,
        decoration: BoxDecoration(
          color: isSelected
              ? _DayDetailScreenState._accentColor.withValues(alpha: 0.55)
              : null,
          border: Border(
            top: BorderSide(
              color: isSelected
                  ? _DayDetailScreenState._accentColor
                  : Colors.blueGrey.shade200,
              width: isSelected ? 1.2 : 0.8,
            ),
          ),
        ),
        child: Stack(
          children: [
            if (!isSelected && currentBlock != null) _buildBlockFill(currentBlock),
            Row(
              children: [
                SizedBox(
                  width: 38,
                  child: Text(
                    '$label:00',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.tiny.copyWith(
                      color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(child: _buildTrailing(currentBlock)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 일정이 이 칸에서 차지하는 분만큼만 칠합니다. 14:30 시작이면 14시 칸의 아래 절반입니다.
  Widget _buildBlockFill(_ScheduleBlock block) {
    final rowStart = hour * 60;
    final from = (block.startMinute - rowStart).clamp(0, 60);
    final to = (block.endMinute - rowStart).clamp(0, 60);
    return Positioned(
      left: 0,
      right: 0,
      top: _kTimelineRowHeight * from / 60,
      height: _kTimelineRowHeight * (to - from) / 60,
      child: ColoredBox(color: block.color),
    );
  }

  Widget _buildTrailing(_ScheduleBlock? currentBlock) {
    if (isBlockStart && currentBlock != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text(
          currentBlock.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.small.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      );
    }

    if (isSelectionStart) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text(
          '새 일정',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.small.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      );
    }

    if (isSelected) return const SizedBox.shrink();

    // 빈 칸은 15분 눈금으로 나눠 둡니다.
    return Row(
      children: List.generate(
        4,
        (lineIndex) => Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: Colors.blueGrey.shade100, width: 0.8),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 칠한 시간대를 확인하고 일정 추가 폼으로 넘어가는 바.
class _SelectionConfirmBar extends StatelessWidget {
  final int startHour;
  final int endHour;
  final VoidCallback onCleared;
  final VoidCallback onConfirmed;

  const _SelectionConfirmBar({
    required this.startHour,
    required this.endHour,
    required this.onCleared,
    required this.onConfirmed,
  });

  @override
  Widget build(BuildContext context) {
    final hours = endHour - startHour;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: _DayDetailScreenState._accentColor),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${_formatMinute(startHour * 60)} – ${_formatMinute(endHour * 60)} · $hours시간',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          IconButton(
            tooltip: '선택 해제',
            visualDensity: VisualDensity.compact,
            onPressed: onCleared,
            icon: const Icon(Icons.close, size: AppIconSize.inline, color: AppColors.textTertiary),
          ),
          FilledButton(
            onPressed: onConfirmed,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('일정 추가'),
          ),
        ],
      ),
    );
  }
}

/// 연속 타임라인에서 날짜가 바뀌는 자리를 알려주는 머리글.
class _TimelineDayHeader extends StatelessWidget {
  static const List<String> _weekdayLabels = [
    '월',
    '화',
    '수',
    '목',
    '금',
    '토',
    '일',
  ];

  /// 머리글 높이. 스크롤 위치로 날짜를 계산할 때도 같은 값을 써야 하므로 상수로 둡니다.
  static const double height = 26;

  final DateTime date;

  /// 화면에서 선택된 날짜인지. 앞뒤로 이어지는 날짜와 구분해 표시합니다.
  final bool isBaseDate;

  const _TimelineDayHeader({required this.date, required this.isBaseDate});

  @override
  Widget build(BuildContext context) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final weekday = _weekdayLabels[date.weekday - 1];

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: isBaseDate ? AppColors.primaryTint : AppColors.inputFill,
        border: const Border(
          top: BorderSide(color: AppColors.textTertiary, width: 1.2),
        ),
      ),
      child: Text(
        '$month월 $day일 ($weekday)',
        style: AppTextStyles.small.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _DetailPanel extends StatelessWidget {
  final _DetailMode mode;
  final List<_TodoSectionState> sections;
  final int? editingSectionId;
  final List<AccountRecordModel> financeEntries;
  final List<Color> palette;
  final int selectedColorIndex;
  final TextEditingController titleController;
  final TextEditingController amountController;
  final TextEditingController memoController;
  final TextEditingController newTodoController;
  final int startMinute;
  final int endMinute;
  final _FinanceType financeType;
  final List<String> activeCategories;
  final String selectedFinanceCategory;
  final List<CategoryModel> sourceCategories;
  final int? selectedSourceCategoryId;
  final ValueChanged<int?> onSourceCategoryChanged;
  final List<String> draftTodos;
  final ValueChanged<_DetailMode> onModeSelected;
  final ValueChanged<int> onSectionLongPress;
  final void Function(int sectionId, int itemId, bool? checked) onTodoChanged;
  final void Function(int sectionId, int itemId, String value) onTodoLabelChanged;
  final void Function(int sectionId, int itemId) onTodoDeleted;
  final ValueChanged<int> onSectionTodoAdded;
  final VoidCallback onSectionEditCanceled;
  final VoidCallback onSectionEditSaved;
  final ValueChanged<int> onSectionDeleted;
  final VoidCallback onPrepareAddMode;
  final VoidCallback onDraftTodoAdded;
  final ValueChanged<String> onDraftTodoRemoved;
  final ValueChanged<int> onColorSelected;
  final ValueChanged<int> onStartMinuteChanged;
  final ValueChanged<int> onEndMinuteChanged;
  final ValueChanged<_FinanceType> onFinanceTypeChanged;
  final ValueChanged<String> onFinanceCategoryChanged;
  final VoidCallback onSubmitNewSchedule;

  const _DetailPanel({
    required this.mode,
    required this.sections,
    required this.editingSectionId,
    required this.financeEntries,
    required this.palette,
    required this.selectedColorIndex,
    required this.titleController,
    required this.amountController,
    required this.memoController,
    required this.newTodoController,
    required this.startMinute,
    required this.endMinute,
    required this.financeType,
    required this.activeCategories,
    required this.selectedFinanceCategory,
    required this.sourceCategories,
    required this.selectedSourceCategoryId,
    required this.onSourceCategoryChanged,
    required this.draftTodos,
    required this.onModeSelected,
    required this.onSectionLongPress,
    required this.onTodoChanged,
    required this.onTodoLabelChanged,
    required this.onTodoDeleted,
    required this.onSectionTodoAdded,
    required this.onSectionEditCanceled,
    required this.onSectionEditSaved,
    required this.onSectionDeleted,
    required this.onPrepareAddMode,
    required this.onDraftTodoAdded,
    required this.onDraftTodoRemoved,
    required this.onColorSelected,
    required this.onStartMinuteChanged,
    required this.onEndMinuteChanged,
    required this.onFinanceTypeChanged,
    required this.onFinanceCategoryChanged,
    required this.onSubmitNewSchedule,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _DayDetailScreenState._panelBorder),
      ),
      child: Column(
        children: [
          _PanelTabs(
            mode: mode,
            onModeSelected: onModeSelected,
            onAddPressed: onPrepareAddMode,
          ),
          Expanded(
            child: switch (mode) {
              _DetailMode.todo => _TodoPanel(
                  sections: sections,
                  editingSectionId: editingSectionId,
                  newTodoController: newTodoController,
                  onSectionLongPress: onSectionLongPress,
                  onTodoChanged: onTodoChanged,
                  onTodoLabelChanged: onTodoLabelChanged,
                  onTodoDeleted: onTodoDeleted,
                  onSectionTodoAdded: onSectionTodoAdded,
                  onSectionEditCanceled: onSectionEditCanceled,
                  onSectionEditSaved: onSectionEditSaved,
                  onSectionDeleted: onSectionDeleted,
                ),
              _DetailMode.finance => _FinancePanel(entries: financeEntries),
              _DetailMode.add => _ScheduleAddPanel(
                  palette: palette,
                  selectedColorIndex: selectedColorIndex,
                  titleController: titleController,
                  amountController: amountController,
                  memoController: memoController,
                  todoController: newTodoController,
                  startMinute: startMinute,
                  endMinute: endMinute,
                  financeType: financeType,
                  activeCategories: activeCategories,
                  selectedFinanceCategory: selectedFinanceCategory,
                  sourceCategories: sourceCategories,
                  selectedSourceCategoryId: selectedSourceCategoryId,
                  onSourceCategoryChanged: onSourceCategoryChanged,
                  draftTodos: draftTodos,
                  onColorSelected: onColorSelected,
                  onStartMinuteChanged: onStartMinuteChanged,
                  onEndMinuteChanged: onEndMinuteChanged,
                  onFinanceTypeChanged: onFinanceTypeChanged,
                  onFinanceCategoryChanged: onFinanceCategoryChanged,
                  onDraftTodoAdded: onDraftTodoAdded,
                  onDraftTodoRemoved: onDraftTodoRemoved,
                  onSubmit: onSubmitNewSchedule,
                ),
            },
          ),
        ],
      ),
    );
  }
}

class _PanelTabs extends StatelessWidget {
  final _DetailMode mode;
  final ValueChanged<_DetailMode> onModeSelected;
  final VoidCallback onAddPressed;

  const _PanelTabs({
    required this.mode,
    required this.onModeSelected,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    Widget tab(String label, _DetailMode tabMode) {
      final isActive = mode == tabMode;
      return InkWell(
        onTap: () => onModeSelected(tabMode),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : AppColors.background,
            border: Border(
              bottom: BorderSide(
                color: isActive ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isActive ? AppColors.textPrimary : AppColors.textTertiary,
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        tab('할 일', _DetailMode.todo),
        tab('수입 · 지출', _DetailMode.finance),
        const Spacer(),
        IconButton(
          onPressed: onAddPressed,
          icon: const Icon(Icons.add, size: 18),
        ),
      ],
    );
  }
}

class _TodoPanel extends StatelessWidget {
  final List<_TodoSectionState> sections;
  final int? editingSectionId;
  final TextEditingController newTodoController;
  final ValueChanged<int> onSectionLongPress;
  final void Function(int sectionId, int itemId, bool? checked) onTodoChanged;
  final void Function(int sectionId, int itemId, String value) onTodoLabelChanged;
  final void Function(int sectionId, int itemId) onTodoDeleted;
  final ValueChanged<int> onSectionTodoAdded;
  final VoidCallback onSectionEditCanceled;
  final VoidCallback onSectionEditSaved;
  final ValueChanged<int> onSectionDeleted;

  const _TodoPanel({
    required this.sections,
    required this.editingSectionId,
    required this.newTodoController,
    required this.onSectionLongPress,
    required this.onTodoChanged,
    required this.onTodoLabelChanged,
    required this.onTodoDeleted,
    required this.onSectionTodoAdded,
    required this.onSectionEditCanceled,
    required this.onSectionEditSaved,
    required this.onSectionDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: sections.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final section = sections[index];
        final isEditing = editingSectionId == section.id;
        return GestureDetector(
          onLongPress: () => onSectionLongPress(section.id),
          child: Container(
            decoration: BoxDecoration(
              color: section.color,
              border: Border.all(color: AppColors.cardBorder),
            ),
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        section.title,
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // "일정 외 할일"(id 0)은 실제 일정이 아니므로 삭제할 수 없습니다.
                    if (isEditing && section.id != 0)
                      IconButton(
                        tooltip: '일정 삭제',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => onSectionDeleted(section.id),
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.white),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (section.items.isEmpty && !isEditing)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      '등록된 할 일이 없습니다.',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ...section.items.map(
                  (item) => _TodoRow(
                    sectionId: section.id,
                    item: item,
                    isEditing: isEditing,
                    onChanged: onTodoChanged,
                    onLabelChanged: onTodoLabelChanged,
                    onDelete: onTodoDeleted,
                  ),
                ),
                if (isEditing) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: newTodoController,
                          // 키보드의 완료(Enter)로도 바로 추가합니다.
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => onSectionTodoAdded(section.id),
                          decoration: const InputDecoration(
                            isDense: true,
                            hintText: '할 일 추가',
                            border: UnderlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => onSectionTodoAdded(section.id),
                        icon: const Icon(Icons.add, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: onSectionEditCanceled,
                            child: const Text('취소'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppPrimaryButton(
                          onPressed: onSectionEditSaved,
                          label: '저장',
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TodoRow extends StatelessWidget {
  final int sectionId;
  final _TodoItemState item;
  final bool isEditing;
  final void Function(int sectionId, int itemId, bool? checked) onChanged;
  final void Function(int sectionId, int itemId, String value) onLabelChanged;
  final void Function(int sectionId, int itemId) onDelete;

  const _TodoRow({
    required this.sectionId,
    required this.item,
    required this.isEditing,
    required this.onChanged,
    required this.onLabelChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (!isEditing) {
      return CheckboxListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: AppColors.primary,
        value: item.isDone,
        onChanged: (checked) => onChanged(sectionId, item.id, checked),
        title: Text(
          item.label,
          style: TextStyle(
            fontSize: AppTextStyles.caption.fontSize,
            decoration: item.isDone ? TextDecoration.lineThrough : null,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.drag_indicator, size: 16, color: AppColors.textTertiary),
          const SizedBox(width: 4),
          Expanded(
            child: TextFormField(
              initialValue: item.label,
              onChanged: (value) => onLabelChanged(sectionId, item.id, value),
              decoration: const InputDecoration(
                isDense: true,
                border: UnderlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            onPressed: () => onDelete(sectionId, item.id),
            icon: const Icon(Icons.delete_outline, size: 18),
          ),
        ],
      ),
    );
  }
}

class _FinancePanel extends StatelessWidget {
  final List<AccountRecordModel> entries;

  const _FinancePanel({required this.entries});

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<AccountRecordModel>>{};
    for (final entry in entries) {
      final groupTitle = entry.scheduleId == null ? '직접 추가한 수입 · 지출' : '일정에 추가한 수입 · 지출';
      grouped.putIfAbsent(groupTitle, () => <AccountRecordModel>[]).add(entry);
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: grouped.entries.map((group) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.primaryTint,
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                color: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text(
                  group.key,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ...group.value.map(
                (entry) => ListTile(
                  dense: true,
                  title: Text(entry.categoryName, style: TextStyle(fontSize: AppTextStyles.caption.fontSize)),
                  subtitle: Text(
                    entry.memo != null && entry.memo!.isNotEmpty
                        ? '${entry.categoryType == 'INCOME' ? '수입' : '지출'} · ${entry.memo}'
                        : (entry.categoryType == 'INCOME' ? '수입' : '지출'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: AppTextStyles.small.fontSize),
                  ),
                  trailing: Text(
                    _formatAmount(
                      entry.categoryType == 'INCOME' ? entry.amount : -entry.amount,
                    ),
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: entry.categoryType == 'INCOME'
                          ? AppColors.income
                          : AppColors.expense,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ScheduleAddPanel extends StatelessWidget {
  final List<Color> palette;
  final int selectedColorIndex;
  final TextEditingController titleController;
  final TextEditingController amountController;
  final TextEditingController memoController;
  final TextEditingController todoController;
  final int startMinute;
  final int endMinute;
  final _FinanceType financeType;
  final List<String> activeCategories;
  final String selectedFinanceCategory;
  final List<CategoryModel> sourceCategories;
  final int? selectedSourceCategoryId;
  final ValueChanged<int?> onSourceCategoryChanged;
  final List<String> draftTodos;
  final ValueChanged<int> onColorSelected;
  final ValueChanged<int> onStartMinuteChanged;
  final ValueChanged<int> onEndMinuteChanged;
  final ValueChanged<_FinanceType> onFinanceTypeChanged;
  final ValueChanged<String> onFinanceCategoryChanged;
  final VoidCallback onDraftTodoAdded;
  final ValueChanged<String> onDraftTodoRemoved;
  final VoidCallback onSubmit;

  const _ScheduleAddPanel({
    required this.palette,
    required this.selectedColorIndex,
    required this.titleController,
    required this.amountController,
    required this.memoController,
    required this.todoController,
    required this.startMinute,
    required this.endMinute,
    required this.financeType,
    required this.activeCategories,
    required this.selectedFinanceCategory,
    required this.sourceCategories,
    required this.selectedSourceCategoryId,
    required this.onSourceCategoryChanged,
    required this.draftTodos,
    required this.onColorSelected,
    required this.onStartMinuteChanged,
    required this.onEndMinuteChanged,
    required this.onFinanceTypeChanged,
    required this.onFinanceCategoryChanged,
    required this.onDraftTodoAdded,
    required this.onDraftTodoRemoved,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const _FieldLabel('제목'),
        TextField(
          controller: titleController,
          decoration: const InputDecoration(border: UnderlineInputBorder()),
        ),
        const SizedBox(height: 16),
        const _FieldLabel('색상'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(
            palette.length,
            (index) => GestureDetector(
              onTap: () => onColorSelected(index),
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: palette[index],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: index == selectedColorIndex
                        ? AppColors.textPrimary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _TimeSelector(
                label: '시작 시간',
                value: startMinute,
                minMinute: 0,
                maxMinute: 24 * 60 - _kTimeStepMinutes,
                onChanged: onStartMinuteChanged,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              // 시작보다 이른 종료 시각은 아예 고를 수 없게 합니다.
              child: _TimeSelector(
                label: '종료 시간',
                value: endMinute,
                minMinute: startMinute + _kTimeStepMinutes,
                maxMinute: 24 * 60,
                onChanged: onEndMinuteChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const _FieldLabel('할일 추가(선택)'),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: todoController,
                // 키보드의 완료(Enter)로도 칩으로 옮깁니다.
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => onDraftTodoAdded(),
                decoration: const InputDecoration(
                  hintText: '할 일을 입력하세요',
                  border: UnderlineInputBorder(),
                ),
              ),
            ),
            IconButton(onPressed: onDraftTodoAdded, icon: const Icon(Icons.add, size: AppIconSize.inline)),
          ],
        ),
        if (draftTodos.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: draftTodos
                .map(
                  (todo) => InputChip(
                    label: Text(todo),
                    onDeleted: () => onDraftTodoRemoved(todo),
                  ),
                )
                .toList(),
          ),
        ],
        const SizedBox(height: 20),
        const _FieldLabel('수입/지출 추가(선택)'),
        Align(
          alignment: Alignment.centerLeft,
          child: SegmentedButton<_FinanceType>(
            segments: const [
              ButtonSegment(value: _FinanceType.expense, label: Text('지출')),
              ButtonSegment(value: _FinanceType.income, label: Text('수입')),
            ],
            selected: <_FinanceType>{financeType},
            onSelectionChanged: (selection) {
              onFinanceTypeChanged(selection.first);
            },
          ),
        ),
        const SizedBox(height: 12),
        _FieldLabel(financeType == _FinanceType.expense ? '지출 카테고리' : '수입원 카테고리'),
        if (activeCategories.isEmpty)
          const Text(
            '카테고리 관리에서 항목을 추가해 주세요.',
            style: AppTextStyles.caption,
          ),
        ...activeCategories.map(
          (category) => RadioListTile<String>(
            dense: true,
            contentPadding: EdgeInsets.zero,
            value: category,
            groupValue: selectedFinanceCategory,
            onChanged: (value) {
              if (value != null) onFinanceCategoryChanged(value);
            },
            title: Text(category, style: TextStyle(fontSize: AppTextStyles.body.fontSize)),
          ),
        ),
        // 지출 수단(=수입원)은 돈이 빠져나가는 곳을 고르는 항목이라 지출에만 필요합니다.
        if (financeType == _FinanceType.expense) ...[
          const SizedBox(height: 12),
          const _FieldLabel('지출 수단'),
          if (sourceCategories.isEmpty)
            const Text(
              '카테고리 관리에서 수입원을 추가해 주세요.',
              style: AppTextStyles.caption,
            )
          else
            DropdownButtonFormField<int>(
              value: selectedSourceCategoryId,
              decoration: const InputDecoration(border: UnderlineInputBorder()),
              items: sourceCategories
                  .map((source) => DropdownMenuItem(value: source.id, child: Text(source.name)))
                  .toList(),
              onChanged: onSourceCategoryChanged,
            ),
        ],
        const _FieldLabel('메모'),
        TextField(
          controller: memoController,
          decoration: const InputDecoration(border: UnderlineInputBorder()),
        ),
        const SizedBox(height: 12),
        const _FieldLabel('비용'),
        TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            suffixText: '원',
            border: UnderlineInputBorder(),
          ),
        ),
        const SizedBox(height: 28),
        AppPrimaryButton(
          onPressed: onSubmit,
          label: '일정 추가',
        ),
      ],
    );
  }
}

class _TimeSelector extends StatelessWidget {
  final String label;

  /// 00:00부터의 분.
  final int value;

  /// 고를 수 있는 시각의 범위(양쪽 포함, 분). 서버가 시작은 0~1439, 종료는 1~1440 을 받으므로
  /// 종료 선택기는 24:00(1440) 까지 담을 수 있어야 합니다.
  final int minMinute;
  final int maxMinute;
  final ValueChanged<int> onChanged;

  const _TimeSelector({
    required this.label,
    required this.value,
    required this.minMinute,
    required this.maxMinute,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = [
      for (var minute = minMinute; minute <= maxMinute; minute += _kTimeStepMinutes) minute,
    ];
    // 범위를 벗어난 값이 들어오면 드롭다운이 항목을 찾지 못해 터지므로 걸러 냅니다.
    final selected = minutes.contains(value) ? value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        DropdownButtonFormField<int>(
          value: selected,
          // 10분 간격이면 항목이 많으므로 펼친 목록 높이를 제한합니다.
          menuMaxHeight: 320,
          decoration: const InputDecoration(border: UnderlineInputBorder()),
          items: minutes
              .map(
                (minute) => DropdownMenuItem<int>(
                  value: minute,
                  child: Text(_formatMinute(minute)),
                ),
              )
              .toList(),
          onChanged: (next) {
            if (next != null) onChanged(next);
          },
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ScheduleBlock {
  final int id;
  final String title;
  final int startMinute;
  final int endMinute;
  final Color color;

  const _ScheduleBlock({
    required this.id,
    required this.title,
    required this.startMinute,
    required this.endMinute,
    required this.color,
  });
}

class _TodoSectionState {
  final int id;
  final String title;
  final Color color;
  final List<_TodoItemState> items;

  _TodoSectionState({
    required this.id,
    required this.title,
    required this.color,
    required this.items,
  });
}

class _TodoItemState {
  final int id;
  String label;
  bool isDone;

  _TodoItemState({
    required this.id,
    required this.label,
    this.isDone = false,
  });
}

/// 일정과 함께 추가한 수입·지출의 거래 시각을 계산합니다.
/// [date]의 날짜에 일정 시작 시각([startMinute], 00:00부터의 분)을 붙여 반환합니다.
@visibleForTesting
DateTime scheduleTransactionTime(DateTime date, int startMinute) =>
    DateTime(date.year, date.month, date.day, 0, startMinute);

/// 일정과 함께 저장할 할 일 목록입니다. 칩으로 옮긴 [drafts] 에, 입력칸에 남은 [pending] 을
/// (공백만 있거나 이미 같은 칩이 있으면 빼고) 덧붙입니다.
@visibleForTesting
List<String> scheduleTodosToSave(List<String> drafts, String pending) {
  final text = pending.trim();
  if (text.isEmpty || drafts.contains(text)) return List.of(drafts);
  return [...drafts, text];
}

/// 00:00부터의 분을 "HH:mm" 으로 적습니다. 1440 은 "24:00" 입니다.
String _formatMinute(int minute) {
  final h = (minute ~/ 60).toString().padLeft(2, '0');
  final m = (minute % 60).toString().padLeft(2, '0');
  return '$h:$m';
}

String _formatAmount(int amount) {
  final sign = amount >= 0 ? '+' : '-';
  final number = amount.abs().toString();
  return '$sign$number';
}
