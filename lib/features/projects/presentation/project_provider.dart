import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/project_model.dart';
import '../data/repositories/project_repository.dart';

final projectRepositoryProvider = Provider<ProjectRepository>((ref) => ProjectRepository());

final projectsProvider = StateNotifierProvider<ProjectsNotifier, List<ProjectModel>>((ref) {
  return ProjectsNotifier(ref.read(projectRepositoryProvider));
});

final currentProjectProvider = StateNotifierProvider<CurrentProjectNotifier, ProjectModel?>((ref) {
  return CurrentProjectNotifier();
});

class ProjectsNotifier extends StateNotifier<List<ProjectModel>> {
  final ProjectRepository _repo;
  ProjectsNotifier(this._repo) : super([]) { load(); }

  void load() => state = _repo.getAllProjects();

  Future<ProjectModel> createProject({required String name, String? initialCode}) async {
    final project = await _repo.createProject(name: name, initialCode: initialCode);
    load();
    return project;
  }

  Future<void> deleteProject(String id) async {
    await _repo.deleteProject(id);
    load();
  }

  Future<void> renameProject(String id, String newName) async {
    final project = _repo.getProject(id);
    if (project == null) return;
    await _repo.saveProject(project.copyWith(name: newName));
    load();
  }
}

class CurrentProjectNotifier extends StateNotifier<ProjectModel?> {
  CurrentProjectNotifier() : super(null);
  void setProject(ProjectModel project) => state = project;
  void clearProject() => state = null;
  void updateProject(ProjectModel project) => state = project;
}
