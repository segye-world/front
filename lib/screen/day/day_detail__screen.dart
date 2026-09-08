import 'package:flutter/material.dart';

import '../../models/account_record_model.dart';
import '../../models/payment_method_model.dart';
import '../../models/schedule_model.dart';
import '../../models/todo_model.dart';
import '../../routes/routes.dart';
import '../../services/account_record_api.dart';
import '../../services/category_api.dart';
import '../../services/finance_settings_api.dart';
import '../../services/payment_method_api.dart';
import '../../services/schedule_api.dart';
import '../../services/todo_api.dart';

class DayDetailScreen extends StatefulWidget {
  final DateTime selectedDate;

  const DayDetailScreen({super.key, required this.selectedDate});

  @override
  State<DayDetailScreen> createState() => _DayDetailScreenState();
}

enum _DetailMode { todo, finance, add }

enum _FinanceType { expense, income }

class _DayDetailScreenState extends State<DayDetailScreen> {
  static const _accentColor = Color(0xFFF7A5A5);
  static const _surfaceColor = Color(0xFFFFFBFB);
  static const _panelBorder = Color(0xFFE6DCDD);

  late final List<_ScheduleBlock> _scheduleBlocks;
  late final List<_TodoSectionState> _sections;
  late final List<AccountRecordModel> _financeEntries;
  List<CategoryModel> _categories = const [];
  List<PaymentMethodModel> _paymentMethods = const [];
  int? _selectedPaymentMethodId;

  _DetailMode _detailMode = _DetailMode.todo;
  int? _editingSectionId;

  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _memoController = TextEditingController();
  final _newTodoController = TextEditingController();

  int _selectedColorIndex = 0;
  double _startHour = 13;
  double _endHour = 15;
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
    _scheduleBlocks = <_ScheduleBlock>[];
    _sections = <_TodoSectionState>[
      _TodoSectionState(
        id: 0,
        title: '일정 외 할일',
        color: const Color(0xFFD6D6D6),
        items: <_TodoItemState>[],
      ),
    ];

