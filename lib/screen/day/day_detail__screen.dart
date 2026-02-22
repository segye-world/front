import 'package:flutter/material.dart';
import '../../widgets/template/base_scaffold.dart';

class DayDetailScreen extends StatefulWidget {
  final DateTime selectedDate;

  const DayDetailScreen({super.key, required this.selectedDate});

  @override
  State<DayDetailScreen> createState() => _DayDetailScreenState();
}

class _DayDetailScreenState extends State<DayDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Format the date for the title
    String formattedDate = "${widget.selectedDate.year}년 ${widget.selectedDate.month.toString().padLeft(2, '0')}월 ${widget.selectedDate.day.toString().padLeft(2, '0')}일";

    return BaseScaffold(
      title: formattedDate, // Display the selected date
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
      body: Row(
        children: [
          // Left side: Time Table
          Expanded(flex: 2, child: _TimeTableWidget()),
          // Right side: Tabbed content (To-do / Income-Expense)
          Expanded(
            flex: 3,
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: '할 일'),
                    Tab(text: '수입 · 지출'),
                  ],
                  labelColor: Colors.black, // Active tab text color
                  unselectedLabelColor: Colors.grey, // Inactive tab text color
                  indicatorColor: Colors.black, // Indicator line color
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _TodoTabContent(), // Content for '할 일' tab
                      const Center(
                        child: Text('수입 · 지출 내용'),
                      ), // Placeholder for '수입 · 지출' tab
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement add schedule/todo functionality
          print('Add button pressed');
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.wallet), label: 'CASH'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'HOME'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'MYPAGE'),
        ],
        currentIndex: 1, // Assuming HOME is the default/current page
        selectedItemColor: Colors.black, // Adjust color as per design
        unselectedItemColor: Colors.grey, // Adjust color as per design
        backgroundColor: Colors.pink[100], // Adjust color as per design
        onTap: (index) {
          // TODO: Implement navigation logic
          print('Tapped item $index');
        },
      ),
    );
  }
}

class _TimeTableWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 24, // 00:00 to 23:00
      itemBuilder: (context, index) {
        String hour = index.toString().padLeft(2, '0');
        Color? backgroundColor;
        if (index >= 7 && index < 11) {
          backgroundColor =
              Colors.red[50]; // Example shaded area 1 (7:00-11:00)
        } else if (index >= 11 && index < 13) {
          backgroundColor =
              Colors.orange[50]; // Example shaded area 2 (11:00-13:00)
        }
        return Container(
          height: 50, // Height of each hour slot
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border(
              bottom: BorderSide(color: Colors.grey[300]!, width: 0.5),
            ),
          ),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                  child: Text(
                    '$hour:00',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 25, // Halfway point for the dotted line
                child: Divider(
                  color: Colors.grey[200],
                  thickness: 0.5,
                  height: 1,
                  indent: 40,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TodoTabContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        // Scheduled To-dos
        _buildTodoSection(
          context,
          '아침 공부 07:00~09:30',
          ['백준 알고리즘 실버 2문제', '듀오링고 영어 1일차', '소시계 8주차 복습', '운영체제 8주차 복습'],
          Colors.red[100], // Background color from the image
        ),
        _buildTodoSection(
          context,
          '영어 공부 10:00~16:30',
          [], // No items shown in the image for this section
          Colors.orange[100], // Background color from the image
        ),
        // Unscheduled To-dos
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            '일정 외 할 일',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ),
        _buildTodoSection(
          context,
          '', // No title for unscheduled section
          [
            // Example unscheduled tasks
            // '빨래하기',
            // '장보기',
          ],
          Colors.grey[200], // Background color from the image
          showTitle: false,
        ),
      ],
    );
  }

  Widget _buildTodoSection(
    BuildContext context,
    String title,
    List<String> todos,
    Color? backgroundColor, {
    bool showTitle = true,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTitle && title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ...todos.map(
            (todo) => CheckboxListTile(
              controlAffinity: ListTileControlAffinity.leading,
              value: false, // For now, all unchecked
              onChanged: (bool? value) {
                // TODO: Implement checkbox functionality
                print('Checkbox for "$todo" changed to $value');
              },
              title: Text(todo),
            ),
          ),
          if (todos.isEmpty &&
              !showTitle) // Add a placeholder if no unscheduled todos
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text('등록된 할 일이 없습니다.'),
            ),
        ],
      ),
    );
  }
}
