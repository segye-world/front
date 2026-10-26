import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';

class AuthLayout extends StatelessWidget {
  final Widget child;
  final Widget? leading;

  const AuthLayout({super.key, required this.child, this.leading});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Container(
            width: 360,
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              border: Border.all(color: AppColors.cardBorder),
              borderRadius: BorderRadius.circular(AppRadius.large),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (leading != null) leading!,
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AuthSymbol extends StatelessWidget {
  final IconData icon;

  const AuthSymbol({super.key, this.icon = Icons.calendar_month_outlined});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFFE0A7FF), Color(0xFFF9E89A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Icon(icon, size: 50, color: AppColors.navyDark),
    );
  }
}
