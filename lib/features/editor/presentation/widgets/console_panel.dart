import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../execution/presentation/execution_provider.dart';
import '../../../settings/presentation/settings_provider.dart';

class ConsolePanel extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  const ConsolePanel({super.key, required this.onClose});

  @override
  ConsumerState<ConsolePanel> createState() => _ConsolePanelState();
}

class _ConsolePanelState extends ConsumerState<ConsolePanel> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final execution = ref.watch(executionProvider);
    final settings = ref.watch(settingsProvider);
    if (execution.outputLines.isNotEmpty) _scrollToBottom();

    return Container(
      color: AppTheme.darkBg,
      child: Column(
        children: [
          Expanded(
            child: execution.outputLines.isEmpty
              ? Center(child: Text('No output yet. Run your code to see results.',
                  style: TextStyle(color: AppTheme.darkTextSecondary.withOpacity(0.5), fontSize: 12)))
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: execution.outputLines.length,
                  itemBuilder: (_, i) => _OutputLine(text: execution.outputLines[i], fontSize: settings.fontSize * 0.9),
                ),
          ),
          if (execution.isRunning)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: AppTheme.accentBlue.withOpacity(0.1),
              child: Row(children: [
                SizedBox(width: 12, height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentBlue))),
                const SizedBox(width: 8),
                const Text('Running...', style: TextStyle(color: AppTheme.accentBlue, fontSize: 12)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => ref.read(executionProvider.notifier).stopCode(),
                  icon: const Icon(Icons.stop, size: 14),
                  label: const Text('Stop', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.accentRed),
                ),
              ]),
            ),
          Container(
            height: 36, color: AppTheme.darkPanel,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(children: [
              TextButton.icon(
                onPressed: () => ref.read(executionProvider.notifier).clearConsole(),
                icon: const Icon(Icons.delete_sweep_outlined, size: 14),
                label: const Text('Clear', style: TextStyle(fontSize: 11)),
                style: TextButton.styleFrom(foregroundColor: AppTheme.darkTextSecondary, padding: const EdgeInsets.symmetric(horizontal: 8)),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  final text = execution.outputLines.join('');
                  Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Output copied'), duration: Duration(seconds: 1)));
                },
                icon: const Icon(Icons.copy_outlined, size: 14),
                label: const Text('Copy', style: TextStyle(fontSize: 11)),
                style: TextButton.styleFrom(foregroundColor: AppTheme.darkTextSecondary, padding: const EdgeInsets.symmetric(horizontal: 8)),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _OutputLine extends StatelessWidget {
  final String text;
  final double fontSize;
  const _OutputLine({required this.text, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    Color color = AppTheme.darkText;
    if (text.contains('Traceback') || text.contains('Error:') || text.startsWith('✗')) color = AppTheme.accentRed;
    else if (text.startsWith('▶') || text.startsWith('✓')) color = AppTheme.accentGreen;
    else if (text.startsWith('⏱') || text.startsWith('⚠')) color = AppTheme.accentYellow;
    return Text(text, style: GoogleFonts.jetBrainsMono(fontSize: fontSize, color: color, height: 1.5));
  }
}
