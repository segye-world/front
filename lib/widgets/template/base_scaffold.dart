import 'package:flutter/material.dart';

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
    this.backgroundColor = const Color(0xFFF5F5F5),
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
      backgroundColor: backgroundColor,
      appBar: appBar ?? (title != null ? AppBar(title: Text(title!)) : null),
      body: content,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
