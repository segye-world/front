import 'package:flutter/material.dart';

import '../../data/mock_erd_repository.dart';
import '../../widgets/template/base_scaffold.dart';
import '../../widgets/template/bottom_nav_layout.dart';

class MyExpenseCategoryScreen extends StatelessWidget {
  final String loginEmail;

  const MyExpenseCategoryScreen({super.key, this.loginEmail = ''});

  @override
  Widget build(BuildContext context) {
    final repository = MockErdRepository.instance;
    // ✅ 설정 화면의 지출 수단/카테고리도 로그인 회원 id 기준으로만 표시합니다.
    final id = repository.idForEmail(loginEmail);
    final categories = repository.categoriesById(id);
    final paymentMethods = repository.paymentMethodsById(id);

    return BaseScaffold(
      title: '지출 수단 및 카테고리',
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const _SectionTitle(title: '카테고리'),
                // ✅ ERD의 Category 데이터를 목데이터로 표시하며, 백엔드 연동 시 실제 CRUD 응답으로 대체됩니다.
                ...categories.map((category) => _SettingRow(title: category.name, subtitle: category.type)),
                const SizedBox(height: 20),
                const _SectionTitle(title: '지불수단'),
                // ✅ ERD의 PaymentMethod 데이터를 목데이터로 표시하며, 백엔드 연동 시 실제 CRUD 응답으로 대체됩니다.
                ...paymentMethods.map((method) => _SettingRow(title: method.name, subtitle: 'id: ${method.id}')),
              ],
            ),
          ),
          // ✅ 모든 페이지 공통 하단 탭 바 유지
          BottomNavLayout(loginEmail: loginEmail, currentTab: BottomNavType.myPage),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SettingRow({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black45)),
            ],
          ),
          const Icon(Icons.edit_outlined, size: 16, color: Color(0xFFF7A5A5)),
        ],
      ),
    );
  }
}
