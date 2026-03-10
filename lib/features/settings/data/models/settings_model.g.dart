// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'settings_model.dart';

class SettingsModelAdapter extends TypeAdapter<SettingsModel> {
  @override
  final int typeId = 1;

  @override
  SettingsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SettingsModel(
      isDarkMode: fields[0] as bool? ?? true,
      fontSize: fields[1] as double? ?? 14.0,
      tabWidth: fields[2] as int? ?? 4,
      wordWrap: fields[3] as bool? ?? false,
      executionTimeoutSeconds: fields[4] as int? ?? 10,
      showLineNumbers: fields[5] as bool? ?? true,
      editorTheme: fields[6] as String? ?? 'vs2015',
    );
  }

  @override
  void write(BinaryWriter writer, SettingsModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)..write(obj.isDarkMode)
      ..writeByte(1)..write(obj.fontSize)
      ..writeByte(2)..write(obj.tabWidth)
      ..writeByte(3)..write(obj.wordWrap)
      ..writeByte(4)..write(obj.executionTimeoutSeconds)
      ..writeByte(5)..write(obj.showLineNumbers)
      ..writeByte(6)..write(obj.editorTheme);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsModelAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
