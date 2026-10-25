import 'package:flutter/material.dart';

/// 카카오 로그인 디자인 가이드의 버튼 규격(배경 #FEE500, 심볼·레이블 #000000, 레이블 85% 불투명도).
///
/// 심볼은 말풍선을 직접 그린 것입니다. 출시 전에 카카오 디벨로퍼스 [리소스 다운로드]의
/// 공식 심볼 이미지로 바꾸는 것을 권장합니다.
class KakaoLoginButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const KakaoLoginButton({super.key, required this.onPressed, this.isLoading = false});

  static const _background = Color(0xFFFEE500);
  static const _foreground = Color(0xFF000000);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: _background,
          foregroundColor: _foreground,
          // 로딩 중에도 카카오 버튼 색은 유지한다.
          disabledBackgroundColor: _background,
          disabledForegroundColor: _foreground.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: isLoading ? null : onPressed,
        child: Row(
          children: [
            const CustomPaint(size: Size(18, 18), painter: _KakaoSymbolPainter()),
            Expanded(
              child: Text(
                isLoading ? '로그인 중...' : '카카오 로그인',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _foreground.withValues(alpha: 0.85),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // 심볼과 대칭이 되도록 같은 폭을 비워 레이블을 정확히 가운데 둔다.
            const SizedBox(width: 18),
          ],
        ),
      ),
    );
  }
}

class _KakaoSymbolPainter extends CustomPainter {
  const _KakaoSymbolPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF000000);
    final w = size.width;
    final h = size.height;

    canvas.drawOval(Rect.fromLTWH(0, 0, w, h * 0.8), paint);
    final tail = Path()
      ..moveTo(w * 0.22, h * 0.62)
      ..lineTo(w * 0.18, h * 0.98)
      ..lineTo(w * 0.45, h * 0.74)
      ..close();
    canvas.drawPath(tail, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
