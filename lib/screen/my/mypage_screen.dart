import 'package:flutter/material.dart';

class MyPageScreen extends StatelessWidget {
  final String loginEmail;

  const MyPageScreen({super.key, this.loginEmail = ''});

  @override
  Widget build(BuildContext context) {
    // ✅ 로그인 이메일을 id처럼 활용하기 위해 @ 앞부분을 이름으로 변환
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
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Color(0xFFE59A9A)),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const Expanded(
                    child: Text(
                      'MY PAGE',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF4F5E82)),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
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
                              style: const TextStyle(color: Color(0xFFBABABA), fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 26),
                    const _MenuRow(icon: Icons.access_time_rounded, label: '지출 수단 및 카테고리'),
                    const _MenuRow(icon: Icons.favorite_border, label: '내 정보 관리'),
                    const _MenuRow(icon: Icons.settings_outlined, label: '알림 설정'),
                    const _MenuRow(icon: Icons.help_outline, label: 'FAQ'),
                    const SizedBox(height: 24),
                    const _ActionRow(label: '로그아웃', color: Color(0xFF616161)),
                    const SizedBox(height: 14),
                    const _ActionRow(label: '탈퇴하기', color: Color(0xFFE58787)),
                  ],
                ),
              ),
            ),
            Container(
              height: 56,
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7A5A5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                children: [
                  _BottomMenu(label: 'CASH'),
                  _BottomMenu(label: 'HOME'),
                  _BottomMenu(label: 'MYPAGE'),
                ],
              ),
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

  const _MenuRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF8B97B0)),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Color(0xFF4F4F4F))),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final String label;
  final Color color;

  const _ActionRow({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.logout, size: 15, color: Color(0xFF8B97B0)),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _BottomMenu extends StatelessWidget {
  final String label;

  const _BottomMenu({required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          border: Border(right: BorderSide(color: Colors.white54, width: 1)),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
