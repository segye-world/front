import 'package:flutter/material.dart';

import '../../data/mock_backend_data.dart';
import '../../widgets/template/base_scaffold.dart';

class CashDetailScreen extends StatelessWidget {
  const CashDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO(backend): 백엔드 수입/지출 내역 조회 API로 교체해야 하는 목데이터 조회입니다.
    final records = MockBackendData.accountRecords;
    final totalIncome = records
        .where((record) => record.amount > 0)
        .fold<int>(0, (sum, record) => sum + record.amount);
    final totalExpense = records
        .where((record) => record.amount < 0)
        .fold<int>(0, (sum, record) => sum + record.amount);

    return BaseScaffold(
      title: 'Cash Detail',
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              Expanded(child: _SummaryCard(title: '수입', amount: totalIncome)),
              const SizedBox(width: 12),
              Expanded(child: _SummaryCard(title: '지출', amount: totalExpense)),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            '수입/지출 내역',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...records.map((record) => _RecordTile(record: record)),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final int amount;

  const _SummaryCard({required this.title, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEFEF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Text(
            amount.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: amount >= 0
                  ? const Color(0xFF1B5E20)
                  : const Color(0xFFB71C1C),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  final AccountRecord record;

  const _RecordTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final category = MockBackendData.categoryById(record.categoryId);
    final paymentMethod = MockBackendData.paymentMethodById(record.paymentMethodId);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(paymentMethod.name),
        trailing: Text(
          record.amount.toString(),
          style: TextStyle(fontWeight: FontWeight.w700, color: record.amountColor),
        ),
      ),
    );
  }
}
