import 'package:flutter/material.dart';

import '../../data/mock_erd_repository.dart';
import '../../widgets/template/base_scaffold.dart';
import '../../widgets/template/bottom_nav_layout.dart';

class CashDetailScreen extends StatelessWidget {
  final String loginEmail;

  const CashDetailScreen({super.key, this.loginEmail = ''});

  @override
  Widget build(BuildContext context) {
    final records = MockErdRepository.instance.allAccountRecordViews();

    return BaseScaffold(
      title: 'Cash Detail',
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text('수입/지출 내역', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                // ✅ ERD의 AccountRecord와 Category/PaymentMethod/Schedule 조인 결과를 목데이터로 표시합니다.
                ...records.map((record) => _CashRecordCard(record: record)),
              ],
            ),
          ),
          // ✅ 모든 화면에서 하단 탭을 공통으로 유지
          BottomNavLayout(loginEmail: loginEmail, currentTab: BottomNavType.cash),
        ],
      ),
    );
  }
}

class _CashRecordCard extends StatelessWidget {
  final AccountRecordView record;

  const _CashRecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final amount = record.record.amount;
    final amountText = amount >= 0 ? '+$amount' : '$amount';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(record.category.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                '${record.paymentMethod.name} · ${_formatDateTime(record.record.transactionTime)}',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              if (record.schedule != null) ...[
                const SizedBox(height: 4),
                Text('연결 일정: ${record.schedule!.title}', style: const TextStyle(fontSize: 12, color: Colors.black45)),
              ],
            ],
          ),
          Text(
            amountText,
            style: TextStyle(
              color: amount >= 0 ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDateTime(DateTime time) =>
    '${time.month}/${time.day} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
