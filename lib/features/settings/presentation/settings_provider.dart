import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../../core/constants/hive_keys.dart';
import '../data/models/settings_model.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsModel>((ref) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<SettingsModel> {
  final Box _box = Hive.box<SettingsModel>(HiveKeys.settingsBox);

  SettingsNotifier() : super(
    Hive.box<SettingsModel>(HiveKeys.settingsBox).get('settings') ?? SettingsModel(),
  );

  Future<void> update(SettingsModel settings) async {
    state = settings;
    await _box.put('settings', settings);
  }

  Future<void> toggleDarkMode() async => update(state.copyWith(isDarkMode: !state.isDarkMode));
  Future<void> setFontSize(double size) async => update(state.copyWith(fontSize: size));
  Future<void> setTabWidth(int width) async => update(state.copyWith(tabWidth: width));
  Future<void> setWordWrap(bool wrap) async => update(state.copyWith(wordWrap: wrap));
  Future<void> setExecutionTimeout(int secs) async => update(state.copyWith(executionTimeoutSeconds: secs));
  Future<void> setShowLineNumbers(bool show) async => update(state.copyWith(showLineNumbers: show));
}
