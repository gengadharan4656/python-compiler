import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../execution/presentation/execution_provider.dart';
import '../../../settings/presentation/settings_provider.dart';

class ConsolePanel extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  final ScrollController? scrollController;

  const ConsolePanel({
    super.key,
    required this.onClose,
    this.scrollController,
  });

  @override
  ConsumerState<ConsolePanel> createState() => _ConsolePanelState();
}

class _ConsolePanelState extends ConsumerState<ConsolePanel> {
  late final ScrollController _scrollController;
  late final bool _ownsScrollController;
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _ownsScrollController = widget.scrollController == null;
    _scrollController = widget.scrollController ?? ScrollController();
  }

  @override
  void dispose() {
    if (_ownsScrollController) {
      _scrollController.dispose();
    }
    _inputController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final offset = _scrollController.position.maxScrollExtent;
      if (animated) {
        _scrollController.animateTo(
          offset,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(offset);
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

    if (execution.outputEntries.isNotEmpty || execution.isWaitingForInput) {
      _scrollToBottom(animated: execution.outputEntries.length > 1);
    }

    if (execution.isWaitingForInput) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _inputFocusNode.requestFocus();
        _scrollToBottom(animated: false);
      });
    }

    return Container(
      color: AppTheme.terminalBackground(context),
      child: Column(
        children: [
          _ConsoleToolbar(
            isRunning: execution.isRunning,
            isWaitingForInput: execution.isWaitingForInput,
            onStop: () => ref.read(executionProvider.notifier).stopCode(),
            onClear: () => ref.read(executionProvider.notifier).clearConsole(),
            onCopy: () {
              final text = execution.outputEntries.map((entry) => entry.text).join();
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Transcript copied'), duration: Duration(seconds: 1)),
              );
            },
          ),
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              children: [
                if (execution.outputEntries.isEmpty && !execution.isRunning)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Ready.',
                      style: GoogleFonts.jetBrainsMono(
                        color: AppTheme.terminalHint(context),
                        fontSize: settings.fontSize * 0.82,
                      ),
                    ),
                  ),
                ...execution.outputEntries.map(
                  (entry) => _OutputLine(
                    entry: entry,
                    fontSize: settings.fontSize * 0.92,
                  ),
                ),
                if (execution.isWaitingForInput)
                  _InlineTerminalInput(
                    prompt: execution.activePrompt,
                    controller: _inputController,
                    focusNode: _inputFocusNode,
                    fontSize: settings.fontSize * 0.92,
                    onChanged: (value) => ref.read(executionProvider.notifier).setTerminalInput(value),
                    onSubmit: (_) => ref.read(executionProvider.notifier).submitTerminalInput(),
                  )
                else if (execution.isRunning)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '…',
                      style: GoogleFonts.jetBrainsMono(
                        color: AppTheme.terminalHint(context),
                        fontSize: settings.fontSize * 0.92,
                        height: 1.45,
                      ),
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

class _ConsoleToolbar extends StatelessWidget {
  final bool isRunning;
  final bool isWaitingForInput;
  final VoidCallback onStop;
  final VoidCallback onClear;
  final VoidCallback onCopy;

  const _ConsoleToolbar({
    required this.isRunning,
    required this.isWaitingForInput,
    required this.onStop,
    required this.onClear,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final statusLabel = isWaitingForInput
        ? 'stdin'
        : isRunning
            ? 'running'
            : 'idle';
    final statusColor = isWaitingForInput
        ? AppTheme.terminalPrompt(context)
        : isRunning
            ? AppTheme.terminalSuccess(context)
            : AppTheme.terminalHint(context);

    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.terminalSurface(context),
        border: Border(
          bottom: BorderSide(color: AppTheme.terminalDivider(context)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.terminal, size: 15, color: AppTheme.terminalHint(context)),
          const SizedBox(width: 8),
          Text(
            statusLabel,
            style: GoogleFonts.jetBrainsMono(
              color: statusColor,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          _ToolbarButton(
            icon: Icons.copy_all_outlined,
            label: 'Copy',
            onPressed: onCopy,
          ),
          const SizedBox(width: 4),
          _ToolbarButton(
            icon: Icons.delete_sweep_outlined,
            label: 'Clear',
            onPressed: onClear,
          ),
          if (isRunning) ...[
            const SizedBox(width: 4),
            _ToolbarButton(
              icon: Icons.stop_circle_outlined,
              label: 'Stop',
              color: AppTheme.terminalError(context),
              onPressed: onStop,
            ),
          ],
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onPressed;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = color ?? AppTheme.terminalHint(context);
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: foreground,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        textStyle: GoogleFonts.jetBrainsMono(fontSize: 11.5, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _InlineTerminalInput extends StatelessWidget {
  final String prompt;
  final TextEditingController controller;
  final FocusNode focusNode;
  final double fontSize;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmit;

  const _InlineTerminalInput({
    required this.prompt,
    required this.controller,
    required this.focusNode,
    required this.fontSize,
    required this.onChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.jetBrainsMono(
      color: AppTheme.terminalInput(context),
      fontSize: fontSize,
      height: 1.45,
    );

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (prompt.isNotEmpty)
            Flexible(
              child: Text(
                prompt,
                style: GoogleFonts.jetBrainsMono(
                  color: AppTheme.terminalPrompt(context),
                  fontSize: fontSize,
                  height: 1.45,
                ),
              ),
            ),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              minLines: 1,
              maxLines: 1,
              onChanged: onChanged,
              onSubmitted: onSubmit,
              style: style,
              cursorColor: AppTheme.cursorColor(context),
              autocorrect: false,
              enableSuggestions: false,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: prompt.isEmpty ? 'input' : null,
                hintStyle: style.copyWith(color: AppTheme.terminalHint(context)),
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
    return SelectableText(
      entry.text,
      style: GoogleFonts.jetBrainsMono(
        fontSize: fontSize,
        color: _resolveColor(context),
        height: 1.45,
      ),
    );
  }

  Color _resolveColor(BuildContext context) {
    return switch (entry.type) {
      ConsoleEntryType.stderr => AppTheme.terminalError(context),
      ConsoleEntryType.system => entry.text.contains('[exit 0')
          ? AppTheme.terminalSuccess(context)
          : entry.text.contains('[timeout') || entry.text.contains('[stopped]')
              ? AppTheme.terminalWarning(context)
              : AppTheme.terminalPrompt(context),
      ConsoleEntryType.prompt => AppTheme.terminalPrompt(context),
      ConsoleEntryType.input => AppTheme.terminalInput(context),
      _ => AppTheme.terminalText(context),
    };
  }
}