    _financeEntries = <AccountRecordModel>[];
    _loadFinanceData();
    _loadScheduleAndTodos();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _memoController.dispose();
    _newTodoController.dispose();
    super.dispose();
  }

  String get _formattedDate {
    final month = widget.selectedDate.month.toString().padLeft(2, '0');
    final day = widget.selectedDate.day.toString().padLeft(2, '0');
    return '${widget.selectedDate.year}년 $month월 $day일';
  }

  String get _dateString =>
      '${widget.selectedDate.year}-${widget.selectedDate.month.toString().padLeft(2, '0')}-${widget.selectedDate.day.toString().padLeft(2, '0')}';

  Future<void> _loadFinanceData() async {
    try {
      await FinanceSettingsApi.ensureDefaults();
      final results = await Future.wait([
        AccountRecordApi.fetchByDate(_dateString),
        CategoryApi.fetchAll(),
        PaymentMethodApi.fetchAll(),
      ]);
      if (!mounted) return;
      setState(() {
        _financeEntries
          ..clear()
          ..addAll(results[0] as List<AccountRecordModel>);
        _categories = results[1] as List<CategoryModel>;
        _paymentMethods = results[2] as List<PaymentMethodModel>;
        _selectedFinanceCategory ??= _expenseCategories.firstOrNull;
        _selectedPaymentMethodId ??= _paymentMethods.firstOrNull?.id;
      });
    } catch (_) {
      // Keep the schedule screen usable when finance data is temporarily unavailable.
    }
  }

  Future<void> _loadScheduleAndTodos() async {
    try {
      final results = await Future.wait([
        ScheduleApi.fetchByDate(_dateString),
        TodoApi.fetchByDate(_dateString),
      ]);
      if (!mounted) return;
      final schedules = results[0] as List<ScheduleModel>;
      final todos = results[1] as List<TodoModel>;
      final blocks = schedules.map((schedule) => _ScheduleBlock(
        id: schedule.id,
        title: schedule.title,
        startHour: schedule.startHour,
        endHour: schedule.endHour,
        color: _colorFromHex(schedule.colorHex).withValues(alpha: 0.45),
      )).toList();
      final sections = schedules.map((schedule) => _TodoSectionState(
        id: schedule.id,
        title: '${schedule.title} ${_formatHour(schedule.startHour.toDouble())}-${_formatHour(schedule.endHour.toDouble())}',
        color: _colorFromHex(schedule.colorHex).withValues(alpha: 0.35),
        items: todos.where((todo) => todo.scheduleId == schedule.id).map(
          (todo) => _TodoItemState(id: todo.id, label: todo.label, isDone: todo.isDone),
        ).toList(),
      )).toList()
        ..add(_TodoSectionState(
          id: 0,
          title: '일정 외 할일',
          color: const Color(0xFFD6D6D6),
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
    } catch (_) {
      // Keep the empty state visible until the schedule/todo APIs are available.
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
    });
  }

  Future<void> _toggleTodo(int sectionId, int itemId, bool? checked) async {
    final item = _sectionById(sectionId).items.firstWhere((element) => element.id == itemId);
    final isDone = checked ?? false;
    setState(() => item.isDone = isDone);
    try {
      await TodoApi.update(itemId, isDone: isDone);
    } catch (_) {
      if (mounted) setState(() => item.isDone = !isDone);
    }
  }

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
    } catch (_) {
      if (mounted) setState(() => item.label = previous);
    }
  }

  Future<void> _removeTodo(int sectionId, int itemId) async {
    final section = _sectionById(sectionId);
    final item = section.items.firstWhere((element) => element.id == itemId);
    setState(() => section.items.remove(item));
    try {
      await TodoApi.delete(itemId);
    } catch (_) {
      if (mounted) setState(() => section.items.add(item));
    }
  }

  Future<void> _addTodoToSection(int sectionId) async {
    final text = _newTodoController.text.trim();
    if (text.isEmpty) return;
    try {
      final todo = await TodoApi.create(
        label: text,
        date: _dateString,
        scheduleId: sectionId == 0 ? null : sectionId,
      );
      if (!mounted) return;
      setState(() {
        _sectionById(sectionId).items.add(
          _TodoItemState(id: todo.id, label: todo.label, isDone: todo.isDone),
        );
        _newTodoController.clear();
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('할 일 저장에 실패했습니다.')),
        );
      }
    }
  }

  void _saveSectionEdits() {
    setState(() {
      _editingSectionId = null;
      _newTodoController.clear();
    });
  }

  void _handleBottomNavTap(int index) {
    switch (index) {
      case 0:
        Navigator.of(context).pushNamed(Routes.cashDetail);
        break;
      case 1:
        Navigator.of(context).pushNamed(Routes.main);
        break;
      case 2:
        Navigator.of(context).pushNamed(Routes.mypage);
        break;
    }
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
      _startHour = 13;
      _endHour = 15;
      _financeType = _FinanceType.expense;
      _selectedFinanceCategory = _expenseCategories.firstOrNull;
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('일정 제목을 입력해 주세요.')),
      );
      return;
    }

    final start = _startHour.round();
    final end = _endHour.round() <= start ? start + 1 : _endHour.round();
    final color = _palette[_selectedColorIndex];

    final amount = int.tryParse(_amountController.text.trim());
    final selectedCategory = _categories.where(
      (category) => category.name == _selectedFinanceCategory &&
          category.type == (_financeType == _FinanceType.expense ? 'EXPENSE' : 'INCOME'),
    ).firstOrNull;

    final selectedPaymentMethod = _paymentMethods.where((method) => method.id == _selectedPaymentMethodId).firstOrNull;

    if (amount != null && amount > 0 && (selectedCategory == null || selectedPaymentMethod == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('수입·지출 카테고리와 지출 수단을 불러온 뒤 다시 시도해 주세요.')),
      );
      return;
    }

    try {
      final schedule = await ScheduleApi.create(
        title: title,
        date: _dateString,
        startHour: start,
        endHour: end,
        colorHex: '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
      );

      AccountRecordModel? createdRecord;
      if (amount != null && amount > 0 && selectedCategory != null && selectedPaymentMethod != null) {
        createdRecord = await AccountRecordApi.create(
          amount: amount,
          categoryId: selectedCategory.id,
          paymentMethodId: selectedPaymentMethod.id,
          scheduleId: schedule.id,
          date: _dateString,
        );
      }

      final createdTodos = await Future.wait(_draftTodos.map(
        (todo) => TodoApi.create(label: todo, date: _dateString, scheduleId: schedule.id),
      ));

      if (!mounted) return;
      setState(() {
      _scheduleBlocks.add(
        _ScheduleBlock(
          id: schedule.id,
          title: title,
          startHour: start,
          endHour: end,
          color: color.withValues(alpha: 0.45),
        ),
      );

      _sections.insert(
        _sections.length - 1,
        _TodoSectionState(
          id: schedule.id,
          title: '$title ${_formatHour(_startHour)}-${_formatHour(_endHour)}',
          color: color.withValues(alpha: 0.35),
          items: createdTodos
              .map((todo) => _TodoItemState(id: todo.id, label: todo.label, isDone: todo.isDone))
              .toList(),
        ),
      );

      if (createdRecord != null) {
        _financeEntries.insert(0, createdRecord);
      }

      _detailMode = _DetailMode.todo;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('일정 또는 수입·지출 저장에 실패했습니다.')),
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

  _TodoSectionState _sectionById(int sectionId) {
    return _sections.firstWhere((section) => section.id == sectionId);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 820;

    return Scaffold(
      backgroundColor: _surfaceColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF1F1),
        elevation: 0,
        centerTitle: true,
        title: Text(
          _formattedDate,
          style: const TextStyle(
            color: Color(0xFF667195),
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _accentColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: isWide
            ? Row(
                children: [
                  Expanded(
                    flex: 11,
                    child: _TimeTablePanel(
                      blocks: _scheduleBlocks,
                      onBlockLongPress: _openEditMode,
                    ),
                  ),
                  Expanded(
                    flex: 13,
                    child: _DetailPanel(
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
                      startHour: _startHour,
                      endHour: _endHour,
                      financeType: _financeType,
                      activeCategories: _activeCategories,
                      selectedFinanceCategory: _selectedFinanceCategory ?? '',
                      paymentMethods: _paymentMethods,
                      selectedPaymentMethodId: _selectedPaymentMethodId,
                      onPaymentMethodChanged: (value) => setState(() => _selectedPaymentMethodId = value),
                      draftTodos: _draftTodos,
                      onModeSelected: _setMode,
                      onSectionLongPress: _openEditMode,
                      onTodoChanged: _toggleTodo,
                      onTodoLabelChanged: _updateTodoLabel,
                      onTodoDeleted: _removeTodo,
                      onSectionTodoAdded: _addTodoToSection,
                      onSectionEditCanceled: _closeEditMode,
                      onSectionEditSaved: _saveSectionEdits,
                      onPrepareAddMode: _prepareAddMode,
                      onDraftTodoAdded: _addDraftTodo,
                      onDraftTodoRemoved: _removeDraftTodo,
                      onColorSelected: (index) {
                        setState(() => _selectedColorIndex = index);
                      },
                      onStartHourChanged: (value) {
                        setState(() => _startHour = value);
                      },
                      onEndHourChanged: (value) {
                        setState(() => _endHour = value);
                      },
                      onFinanceTypeChanged: _changeFinanceType,
                      onFinanceCategoryChanged: (value) {
                        setState(() => _selectedFinanceCategory = value);
                      },
                      onSubmitNewSchedule: _submitNewSchedule,
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  SizedBox(
                    height: 360,
                    child: _TimeTablePanel(
                      blocks: _scheduleBlocks,
                      onBlockLongPress: _openEditMode,
                    ),
                  ),
                  Expanded(
                    child: _DetailPanel(
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
                      startHour: _startHour,
                      endHour: _endHour,
                      financeType: _financeType,
                      activeCategories: _activeCategories,
                      selectedFinanceCategory: _selectedFinanceCategory ?? '',
                      paymentMethods: _paymentMethods,
                      selectedPaymentMethodId: _selectedPaymentMethodId,
                      onPaymentMethodChanged: (value) => setState(() => _selectedPaymentMethodId = value),
                      draftTodos: _draftTodos,
                      onModeSelected: _setMode,
                      onSectionLongPress: _openEditMode,
                      onTodoChanged: _toggleTodo,
                      onTodoLabelChanged: _updateTodoLabel,
                      onTodoDeleted: _removeTodo,
                      onSectionTodoAdded: _addTodoToSection,
                      onSectionEditCanceled: _closeEditMode,
                      onSectionEditSaved: _saveSectionEdits,
                      onPrepareAddMode: _prepareAddMode,
                      onDraftTodoAdded: _addDraftTodo,
                      onDraftTodoRemoved: _removeDraftTodo,
                      onColorSelected: (index) {
                        setState(() => _selectedColorIndex = index);
                      },
                      onStartHourChanged: (value) {
                        setState(() => _startHour = value);
                      },
                      onEndHourChanged: (value) {
                        setState(() => _endHour = value);
                      },
                      onFinanceTypeChanged: _changeFinanceType,
                      onFinanceCategoryChanged: (value) {
                        setState(() => _selectedFinanceCategory = value);
                      },
                      onSubmitNewSchedule: _submitNewSchedule,
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6F7A9B),
        onPressed: _prepareAddMode,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: _handleBottomNavTap,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white,
        backgroundColor: _accentColor,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.wallet), label: 'CASH'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'HOME'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'MYPAGE'),
        ],
      ),
    );
  }
}

class _TimeTablePanel extends StatelessWidget {
  final List<_ScheduleBlock> blocks;
  final ValueChanged<int> onBlockLongPress;

  const _TimeTablePanel({
    required this.blocks,
    required this.onBlockLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDCD6D6)),
      ),
      child: ListView.builder(
        itemCount: 25,
        itemBuilder: (context, index) {
          final hour = index.toString().padLeft(2, '0');
          final block = _blockForHour(index);

          return GestureDetector(
            onLongPress: block == null ? null : () => onBlockLongPress(block.id),
            child: Container(
              height: 28,
              decoration: BoxDecoration(
                color: block?.color,
                border: Border(
                  top: BorderSide(color: Colors.blueGrey.shade200, width: 0.8),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 38,
                    child: Text(
                      '$hour:00',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: List.generate(
                        4,
                        (lineIndex) => Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: Colors.blueGrey.shade100,
                                  width: 0.8,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  _ScheduleBlock? _blockForHour(int hour) {
    for (final block in blocks) {
      if (hour >= block.startHour && hour < block.endHour) {
        return block;
      }
    }
    return null;
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
  final double startHour;
  final double endHour;
  final _FinanceType financeType;
  final List<String> activeCategories;
  final String selectedFinanceCategory;
  final List<PaymentMethodModel> paymentMethods;
  final int? selectedPaymentMethodId;
  final ValueChanged<int?> onPaymentMethodChanged;
  final List<String> draftTodos;
  final ValueChanged<_DetailMode> onModeSelected;
  final ValueChanged<int> onSectionLongPress;
  final void Function(int sectionId, int itemId, bool? checked) onTodoChanged;
  final void Function(int sectionId, int itemId, String value) onTodoLabelChanged;
  final void Function(int sectionId, int itemId) onTodoDeleted;
  final ValueChanged<int> onSectionTodoAdded;
  final VoidCallback onSectionEditCanceled;
  final VoidCallback onSectionEditSaved;
  final VoidCallback onPrepareAddMode;
  final VoidCallback onDraftTodoAdded;
  final ValueChanged<String> onDraftTodoRemoved;
  final ValueChanged<int> onColorSelected;
  final ValueChanged<double> onStartHourChanged;
  final ValueChanged<double> onEndHourChanged;
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
    required this.startHour,
    required this.endHour,
    required this.financeType,
    required this.activeCategories,
    required this.selectedFinanceCategory,
    required this.paymentMethods,
    required this.selectedPaymentMethodId,
    required this.onPaymentMethodChanged,
    required this.draftTodos,
    required this.onModeSelected,
    required this.onSectionLongPress,
    required this.onTodoChanged,
    required this.onTodoLabelChanged,
    required this.onTodoDeleted,
    required this.onSectionTodoAdded,
    required this.onSectionEditCanceled,
    required this.onSectionEditSaved,
    required this.onPrepareAddMode,
    required this.onDraftTodoAdded,
    required this.onDraftTodoRemoved,
    required this.onColorSelected,
    required this.onStartHourChanged,
    required this.onEndHourChanged,
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
                ),
              _DetailMode.finance => _FinancePanel(entries: financeEntries),
              _DetailMode.add => _ScheduleAddPanel(
                  palette: palette,
                  selectedColorIndex: selectedColorIndex,
                  titleController: titleController,
                  amountController: amountController,
                  memoController: memoController,
                  todoController: newTodoController,
                  startHour: startHour,
                  endHour: endHour,
                  financeType: financeType,
                  activeCategories: activeCategories,
                  selectedFinanceCategory: selectedFinanceCategory,
                  paymentMethods: paymentMethods,
                  selectedPaymentMethodId: selectedPaymentMethodId,
                  onPaymentMethodChanged: onPaymentMethodChanged,
                  draftTodos: draftTodos,
                  onColorSelected: onColorSelected,
                  onStartHourChanged: onStartHourChanged,
                  onEndHourChanged: onEndHourChanged,
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
            color: isActive ? Colors.white : const Color(0xFFF5F0F0),
            border: Border(
              bottom: BorderSide(
                color: isActive ? const Color(0xFF6F7A9B) : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isActive ? Colors.black87 : Colors.black45,
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
              border: Border.all(color: const Color(0xFFE1C9CC)),
            ),
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                if (section.items.isEmpty && !isEditing)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      '등록된 할 일이 없습니다.',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
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
                  Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: onSectionEditCanceled,
                          child: const Text('취소'),
                        ),
                        FilledButton(
                          onPressed: onSectionEditSaved,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF6F7A9B),
                          ),
                          child: const Text('저장'),
                        ),
                      ],
                    ),
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
        activeColor: const Color(0xFF6F7A9B),
        value: item.isDone,
        onChanged: (checked) => onChanged(sectionId, item.id, checked),
        title: Text(
          item.label,
          style: TextStyle(
            fontSize: 12,
            decoration: item.isDone ? TextDecoration.lineThrough : null,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.drag_indicator, size: 16, color: Colors.black38),
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
            color: const Color(0xFFFFF4F4),
            border: Border.all(color: const Color(0xFFE1C9CC)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                color: const Color(0xFFF6B7B7),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text(
                  group.key,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ...group.value.map(
                (entry) => ListTile(
                  dense: true,
                  title: Text(entry.categoryName, style: const TextStyle(fontSize: 12)),
                  subtitle: Text(
                    entry.categoryType == 'INCOME' ? '수입' : '지출',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: Text(
                    _formatAmount(
                      entry.categoryType == 'INCOME' ? entry.amount : -entry.amount,
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: entry.categoryType == 'INCOME'
                          ? const Color(0xFF1B5E20)
                          : const Color(0xFFB71C1C),
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
  final double startHour;
  final double endHour;
  final _FinanceType financeType;
  final List<String> activeCategories;
  final String selectedFinanceCategory;
  final List<PaymentMethodModel> paymentMethods;
  final int? selectedPaymentMethodId;
  final ValueChanged<int?> onPaymentMethodChanged;
  final List<String> draftTodos;
  final ValueChanged<int> onColorSelected;
  final ValueChanged<double> onStartHourChanged;
  final ValueChanged<double> onEndHourChanged;
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
    required this.startHour,
    required this.endHour,
    required this.financeType,
    required this.activeCategories,
    required this.selectedFinanceCategory,
    required this.paymentMethods,
    required this.selectedPaymentMethodId,
    required this.onPaymentMethodChanged,
    required this.draftTodos,
    required this.onColorSelected,
    required this.onStartHourChanged,
    required this.onEndHourChanged,
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
                        ? Colors.black87
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
              child: _HourSelector(
                label: '시작 시간',
                value: startHour,
                onChanged: onStartHourChanged,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _HourSelector(
                label: '종료 시간',
                value: endHour,
                onChanged: onEndHourChanged,
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
                decoration: const InputDecoration(
                  hintText: '할 일을 입력하세요',
                  border: UnderlineInputBorder(),
                ),
              ),
            ),
            IconButton(onPressed: onDraftTodoAdded, icon: const Icon(Icons.add)),
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
        const _FieldLabel('카테고리'),
        ...activeCategories.map(
          (category) => RadioListTile<String>(
            dense: true,
            contentPadding: EdgeInsets.zero,
            value: category,
            groupValue: selectedFinanceCategory,
            onChanged: (value) {
              if (value != null) onFinanceCategoryChanged(value);
            },
            title: Text(category, style: const TextStyle(fontSize: 13)),
          ),
        ),
        const SizedBox(height: 12),
        const _FieldLabel('지출 수단'),
        DropdownButtonFormField<int>(
          value: selectedPaymentMethodId,
          decoration: const InputDecoration(border: UnderlineInputBorder()),
          items: paymentMethods
              .map((method) => DropdownMenuItem(value: method.id, child: Text(method.name)))
              .toList(),
          onChanged: onPaymentMethodChanged,
        ),
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
        FilledButton(
          onPressed: onSubmit,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF6F7A9B),
          ),
          child: const Text('일정 추가'),
        ),
      ],
    );
  }
}

class _HourSelector extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const _HourSelector({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        DropdownButtonFormField<double>(
          value: value,
          decoration: const InputDecoration(border: UnderlineInputBorder()),
          items: List.generate(
            24,
            (index) => DropdownMenuItem<double>(
              value: index.toDouble(),
              child: Text(_formatHour(index.toDouble())),
            ),
          ),
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
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ScheduleBlock {
  final int id;
  final String title;
  final int startHour;
  final int endHour;
  final Color color;

  const _ScheduleBlock({
    required this.id,
    required this.title,
    required this.startHour,
    required this.endHour,
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

String _formatHour(double hour) {
  final rounded = hour.round().toString().padLeft(2, '0');
  return '$rounded:00';
}

String _formatAmount(int amount) {
  final sign = amount >= 0 ? '+' : '-';
  final number = amount.abs().toString();
  return '$sign$number';
}
