import 'package:flutter/material.dart';
import 'package:the_forge/app/app_controller.dart';
import 'package:the_forge/features/home/home_page.dart';
import 'package:the_forge/theme/app_theme.dart';

class TheForgeApp extends StatefulWidget {
  const TheForgeApp({super.key});

  @override
  State<TheForgeApp> createState() => _TheForgeAppState();
}

class _TheForgeAppState extends State<TheForgeApp> {
  late final AppController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AppController()..initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'the Forge',
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: HomePage(controller: _controller),
    );
  }
}
