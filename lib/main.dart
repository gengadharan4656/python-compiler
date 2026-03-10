import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'app/app.dart';
import 'core/constants/hive_keys.dart';
import 'features/projects/data/models/project_model.dart';
import 'features/settings/data/models/settings_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  final appDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDir.path);
  Hive.registerAdapter(ProjectModelAdapter());
  Hive.registerAdapter(SettingsModelAdapter());
  await Hive.openBox<ProjectModel>(HiveKeys.projectsBox);
  await Hive.openBox<SettingsModel>(HiveKeys.settingsBox);
  await Hive.openBox(HiveKeys.runHistoryBox);
  runApp(const ProviderScope(child: PyDroidApp()));
}
