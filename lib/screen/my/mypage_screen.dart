import 'package:flutter/material.dart';

import '../../routes/routes.dart';
import '../../api/auth_api.dart';
import '../../services/token_storage.dart';
import '../../widgets/template/bottom_nav_layout.dart';

class MyPageScreen extends StatefulWidget {
  final String loginEmail;

  const MyPageScreen({super.key, this.loginEmail = ''});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  final AuthApi _authApi = AuthApi();
  String _email = '';

  @override
  void initState() {
    super.initState();
    _loadEmail();
  }

  Future<void> _loadEmail() async {
    // 인자로 받은 이메일 우선, 없으면 저장된 토큰에서 로드합니다.
    if (widget.loginEmail.isNotEmpty) {
      setState(() => _email = widget.loginEmail);
    } else {
      final stored = await TokenStorage.loadEmail();
      if (mounted) setState(() => _email = stored ?? '');
    }
  }

  Future<void> _logout(BuildContext context) async {
    await TokenStorage.clear();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(Routes.login, (r) => false);
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('회원 탈퇴'),
        content: const Text('정말 탈퇴하시겠습니까?\n모든 데이터가 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('탈퇴', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await _authApi.deleteAccount();
      await TokenStorage.clear();
      if (!context.mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(Routes.login, (r) => false);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayId = _email.isEmpty ? '' : _email.split('@').first;
    final displayEmail = _email.isEmpty ? '' : _email;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F1),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 44,
              color: const Color(0xFFFBEFEF),
              child: const Center(
                child: Text(
                  'MY PAGE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4F5E82),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: Color(0xFF242424),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            displayId.isEmpty ? '?' : displayId.substring(0, 1),
                            style: const TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayId,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF6B6B6B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              displayEmail,
                              style: const TextStyle(
                                color: Color(0xFFBABABA),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 26),
                    _MenuRow(
                      icon: Icons.access_time_rounded,
                      label: '지출 수단 및 카테고리',
                      onTap: () => Navigator.of(context).pushNamed(
                        Routes.myExpenseCategory,
                      ),
                    ),
                    _MenuRow(
                      icon: Icons.favorite_border,
                      label: '내 정보 관리',
                      onTap: () => Navigator.of(context).pushNamed(
                        Routes.myProfile,
                      ),
                    ),
                    _MenuRow(
                      icon: Icons.settings_outlined,
                      label: '알림 설정',
                      onTap: () => Navigator.of(context).pushNamed(
                        Routes.myNotification,
                      ),
                    ),
                    _MenuRow(
                      icon: Icons.help_outline,
                      label: 'FAQ',
                      onTap: () => Navigator.of(context).pushNamed(
                        Routes.myFaq,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _ActionRow(
                      label: '로그아웃',
                      color: const Color(0xFF616161),
                      onTap: () => _logout(context),
                    ),
                    const SizedBox(height: 14),
                    _ActionRow(
                      label: '탈퇴하기',
                      color: const Color(0xFFE58787),
                      onTap: () => _deleteAccount(context),
                    ),
                  ],
                ),
              ),
            ),
            const AppBottomNavBar(currentItem: AppNavItem.mypage),
          ],
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF8B97B0)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Color(0xFF4F4F4F)),
              ),
            ),
            const Icon(Icons.chevron_right, size: 16, color: Color(0xFFB0B8C8)),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionRow({required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          const Icon(Icons.logout, size: 15, color: Color(0xFF8B97B0)),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
