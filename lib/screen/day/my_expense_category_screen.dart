import 'package:flutter/material.dart';

import '../../models/account_record_model.dart';
import '../../services/category_api.dart';
import '../../services/finance_settings_api.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';
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
      await FinanceSettingsApi.ensureDefaults();
      final categories = await CategoryApi.fetchAll();
      if (!mounted) return;
      setState(() => _categories = categories);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showAddDialog(String type) async {
    final result = await showDialog<_CategoryFormResult>(
      context: context,
      builder: (_) => _CategoryFormDialog(initialType: type),
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
        title: const Text('카테고리 삭제'),
        content: Text('"${cat.name}" 카테고리를 삭제할까요?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('삭제',
                  style: TextStyle(color: AppColors.expenseAccent))),
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
      title: '지출 카테고리 및 수입원',
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primaryPink, strokeWidth: 2))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSection('지출 카테고리', expenseList, 'EXPENSE'),
                      const SizedBox(height: 20),
                      _buildSection('수입원', incomeList, 'INCOME'),
                    ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentItem: AppNavItem.mypage),
    );
  }

  Widget _buildSection(String title, List<CategoryModel> list, String type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTextStyles.subtitle),
            TextButton.icon(
              onPressed: () => _showAddDialog(type),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('추가', style: AppTextStyles.label),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryPink,
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (list.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('카테고리가 없어요.', style: AppTextStyles.caption),
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(
            category.type == 'INCOME' ? Icons.trending_up : Icons.trending_down,
            size: 20,
            color: category.type == 'INCOME'
                ? AppColors.incomeAccent
                : AppColors.expenseAccent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category.name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  category.type == 'INCOME' ? '수입원' : '지출',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18,
                color: AppColors.primaryPink),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 18,
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
  final String initialType;
  const _CategoryFormDialog({this.initial, this.initialType = 'EXPENSE'});

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
    _type = widget.initial?.type ?? widget.initialType;
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isEdit ? '카테고리 수정' : '카테고리 추가', style: AppTextStyles.title),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                hintText: '카테고리 이름',
                filled: true,
                fillColor: AppColors.inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  borderSide: const BorderSide(color: AppColors.inputBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  borderSide: const BorderSide(color: AppColors.inputBorder),
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
                    activeColor: AppColors.expenseAccent,
                    onTap: () => setState(() => _type = 'EXPENSE'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TypeChip(
                    label: '수입원',
                    isActive: _type == 'INCOME',
                    activeColor: AppColors.incomeAccent,
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
          borderRadius: BorderRadius.circular(AppRadius.button),
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
