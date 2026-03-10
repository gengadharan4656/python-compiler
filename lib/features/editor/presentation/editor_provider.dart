import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../projects/data/repositories/project_repository.dart';

final currentFileProvider = StateProvider<String>((ref) => 'main.py');

final editorContentProvider = StateNotifierProvider<EditorContentNotifier, Map<String, String>>((ref) {
  return EditorContentNotifier();
});

class EditorContentNotifier extends StateNotifier<Map<String, String>> {
  EditorContentNotifier() : super({});
  void setContent(String fileName, String content) => state = {...state, fileName: content};
  String getContent(String fileName) => state[fileName] ?? '';
  void clear() => state = {};
}

final unsavedFilesProvider = StateNotifierProvider<UnsavedFilesNotifier, Set<String>>((ref) {
  return UnsavedFilesNotifier();
});

class UnsavedFilesNotifier extends StateNotifier<Set<String>> {
  UnsavedFilesNotifier() : super({});
  void markDirty(String fileName) => state = {...state, fileName};
  void markSaved(String fileName) => state = state.difference({fileName});
  bool isDirty(String fileName) => state.contains(fileName);
  void clear() => state = {};
}
