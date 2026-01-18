import 'package:flutter/material.dart';

class BaseScaffold extends StatelessWidget {
  final Widget body;
  final String? title;

  const BaseScaffold({required this.body, this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: title != null ? AppBar(title: Text(title!)) : null,
      body: body,
    );
  }
}