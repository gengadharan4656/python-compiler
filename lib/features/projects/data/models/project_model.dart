import 'package:hive/hive.dart';
import '../../../../core/constants/hive_keys.dart';

part 'project_model.g.dart';

@HiveType(typeId: HiveTypeIds.projectModel)
class ProjectModel extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String name;
  @HiveField(2) String mainFile;
  @HiveField(3) DateTime createdAt;
  @HiveField(4) DateTime updatedAt;
  @HiveField(5) List<String> enabledPackages;
  @HiveField(6) List<String> files;

  ProjectModel({
    required this.id,
    required this.name,
    this.mainFile = 'main.py',
    required this.createdAt,
    required this.updatedAt,
    List<String>? enabledPackages,
    List<String>? files,
  }) : enabledPackages = enabledPackages ?? [],
       files = files ?? ['main.py'];

  ProjectModel copyWith({String? name, String? mainFile, DateTime? updatedAt,
    List<String>? enabledPackages, List<String>? files}) =>
    ProjectModel(id: id, name: name ?? this.name, mainFile: mainFile ?? this.mainFile,
      createdAt: createdAt, updatedAt: updatedAt ?? this.updatedAt,
      enabledPackages: enabledPackages ?? this.enabledPackages, files: files ?? this.files);
}
