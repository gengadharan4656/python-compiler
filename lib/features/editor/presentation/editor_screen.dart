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
  bool _showConsole = false;
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

    if (project == null) return const Scaffold(body: Center(child: Text('No project selected')));

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkSurface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () async { await _saveCurrentFile(); if (context.mounted) Navigator.pop(context); },
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(project.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          Text(currentFile, style: const TextStyle(fontSize: 11, color: AppTheme.darkTextSecondary)),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.save_outlined, size: 20), tooltip: 'Save', onPressed: _saveCurrentFile),
          IconButton(
            icon: Icon(_showConsole ? Icons.terminal : Icons.terminal_outlined, size: 20,
              color: _showConsole ? AppTheme.accentBlue : null),
            tooltip: 'Console',
            onPressed: () => setState(() => _showConsole = true),
          ),
          execution.isRunning
            ? IconButton(
                icon: const Icon(Icons.stop_circle, color: AppTheme.accentRed, size: 22),
                tooltip: 'Stop',
                onPressed: () => ref.read(executionProvider.notifier).stopCode())
            : IconButton(
                icon: const Icon(Icons.play_circle_filled, color: AppTheme.accentGreen, size: 22),
                tooltip: 'Run',
                onPressed: _runCode),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(children: [
        FileTabsBar(project: project),
        const Divider(height: 1),
        Expanded(
          child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(children: [
                Expanded(flex: _showConsole ? 3 : 1, child: const CodeEditorWidget()),
                if (_showConsole) ...[
                  Container(
                    height: 28, color: AppTheme.darkPanel,
                    child: Row(children: [
                      const SizedBox(width: 12),
                      const Icon(Icons.terminal, size: 14, color: AppTheme.accentBlue),
                      const SizedBox(width: 6),
                      const Text('Console', style: TextStyle(color: AppTheme.accentBlue, fontSize: 12, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                        onPressed: () => setState(() => _showConsole = false),
                        padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                      const SizedBox(width: 8),
                    ]),
                  ),
                  Expanded(flex: 2, child: ConsolePanel(onClose: () => setState(() => _showConsole = false))),
                ],
              ]),
        ),
      ]),
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
    await _saveCurrentFile();
    final fileName = ref.read(currentFileProvider);
    final content = ref.read(editorContentProvider.notifier).getContent(fileName);
    setState(() => _showConsole = true);
    await ref.read(executionProvider.notifier).runCode(content);
  }
}
