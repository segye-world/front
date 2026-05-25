import 'package:flutter/material.dart';

import '../../models/account_record_model.dart';
import '../../services/category_api.dart';
import '../../widgets/template/base_scaffold.dart';
import '../../widgets/template/bottom_nav_layout.dart';

class MyExpenseCategoryScreen extends StatefulWidget {
  const MyExpenseCategoryScreen({super.key});

  @override
  State<MyExpenseCategoryScreen> createState() => _MyExpenseCategoryScreenState();
}

class _MyExpenseCategoryScreenState extends State<MyExpenseCategoryScreen> {
  List<CategoryModel> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final categories = await CategoryApi.fetchAll();
      if (!mounted) return;
      setState(() => _categories = categories);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showAddDialog() async {
    final result = await showDialog<_CategoryFormResult>(
      context: context,
      builder: (_) => const _CategoryFormDialog(),
    );
    if (result == null) return;
    try {
      await CategoryApi.create(name: result.name, type: result.type);
      await _loadCategories();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('카테고리 추가에 실패했습니다.')),
        );
      }
    }
  }

  Future<void> _showEditDialog(CategoryModel cat) async {
    final result = await showDialog<_CategoryFormResult>(
      context: context,
      builder: (_) => _CategoryFormDialog(initial: cat),
    );
    if (result == null) return;
    try {
      await CategoryApi.update(id: cat.id, name: result.name, type: result.type);
      await _loadCategories();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('카테고리 수정에 실패했습니다.')),
        );
      }
    }
  }

  Future<void> _delete(CategoryModel cat) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('카테고리 삭제', style: TextStyle(fontSize: 15)),
        content: Text('"${cat.name}" 카테고리를 삭제할까요?',
            style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('삭제',
                  style: TextStyle(color: Color(0xFFE05353)))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await CategoryApi.delete(id: cat.id);
      await _loadCategories();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('카테고리 삭제에 실패했습니다.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseList = _categories.where((c) => c.type == 'EXPENSE').toList();
    final incomeList = _categories.where((c) => c.type == 'INCOME').toList();

    return BaseScaffold(
      title: '지출 수단 및 카테고리',
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFFF7A5A5), strokeWidth: 2))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSection('지출 카테고리', expenseList, 'EXPENSE'),
                      const SizedBox(height: 20),
                      _buildSection('수입 카테고리', incomeList, 'INCOME'),
                    ],
                  ),
          ),
          const AppBottomNavBar(currentItem: AppNavItem.mypage),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<CategoryModel> list, String type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700)),
            TextButton.icon(
              onPressed: _showAddDialog,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('추가', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFF7A5A5),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (list.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('카테고리가 없어요.',
                style: TextStyle(fontSize: 13, color: Colors.black45)),
          )
        else
          ...list.map(
            (c) => _CategoryRow(
              category: c,
              onEdit: () => _showEditDialog(c),
              onDelete: () => _delete(c),
            ),
          ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryRow({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEE0E0)),
      ),
      child: Row(
        children: [
          Icon(
            category.type == 'INCOME' ? Icons.trending_up : Icons.trending_down,
            size: 16,
            color: category.type == 'INCOME'
                ? const Color(0xFF5AAD72)
                : const Color(0xFFE05353),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category.name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  category.type == 'INCOME' ? '수입' : '지출',
                  style: const TextStyle(fontSize: 11, color: Colors.black45),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 16,
                color: Color(0xFFF7A5A5)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 16,
                color: Colors.black26),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

class _CategoryFormResult {
  final String name;
  final String type;
  const _CategoryFormResult({required this.name, required this.type});
}

class _CategoryFormDialog extends StatefulWidget {
  final CategoryModel? initial;
  const _CategoryFormDialog({this.initial});

  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  late TextEditingController _nameCtrl;
  late String _type;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initial?.name ?? '');
    _type = widget.initial?.type ?? 'EXPENSE';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isEdit ? '카테고리 수정' : '카테고리 추가',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                hintText: '카테고리 이름',
                filled: true,
                fillColor: const Color(0xFFF8F9FB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE0E3E8)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE0E3E8)),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _TypeChip(
                    label: '지출',
                    isActive: _type == 'EXPENSE',
                    activeColor: const Color(0xFFE05353),
                    onTap: () => setState(() => _type = 'EXPENSE'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TypeChip(
                    label: '수입',
                    isActive: _type == 'INCOME',
                    activeColor: const Color(0xFF5AAD72),
                    onTap: () => setState(() => _type = 'INCOME'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('취소'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final name = _nameCtrl.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('이름을 입력해 주세요.')),
                        );
                        return;
                      }
                      Navigator.pop(
                          context, _CategoryFormResult(name: name, type: _type));
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFF7A5A5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(isEdit ? '저장' : '추가'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? activeColor.withValues(alpha: 0.1) : Colors.transparent,
          border: Border.all(
            color: isActive ? activeColor : Colors.black26,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive ? activeColor : Colors.black45,
          ),
        ),
      ),
    );
  }
}
