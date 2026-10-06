import 'package:flutter/material.dart';

import '../../services/notification_service.dart';
import '../../services/notification_settings.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/template/base_scaffold.dart';
import '../../widgets/template/bottom_nav_layout.dart';

class MyNotificationSettingScreen extends StatefulWidget {
  const MyNotificationSettingScreen({super.key});

  @override
  State<MyNotificationSettingScreen> createState() =>
      _MyNotificationSettingScreenState();
}

class _MyNotificationSettingScreenState
    extends State<MyNotificationSettingScreen> with WidgetsBindingObserver {
  final _service = NotificationService.instance;
  NotificationSettings? _settings;
  bool _permitted = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 시스템 설정에서 권한을 켜고 돌아오면 안내 배너를 갱신합니다.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshPermission();
  }

  Future<void> _load() async {
    final settings = await NotificationSettings.load();
    final permitted = await _service.isPermitted();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _permitted = permitted;
    });
  }

  Future<void> _refreshPermission() async {
    final permitted = await _service.isPermitted();
    if (mounted) setState(() => _permitted = permitted);
  }

  Future<void> _update(NotificationSettings next, {required bool turnedOn}) async {
    if (turnedOn && !_permitted) {
      final granted = await _service.requestPermission();
      if (!mounted) return;
      setState(() => _permitted = granted);
      if (!granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('기기 설정에서 알림을 허용해 주세요.'),
            action: SnackBarAction(label: '설정 열기', onPressed: _service.openSystemSettings),
          ),
        );
        return;
      }
    }
    setState(() => _settings = next);
    await next.save();
    await _service.sync();
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;
    return BaseScaffold(
      title: '알림 설정',
      backgroundColor: Colors.white,
      body: settings == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (!_service.isSupported)
                  const _NoticeBox(message: '이 기기에서는 알림을 지원하지 않아요.')
                else if (!_permitted)
                  _NoticeBox(
                    message: '기기 알림이 꺼져 있어 알림을 받을 수 없어요.',
                    actionLabel: '설정 열기',
                    onAction: _service.openSystemSettings,
                  ),
                if (!_service.isSupported || !_permitted) const SizedBox(height: 16),
                _NotificationTile(
                  icon: Icons.calendar_today_outlined,
                  title: '일정 시작 알림',
                  subtitle: '일정 시작 30분 전에 그 일정의 할 일을 알려드려요',
                  value: settings.scheduleStart,
                  onChanged: (v) => _update(settings.copyWith(scheduleStart: v), turnedOn: v),
                ),
                const SizedBox(height: 8),
                _NotificationTile(
                  icon: Icons.timer_outlined,
                  title: '일정 종료 알림',
                  subtitle: '일정 끝나기 10분 전, 남은 할 일이 있으면 알려드려요',
                  value: settings.scheduleEnd,
                  onChanged: (v) => _update(settings.copyWith(scheduleEnd: v), turnedOn: v),
                ),
                const SizedBox(height: 8),
                _NotificationTile(
                  icon: Icons.nightlight_outlined,
                  title: '하루 마무리 알림',
                  subtitle: '밤 10시에 오늘 못 끝낸 할 일이 있으면 알려드려요',
                  value: settings.dailyWrapUp,
                  onChanged: (v) => _update(settings.copyWith(dailyWrapUp: v), turnedOn: v),
                ),
                const SizedBox(height: 8),
                const _NotificationTile(
                  icon: Icons.bar_chart_outlined,
                  title: '주간 소비 리포트',
                  subtitle: '준비 중인 기능이에요',
                  value: false,
                  onChanged: null,
                ),
                const SizedBox(height: 16),
                Text(
                  '할 일이 없는 일정은 알림을 보내지 않아요. 절전 상태에서는 몇 분 늦게 도착할 수 있어요.',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
      bottomNavigationBar: const AppBottomNavBar(currentItem: AppNavItem.mypage),
    );
  }
}

class _NoticeBox extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _NoticeBox({required this.message, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      constraints: const BoxConstraints(minHeight: 48),
      decoration: BoxDecoration(
        color: AppColors.warningBackground,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: AppColors.warningBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 20, color: AppColors.warningIcon),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: AppTextStyles.small.fontSize, color: AppColors.warningText),
            ),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;

  /// null 이면 비활성(준비 중) 상태로 그립니다.
  final ValueChanged<bool>? onChanged;

  const _NotificationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primaryPink),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppColors.primaryPink,
            ),
          ],
        ),
      ),
    );
  }
}
