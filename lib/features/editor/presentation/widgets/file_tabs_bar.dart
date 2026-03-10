import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../projects/data/models/project_model.dart';
import '../../../projects/data/repositories/project_repository.dart';
import '../../../projects/presentation/project_provider.dart';
import '../editor_provider.dart';

class FileTabsBar extends ConsumerWidget {
  final ProjectModel project;
  const FileTabsBar({super.key, required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFile = ref.watch(currentFileProvider);
    final unsaved = ref.watch(unsavedFilesProvider);

    return Container(
      height: 36, color: AppTheme.darkSurface,
      child: Row(children: [
        Expanded(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: project.files.length,
            itemBuilder: (_, i) {
              final file = project.files[i];
              final isActive = file == currentFile;
              final isDirty = unsaved.contains(file);
              return _FileTab(
                fileName: file, isActive: isActive, isDirty: isDirty,
                onTap: () => _switchFile(ref, file),
                onClose: project.files.length > 1 ? () => _closeFile(context, ref, file) : null,
              );
            },
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add, size: 18),
          onPressed: () => _addNewFile(context, ref),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
      ]),
    );
  }

  void _switchFile(WidgetRef ref, String fileName) async {
    final project = ref.read(currentProjectProvider);
    if (project == null) return;
    final existing = ref.read(editorContentProvider.notifier).getContent(fileName);
    if (existing.isEmpty) {
      final repo = ref.read(projectRepositoryProvider);
      final content = await repo.readFile(project.id, fileName);
      ref.read(editorContentProvider.notifier).setContent(fileName, content);
    }
    ref.read(currentFileProvider.notifier).state = fileName;
  }

  Future<void> _closeFile(BuildContext context, WidgetRef ref, String fileName) async {
    final isDirty = ref.read(unsavedFilesProvider).contains(fileName);
    if (isDirty) {
      final save = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Unsaved Changes'),
          content: Text('Save changes to $fileName?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Discard')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      );
      if (save == true) {
        final project = ref.read(currentProjectProvider);
        if (project != null) {
          final content = ref.read(editorContentProvider.notifier).getContent(fileName);
          await ref.read(projectRepositoryProvider).writeFile(project.id, fileName, content);
        }
      }
    }
  }

  Future<void> _addNewFile(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: 'module.py');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New File'),
        content: TextField(controller: controller, autofocus: true,
          decoration: const InputDecoration(labelText: 'File name', hintText: 'e.g. utils.py')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Create')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      final project = ref.read(currentProjectProvider);
      if (project == null) return;
      await ref.read(projectRepositoryProvider).addFileToProject(project.id, result);
      ref.read(editorContentProvider.notifier).setContent(result, '');
      ref.read(currentFileProvider.notifier).state = result;
      final updated = ref.read(projectRepositoryProvider).getProject(project.id);
      if (updated != null) ref.read(currentProjectProvider.notifier).updateProject(updated);
    }
  }
}

class _FileTab extends StatelessWidget {
  final String fileName;
  final bool isActive;
  final bool isDirty;
  final VoidCallback onTap;
  final VoidCallback? onClose;

  const _FileTab({required this.fileName, required this.isActive, required this.isDirty,
    required this.onTap, this.onClose});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.darkBg : Colors.transparent,
          border: Border(bottom: BorderSide(
            color: isActive ? AppTheme.accentBlue : Colors.transparent, width: 2))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(fileName, style: TextStyle(fontSize: 12,
            color: isActive ? AppTheme.darkText : AppTheme.darkTextSecondary,
            fontWeight: isActive ? FontWeight.w500 : FontWeight.normal)),
          if (isDirty) ...[const SizedBox(width: 4),
            Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.accentBlue))],
          if (onClose != null) ...[const SizedBox(width: 6),
            GestureDetector(onTap: onClose,
              child: const Icon(Icons.close, size: 12, color: AppTheme.darkTextSecondary))],
        ]),
      ),
    );
  }
}
