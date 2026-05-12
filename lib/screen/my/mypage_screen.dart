import 'package:flutter/material.dart';

import '../../routes/routes.dart';
import '../../widgets/template/bottom_nav_layout.dart';

class MyPageScreen extends StatelessWidget {
  final String loginEmail;

  const MyPageScreen({super.key, this.loginEmail = ''});

  @override
  Widget build(BuildContext context) {
    // ✅ 로그인 이메일을 아이디/이메일 표시에 재사용합니다.
    final displayId = loginEmail.isEmpty ? '김' : loginEmail.split('@').first;
    final displayEmail = loginEmail.isEmpty ? 'email.com' : loginEmail;

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
                            displayId.isEmpty ? '김' : displayId.substring(0, 1),
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
                        arguments: {'loginEmail': loginEmail},
                      ),
                    ),
                    _MenuRow(
                      icon: Icons.favorite_border,
                      label: '내 정보 관리',
                      onTap: () => Navigator.of(context).pushNamed(
                        Routes.myProfile,
                        arguments: {'loginEmail': loginEmail},
                      ),
                    ),
                    _MenuRow(
                      icon: Icons.settings_outlined,
                      label: '알림 설정',
                      onTap: () => Navigator.of(context).pushNamed(
                        Routes.myNotification,
                        arguments: {'loginEmail': loginEmail},
                      ),
                    ),
                    _MenuRow(
                      icon: Icons.help_outline,
                      label: 'FAQ',
                      onTap: () => Navigator.of(context).pushNamed(
                        Routes.myFaq,
                        arguments: {'loginEmail': loginEmail},
                      ),
                    ),
                    const SizedBox(height: 24),
                    _ActionRow(
                      label: '로그아웃',
                      color: const Color(0xFF616161),
                      onTap: () {
                        // ✅ 로그아웃 시 로그인 페이지만 남기고 스택을 정리합니다.
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          Routes.login,
                          (route) => false,
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    const _ActionRow(
                      label: '탈퇴하기',
                      color: Color(0xFFE58787),
                    ),
                  ],
                ),
              ),
            ),
            BottomNavLayout(
              loginEmail: loginEmail,
              currentTab: BottomNavType.myPage,
            ),
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
