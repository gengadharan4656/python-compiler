import 'package:flutter/material.dart';
import '../features/editor/presentation/editor_screen.dart';
import '../features/packages/presentation/packages_screen.dart';
import '../features/projects/presentation/home_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/templates/presentation/templates_screen.dart';
import 'splash_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String home = '/home';
  static const String editor = '/editor';
  static const String packages = '/packages';
  static const String settings = '/settings';
  static const String templates = '/templates';

  static Map<String, WidgetBuilder> get routes => {
    splash: (_) => const SplashScreen(),
    home: (_) => const HomeScreen(),
    editor: (_) => const EditorScreen(),
    packages: (_) => const PackagesScreen(),
    settings: (_) => const SettingsScreen(),
    templates: (_) => const TemplatesScreen(),
  };
}
