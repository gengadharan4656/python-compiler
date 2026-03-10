import 'dart:io';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/hive_keys.dart';
import '../models/project_model.dart';

class ProjectRepository {
  final Box<ProjectModel> _box = Hive.box<ProjectModel>(HiveKeys.projectsBox);
  final _uuid = const Uuid();

  List<ProjectModel> getAllProjects() =>
      _box.values.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  ProjectModel? getProject(String id) => _box.get(id);

  Future<ProjectModel> createProject({required String name, String? initialCode}) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final project = ProjectModel(id: id, name: name, createdAt: now, updatedAt: now);
    await _box.put(id, project);
    final dir = await _getProjectDir(id);
    await dir.create(recursive: true);
    await File('${dir.path}/main.py').writeAsString(initialCode ?? '# $name\n\nprint("Hello from $name!")\n');
    return project;
  }

  Future<void> saveProject(ProjectModel project) async {
    project.updatedAt = DateTime.now();
    await _box.put(project.id, project);
  }

  Future<void> deleteProject(String id) async {
    await _box.delete(id);
    final dir = await _getProjectDir(id);
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  Future<String> readFile(String projectId, String fileName) async {
    final dir = await _getProjectDir(projectId);
    final file = File('${dir.path}/$fileName');
    return await file.exists() ? await file.readAsString() : '';
  }

  Future<void> writeFile(String projectId, String fileName, String content) async {
    final dir = await _getProjectDir(projectId);
    await dir.create(recursive: true);
    await File('${dir.path}/$fileName').writeAsString(content);
    final project = _box.get(projectId);
    if (project != null) { project.updatedAt = DateTime.now(); await project.save(); }
  }

  Future<void> addFileToProject(String projectId, String fileName) async {
    final project = _box.get(projectId);
    if (project == null || project.files.contains(fileName)) return;
    final updatedFiles = List<String>.from(project.files)..add(fileName);
    await _box.put(projectId, project.copyWith(files: updatedFiles));
    final dir = await _getProjectDir(projectId);
    final file = File('${dir.path}/$fileName');
    if (!await file.exists()) await file.writeAsString('');
  }

  Future<void> deleteFileFromProject(String projectId, String fileName) async {
    final project = _box.get(projectId);
    if (project == null) return;
    final updatedFiles = List<String>.from(project.files)..remove(fileName);
    await _box.put(projectId, project.copyWith(files: updatedFiles));
    final dir = await _getProjectDir(projectId);
    final file = File('${dir.path}/$fileName');
    if (await file.exists()) await file.delete();
  }

  Future<String> getProjectPath(String projectId) async {
    final dir = await _getProjectDir(projectId);
    return dir.path;
  }

  Future<Directory> _getProjectDir(String projectId) async {
    final appDir = await getApplicationDocumentsDirectory();
    return Directory('${appDir.path}/projects/$projectId');
  }
}
