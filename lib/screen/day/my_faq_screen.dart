import 'package:flutter/material.dart';

import '../../widgets/template/base_scaffold.dart';
import '../../widgets/template/bottom_nav_layout.dart';

class MyFaqScreen extends StatelessWidget {
  const MyFaqScreen({super.key});

  static const _items = [
    _FaqItem(
      question: '일정은 어떻게 추가하나요?',
      answer: '날짜 상세 화면 우측 하단의 + 버튼을 누른 후 "일정 새로 만들기"를 선택하세요. '
          '제목, 시작/종료 시간, 색상을 설정할 수 있습니다.',
    ),
    _FaqItem(
      question: '할 일을 일정에 연결할 수 있나요?',
      answer: '네. 날짜 상세 화면의 할 일 탭에서 각 일정 카드 하단의 입력창에 '
          '할 일을 입력하면 해당 일정에 연결됩니다. "일정 외 할일" 카드에 입력하면 '
          '독립적인 할 일이 생성됩니다.',
    ),
    _FaqItem(
      question: '수입·지출은 어디서 기록하나요?',
      answer: '날짜 상세 화면의 + 버튼 → "수입·지출 기입" 또는 소비(CASH) 탭의 '
          '"수입·지출 추가" 버튼을 이용하세요.',
    ),
    _FaqItem(
      question: '기록한 가계부 내역을 삭제하려면?',
      answer: '날짜 상세 화면의 "수입·지출" 탭에서 항목을 왼쪽으로 스와이프하면 삭제할 수 있습니다.',
    ),
    _FaqItem(
      question: '카테고리를 추가하거나 변경할 수 있나요?',
      answer: '마이페이지 → "지출 수단 및 카테고리"에서 카테고리 목록을 확인하고 편집할 수 있습니다.',
    ),
    _FaqItem(
      question: '비밀번호를 변경하려면?',
      answer: '마이페이지 → "내 정보 관리"에서 현재 비밀번호 확인 후 새 비밀번호로 변경할 수 있습니다.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: 'FAQ',
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _FaqTile(item: _items[i]),
            ),
          ),
          const AppBottomNavBar(currentItem: AppNavItem.mypage),
        ],
      ),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;
  const _FaqItem({required this.question, required this.answer});
}

class _FaqTile extends StatefulWidget {
  final _FaqItem item;
  const _FaqTile({required this.item});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEE0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Text('Q. ', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFF7A5A5))),
                  Expanded(
                    child: Text(
                      widget.item.question,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.black38,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Text(
                widget.item.answer,
                style: const TextStyle(fontSize: 12, color: Colors.black54, height: 1.6),
              ),
            ),
        ],
      ),
    );
  }
}
