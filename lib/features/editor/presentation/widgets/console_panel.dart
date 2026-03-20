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
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();

  @override
  void dispose() {
    _scrollController.dispose();
    _inputController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final execution = ref.watch(executionProvider);
    final settings = ref.watch(settingsProvider);

    if (_inputController.text != execution.terminalInput) {
      _inputController.value = TextEditingValue(
        text: execution.terminalInput,
        selection: TextSelection.collapsed(offset: execution.terminalInput.length),
      );
    }

    if (execution.outputEntries.isNotEmpty) _scrollToBottom();
    if (execution.isWaitingForInput) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _inputFocusNode.requestFocus();
      });
    }

    return Container(
      color: AppTheme.terminalBackground(context),
      child: Column(
        children: [
          Expanded(
            child: execution.outputEntries.isEmpty
                ? Center(
                    child: Text(
                      'No output yet. Run your code to see terminal activity.',
                      style: TextStyle(
                        color: AppTheme.terminalHint(context),
                        fontSize: 12,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: execution.outputEntries.length,
                    itemBuilder: (_, i) => _OutputLine(
                      entry: execution.outputEntries[i],
                      fontSize: settings.fontSize * 0.9,
                    ),
                  ),
          ),
          if (execution.isRunning)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.terminalSurface(context),
                border: Border(
                  top: BorderSide(color: AppTheme.editorBorder(context)),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    execution.isWaitingForInput ? Icons.keyboard_alt_outlined : Icons.play_arrow_rounded,
                    size: 16,
                    color: execution.isWaitingForInput
                        ? AppTheme.terminalPrompt(context)
                        : AppTheme.terminalSuccess(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      execution.isWaitingForInput
                          ? 'Program is waiting for input. Type below and press Enter.'
                          : 'Program is running. Output streams here live.',
                      style: TextStyle(
                        color: execution.isWaitingForInput
                            ? AppTheme.terminalPrompt(context)
                            : AppTheme.terminalHint(context),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => ref.read(executionProvider.notifier).stopCode(),
                    icon: const Icon(Icons.stop, size: 14),
                    label: const Text('Stop', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.terminalError(context),
                    ),
                  ),
                ],
              ),
            ),
          _TerminalInputBar(
            controller: _inputController,
            focusNode: _inputFocusNode,
            waitingForInput: execution.isWaitingForInput,
            onChanged: (value) => ref.read(executionProvider.notifier).setTerminalInput(value),
            onSubmit: (_) => ref.read(executionProvider.notifier).submitTerminalInput(),
          ),
          Container(
            height: 40,
            color: AppTheme.editorPanel(context),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: () => ref.read(executionProvider.notifier).clearConsole(),
                  icon: const Icon(Icons.delete_sweep_outlined, size: 14),
                  label: const Text('Clear', style: TextStyle(fontSize: 11)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.editorMutedText(context),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    final text = execution.outputEntries.map((entry) => entry.text).join('');
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Output copied'), duration: Duration(seconds: 1)),
                    );
                  },
                  icon: const Icon(Icons.copy_outlined, size: 14),
                  label: const Text('Copy', style: TextStyle(fontSize: 11)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.editorMutedText(context),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TerminalInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool waitingForInput;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmit;

  const _TerminalInputBar({
    required this.controller,
    required this.focusNode,
    required this.waitingForInput,
    required this.onChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: AppTheme.terminalSurface(context),
        border: Border(top: BorderSide(color: AppTheme.editorBorder(context))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              waitingForInput ? '›' : '⏸',
              style: GoogleFonts.jetBrainsMono(
                color: waitingForInput
                    ? AppTheme.terminalPrompt(context)
                    : AppTheme.terminalHint(context),
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: waitingForInput,
              minLines: 1,
              maxLines: 3,
              onChanged: onChanged,
              onSubmitted: onSubmit,
              style: GoogleFonts.jetBrainsMono(
                color: waitingForInput
                    ? AppTheme.terminalInput(context)
                    : AppTheme.terminalHint(context),
                fontSize: 13,
                height: 1.4,
              ),
              cursorColor: AppTheme.cursorColor(context),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: AppTheme.editorBackground(context),
                hintText: waitingForInput
                    ? 'Enter one line of input and press Enter'
                    : 'Input will activate here when the program calls input()',
                hintStyle: GoogleFonts.jetBrainsMono(
                  color: AppTheme.terminalHint(context),
                  fontSize: 12,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppTheme.editorBorder(context)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppTheme.editorBorder(context)),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppTheme.editorBorder(context)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppTheme.terminalPrompt(context)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OutputLine extends StatelessWidget {
  final ConsoleEntry entry;
  final double fontSize;
  const _OutputLine({required this.entry, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Text(
      entry.text,
      style: GoogleFonts.jetBrainsMono(
        fontSize: fontSize,
        color: _resolveColor(context),
        height: 1.5,
      ),
    );
  }

  Color _resolveColor(BuildContext context) {
    return switch (entry.type) {
      ConsoleEntryType.stderr => AppTheme.terminalError(context),
      ConsoleEntryType.system => entry.text.startsWith('✓') || entry.text.contains('Completed')
          ? AppTheme.terminalSuccess(context)
          : entry.text.startsWith('⚠') || entry.text.startsWith('⏱')
              ? AppTheme.terminalWarning(context)
              : AppTheme.terminalPrompt(context),
      ConsoleEntryType.prompt => AppTheme.terminalPrompt(context),
      ConsoleEntryType.input => AppTheme.terminalInput(context),
      _ => AppTheme.terminalText(context),
    };
  }
}
