import 'package:hive/hive.dart';
import '../../../../core/constants/hive_keys.dart';

part 'settings_model.g.dart';

@HiveType(typeId: HiveTypeIds.settingsModel)
class SettingsModel extends HiveObject {
  @HiveField(0) bool isDarkMode;
  @HiveField(1) double fontSize;
  @HiveField(2) int tabWidth;
  @HiveField(3) bool wordWrap;
  @HiveField(4) int executionTimeoutSeconds;
  @HiveField(5) bool showLineNumbers;
  @HiveField(6) String editorTheme;

  SettingsModel({
    this.isDarkMode = true,
    this.fontSize = 14.0,
    this.tabWidth = 4,
    this.wordWrap = false,
    this.executionTimeoutSeconds = 10,
    this.showLineNumbers = true,
    this.editorTheme = 'vs2015',
  });

  SettingsModel copyWith({bool? isDarkMode, double? fontSize, int? tabWidth,
    bool? wordWrap, int? executionTimeoutSeconds, bool? showLineNumbers, String? editorTheme}) =>
    SettingsModel(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      fontSize: fontSize ?? this.fontSize,
      tabWidth: tabWidth ?? this.tabWidth,
      wordWrap: wordWrap ?? this.wordWrap,
      executionTimeoutSeconds: executionTimeoutSeconds ?? this.executionTimeoutSeconds,
      showLineNumbers: showLineNumbers ?? this.showLineNumbers,
      editorTheme: editorTheme ?? this.editorTheme,
    );
}
