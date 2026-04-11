import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../execution/presentation/execution_provider.dart';
import '../../projects/data/repositories/project_repository.dart';
import '../../projects/presentation/project_provider.dart';
import 'editor_provider.dart';
import 'widgets/code_editor_widget.dart';
import 'widgets/console_panel.dart';
import 'widgets/file_tabs_bar.dart';

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key});
  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentFile();
  }

  Future<void> _loadCurrentFile() async {
    final project = ref.read(currentProjectProvider);
    if (project == null) return;
    final fileName = ref.read(currentFileProvider);
    final repo = ref.read(projectRepositoryProvider);
    final content = await repo.readFile(project.id, fileName);
    ref.read(editorContentProvider.notifier).setContent(fileName, content);
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(currentProjectProvider);
    final execution = ref.watch(executionProvider);
    final currentFile = ref.watch(currentFileProvider);

    if (project == null) {
      return const Scaffold(body: Center(child: Text('No project selected')));
    }

    return Scaffold(
      backgroundColor: AppTheme.editorBackground(context),
      appBar: AppBar(
        backgroundColor: AppTheme.editorSurface(context),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () async {
            await _saveCurrentFile();
            if (context.mounted) Navigator.pop(context);
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(project.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            Text(
              currentFile,
              style: TextStyle(fontSize: 11, color: AppTheme.editorMutedText(context)),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.save_outlined, size: 20), tooltip: 'Save', onPressed: _saveCurrentFile),
          IconButton(
            icon: const Icon(Icons.terminal_outlined, size: 20),
            tooltip: 'Console',
            onPressed: _openFullScreenConsole,
          ),
          execution.isRunning
              ? IconButton(
                  icon: const Icon(Icons.stop_circle, color: AppTheme.accentRed, size: 22),
                  tooltip: 'Stop',
                  onPressed: () => ref.read(executionProvider.notifier).stopCode(),
                )
              : IconButton(
                  icon: const Icon(Icons.play_circle_filled, color: AppTheme.accentGreen, size: 22),
                  tooltip: 'Run',
                  onPressed: _runCode,
                ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          FileTabsBar(project: project),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : const CodeEditorWidget(),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCurrentFile() async {
    final project = ref.read(currentProjectProvider);
    if (project == null) return;
    final fileName = ref.read(currentFileProvider);
    final content = ref.read(editorContentProvider.notifier).getContent(fileName);
    await ref.read(projectRepositoryProvider).writeFile(project.id, fileName, content);
    ref.read(unsavedFilesProvider.notifier).markSaved(fileName);
  }

  Future<void> _runCode() async {
    final executionNotifier = ref.read(executionProvider.notifier);
    if (ref.read(executionProvider).isRunning) return;

    await _saveCurrentFile();
    _openFullScreenConsole();
    final fileName = ref.read(currentFileProvider);
    final content = ref.read(editorContentProvider.notifier).getContent(fileName);
    unawaited(executionNotifier.runCode(content, entryFileName: fileName));
  }

  void _openFullScreenConsole() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const _FullScreenConsolePage()),
    );
  }
}

class _FullScreenConsolePage extends StatelessWidget {
  const _FullScreenConsolePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.terminalBackground(context),
      appBar: AppBar(
        title: const Text('Console'),
        backgroundColor: AppTheme.terminalSurface(context),
      ),
      body: ConsolePanel(
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }
}
