import 'package:flutter/material.dart';

import 'dart:convert';
import '../../services/api_client.dart';
import '../../services/token_storage.dart';
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
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEEE0E0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Color(0xFF242424),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _email.isNotEmpty ? _email.substring(0, 1).toUpperCase() : '-',
                          style: const TextStyle(color: Colors.white, fontSize: 18),
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
                            Text(
                              _email,
                              style: const TextStyle(fontSize: 12, color: Colors.black45),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  '비밀번호 변경',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
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
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _changePassword,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFF7A5A5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(_isLoading ? '변경 중...' : '비밀번호 변경'),
                  ),
                ),
              ],
            ),
          ),
          const AppBottomNavBar(currentItem: AppNavItem.mypage),
        ],
      ),
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
        Text(label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: true,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black26),
            filled: true,
            fillColor: const Color(0xFFF8F9FB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E3E8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E3E8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFF3A3A4), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
