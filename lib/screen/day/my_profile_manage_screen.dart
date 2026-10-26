import 'package:flutter/material.dart';

import '../../services/token_storage.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/template/base_scaffold.dart';
import '../../widgets/template/bottom_nav_layout.dart';

// 카카오 로그인만 쓰므로 비밀번호 변경은 없다. 닉네임은 카카오 계정에서 바꾸면 다음 로그인 때 반영된다.
class MyProfileManageScreen extends StatefulWidget {
  const MyProfileManageScreen({super.key});

  @override
  State<MyProfileManageScreen> createState() => _MyProfileManageScreenState();
}

class _MyProfileManageScreenState extends State<MyProfileManageScreen> {
  String _nickname = '';

  @override
  void initState() {
    super.initState();
    _loadNickname();
  }

  Future<void> _loadNickname() async {
    final nickname = await TokenStorage.loadNickname();
    if (mounted) setState(() => _nickname = nickname ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _nickname.isEmpty ? '온하루 사용자' : _nickname;

    return BaseScaffold(
      title: '내 정보 관리',
      backgroundColor: Colors.white,
      body: ListView(
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
                    displayName.characters.first,
                    style: AppTextStyles.emphasis.copyWith(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayName, style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      const Text('카카오 계정으로 로그인', style: AppTextStyles.caption),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '닉네임은 카카오 계정의 프로필 이름을 사용합니다. 카카오에서 바꾸면 다음 로그인 때 반영됩니다.',
            style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentItem: AppNavItem.mypage),
    );
  }
}
