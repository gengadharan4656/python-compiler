import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../settings/presentation/settings_provider.dart';
import '../editor_provider.dart';

class CodeEditorWidget extends ConsumerStatefulWidget {
  const CodeEditorWidget({super.key});
  @override
  ConsumerState<CodeEditorWidget> createState() => _CodeEditorWidgetState();
}

class _CodeEditorWidgetState extends ConsumerState<CodeEditorWidget> {
  late TextEditingController _controller;
  late ScrollController _scrollController;
  late FocusNode _focusNode;
  final FocusNode _keyboardFocusNode = FocusNode();
  String _lastFile = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _scrollController = ScrollController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    final fileName = ref.read(currentFileProvider);
    ref.read(editorContentProvider.notifier).setContent(fileName, value);
    ref.read(unsavedFilesProvider.notifier).markDirty(fileName);
  }

  void _handleTab() {
    final settings = ref.read(settingsProvider);
    final spaces = ' ' * settings.tabWidth;
    final sel = _controller.selection;
    final text = _controller.text;
    final newText = text.replaceRange(sel.start, sel.end, spaces);
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: sel.start + spaces.length),
    );
    _onChanged(newText);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final fileName = ref.watch(currentFileProvider);

    if (fileName != _lastFile) {
      _lastFile = fileName;
      final content = ref.read(editorContentProvider.notifier).getContent(fileName);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.text = content;
      });
    }

    return Container(
      color: AppTheme.darkBg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (settings.showLineNumbers)
            _LineNumbers(
              controller: _controller,
              scrollController: _scrollController,
              fontSize: settings.fontSize,
            ),
          Expanded(
            child: KeyboardListener(
              focusNode: _keyboardFocusNode,
              onKeyEvent: (event) {
                if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.tab) {
                  _handleTab();
                }
              },
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: _onChanged,
                maxLines: null,
                expands: true,
                scrollController: _scrollController,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: settings.fontSize,
                  color: AppTheme.darkText,
                  height: 1.5,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(12),
                  filled: false,
                ),
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                autocorrect: false,
                enableSuggestions: false,
                smartQuotesType: SmartQuotesType.disabled,
                smartDashesType: SmartDashesType.disabled,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineNumbers extends StatefulWidget {
  final TextEditingController controller;
  final ScrollController scrollController;
  final double fontSize;

  const _LineNumbers({
    required this.controller,
    required this.scrollController,
    required this.fontSize,
  });

  @override
  State<_LineNumbers> createState() => _LineNumbersState();
}

class _LineNumbersState extends State<_LineNumbers> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_update);
  }

  void _update() => setState(() {});

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lines = '\n'.allMatches(widget.controller.text).length + 1;

    return Container(
      width: 52,
      color: AppTheme.darkSurface,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: widget.scrollController,
          builder: (context, child) {
            final offset = widget.scrollController.hasClients
                ? widget.scrollController.offset
                : 0.0;

            return Transform.translate(
              offset: Offset(0, -offset),
              child: child,
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(top: 12, right: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(
                lines,
                (i) => SizedBox(
                  height: widget.fontSize * 1.5,
                  child: Text(
                    '${i + 1}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: widget.fontSize,
                      color: AppTheme.darkTextSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
