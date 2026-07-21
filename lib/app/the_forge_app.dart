import 'package:flutter/material.dart';
import 'package:the_forge/features/home/home_page.dart';
import 'package:the_forge/theme/app_theme.dart';

class TheForgeApp extends StatelessWidget {
  const TheForgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'the Forge',
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: const HomePage(),
    );
  }
}
