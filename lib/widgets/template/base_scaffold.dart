import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'app_top_bar.dart';

class BaseScaffold extends StatelessWidget {
  final Widget body;
  final String? title;
  final PreferredSizeWidget? appBar;
  final Color backgroundColor;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final EdgeInsetsGeometry? bodyPadding;
  final double? maxBodyWidth;
  final bool centerBody;
  final bool useSafeArea;

  const BaseScaffold({
    super.key,
    required this.body,
    this.title,
    this.appBar,
    this.backgroundColor = AppColors.background,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.bodyPadding,
    this.maxBodyWidth,
    this.centerBody = false,
    this.useSafeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = body;

    if (bodyPadding != null) {
      content = Padding(padding: bodyPadding!, child: content);
    }

    if (maxBodyWidth != null) {
      content = Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxBodyWidth!),
          child: content,
        ),
      );
    }

    if (centerBody) {
      content = Center(child: content);
    }

    if (useSafeArea) {
      content = SafeArea(child: content);
    }

    return Scaffold(
      // 하단 바(Liquid Glass)가 본문 위에 떠 있도록 본문을 바 뒤까지 늘립니다.
      // 본문은 SafeArea 가 바 높이만큼 비켜 줍니다.
      extendBody: true,
      backgroundColor: backgroundColor,
      appBar: appBar ?? (title != null ? AppTopBar(title: title!) : null),
      body: content,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
