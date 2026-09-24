import 'package:flutter/material.dart';

import 'dart:convert';
import '../../services/api_client.dart';
import '../../services/token_storage.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/app_primary_button.dart';
import '../../widgets/template/base_scaffold.dart';
import '../../widgets/template/bottom_nav_layout.dart';

class MyProfileManageScreen extends StatefulWidget {
  const MyProfileManageScreen({super.key});

  @override
  State<MyProfileManageScreen> createState() => _MyProfileManageScreenState();
}

class _MyProfileManageScreenState extends State<MyProfileManageScreen> {
  String _email = '';
  final _currentPwCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  final _confirmPwCtrl = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEmail();
  }

  Future<void> _loadEmail() async {
    final email = await TokenStorage.loadEmail();
    if (mounted) setState(() => _email = email ?? '');
  }

  @override
  void dispose() {
    _currentPwCtrl.dispose();
    _newPwCtrl.dispose();
    _confirmPwCtrl.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final current = _currentPwCtrl.text;
    final next = _newPwCtrl.text;
    final confirm = _confirmPwCtrl.text;

    if (current.isEmpty || next.isEmpty || confirm.isEmpty) {
      setState(() => _errorMessage = '모든 항목을 입력해 주세요.');
      return;
    }
    if (next != confirm) {
      setState(() => _errorMessage = '새 비밀번호가 일치하지 않습니다.');
      return;
    }
    if (next.length < 8) {
      setState(() => _errorMessage = '비밀번호는 8자 이상이어야 합니다.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await ApiClient.put('/api/v1/members/me/password', {
        'currentPassword': current,
        'newPassword': next,
      });
      if (res.statusCode != 200 && res.statusCode != 204) {
        final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        throw Exception(body['message'] ?? '비밀번호 변경에 실패했습니다.');
      }
      if (!mounted) return;
      _currentPwCtrl.clear();
      _newPwCtrl.clear();
      _confirmPwCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호가 변경되었습니다.')),
      );
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: '내 정보 관리',
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.large),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: AppColors.textPrimary,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _email.isNotEmpty ? _email.substring(0, 1).toUpperCase() : '-',
                          style: AppTextStyles.emphasis.copyWith(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _email.isEmpty ? '-' : _email.split('@').first,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(_email, style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('비밀번호 변경', style: AppTextStyles.subtitle),
                const SizedBox(height: 12),
                _PwField(controller: _currentPwCtrl, label: '현재 비밀번호', hint: '현재 비밀번호 입력'),
                const SizedBox(height: 10),
                _PwField(controller: _newPwCtrl, label: '새 비밀번호', hint: '새 비밀번호 (8자 이상)'),
                const SizedBox(height: 10),
                _PwField(controller: _confirmPwCtrl, label: '새 비밀번호 확인', hint: '새 비밀번호 재입력'),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _errorMessage!,
                    style: AppTextStyles.caption.copyWith(color: AppColors.expenseAccent),
                  ),
                ],
                const SizedBox(height: 20),
                AppPrimaryButton(
                  onPressed: _isLoading ? null : _changePassword,
                  label: _isLoading ? '변경 중...' : '비밀번호 변경',
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentItem: AppNavItem.mypage),
    );
  }
}

class _PwField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;

  const _PwField({required this.controller, required this.label, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: true,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textTertiary),
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
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
              borderSide: const BorderSide(color: AppColors.primaryPink, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
