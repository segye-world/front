import 'package:flutter/material.dart';

import '../../routes/routes.dart';
import '../../api/auth_api.dart';
import '../../services/notification_service.dart';
import '../../services/token_storage.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/app_dialog.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/template/app_top_bar.dart';
import '../../widgets/template/bottom_nav_layout.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  final AuthApi _authApi = AuthApi();
  String _nickname = '';

  @override
  void initState() {
    super.initState();
    _loadNickname();
  }

  Future<void> _loadNickname() async {
    final stored = await TokenStorage.loadNickname();
    if (mounted) setState(() => _nickname = stored ?? '');
  }

  Future<void> _logout(BuildContext context) async {
    await NotificationService.instance.clear();
    await _authApi.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(Routes.login, (r) => false);
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AppDialog(
        title: '회원 탈퇴',
        content: const Text('정말 탈퇴하시겠습니까?\n모든 데이터가 삭제됩니다.'),
        confirmLabel: '탈퇴',
        confirmColor: AppColors.expenseAccent,
        onConfirm: () => Navigator.pop(ctx, true),
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await _authApi.deleteAccount();
      await NotificationService.instance.clear();
      if (!context.mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(Routes.login, (r) => false);
    } catch (e, stackTrace) {
      if (!context.mounted) return;
      showErrorSnackBar(
        context,
        e,
        fallback: '회원 탈퇴에 실패했습니다.',
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _nickname.isEmpty ? '온하루 사용자' : _nickname;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AppTopBar(title: 'MY PAGE', showBack: false),
      body: SafeArea(
        child: Column(
          children: [
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
                            color: AppColors.textPrimary,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            displayName.characters.first,
                            style: AppTextStyles.emphasis.copyWith(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '카카오 계정으로 로그인',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textTertiary,
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
                      color: AppColors.textSecondary,
                      onTap: () => _logout(context),
                    ),
                    const SizedBox(height: 14),
                    _ActionRow(
                      label: '탈퇴하기',
                      color: AppColors.expenseAccent,
                      onTap: () => _deleteAccount(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentItem: AppNavItem.mypage),
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
            Icon(icon, size: 20, color: AppColors.textTertiary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textTertiary),
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
          const Icon(Icons.logout, size: 20, color: AppColors.textTertiary),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
