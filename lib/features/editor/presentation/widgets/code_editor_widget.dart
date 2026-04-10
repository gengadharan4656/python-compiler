import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../../../../app/theme/app_theme.dart';
import '../../../settings/presentation/settings_provider.dart';
import '../editor_provider.dart';
import 'python_syntax_highlighter.dart';

class CodeEditorWidget extends ConsumerStatefulWidget {
  const CodeEditorWidget({super.key});
  @override
  ConsumerState<CodeEditorWidget> createState() => _CodeEditorWidgetState();
}

class _CodeEditorWidgetState extends ConsumerState<CodeEditorWidget> {
  late PythonSyntaxTextController _controller;
  late ScrollController _scrollController;
  late FocusNode _focusNode;
  final FocusNode _keyboardFocusNode = FocusNode();
  String _lastFile = '';

  @override
  void initState() {
    super.initState();
    _controller = PythonSyntaxTextController(context: context);
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

  void _replaceSelection(String replacement, {int caretOffset = 0}) {
    final sel = _controller.selection;
    if (sel.start < 0 || sel.end < 0) return;
    final text = _controller.text;
    final newText = text.replaceRange(sel.start, sel.end, replacement);
    final caret = (sel.start + replacement.length + caretOffset).clamp(0, newText.length);
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: caret),
    );
    _onChanged(newText);
    _focusNode.requestFocus();
  }

  void _handleTab() {
    final settings = ref.read(settingsProvider);
    _replaceSelection(' ' * settings.tabWidth);
  }

  Future<void> _copySelection() async {
    final sel = _controller.selection;
    if (!sel.isValid || sel.isCollapsed) {
      await Clipboard.setData(ClipboardData(text: _controller.text));
      return;
    }
    await Clipboard.setData(ClipboardData(text: sel.textInside(_controller.text)));
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) return;
    _replaceSelection(text);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final fileName = ref.watch(currentFileProvider);
    _controller.context = context;

    if (fileName != _lastFile) {
      _lastFile = fileName;
      final content = ref.read(editorContentProvider.notifier).getContent(fileName);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.value = TextEditingValue(
          text: content,
          selection: TextSelection.collapsed(offset: content.length),
        );
      });
    }

    final editorStyle = GoogleFonts.jetBrainsMono(
      fontSize: settings.fontSize,
      color: AppTheme.editorText(context),
      height: 1.4,
    );

    return Container(
      color: AppTheme.editorBackground(context),
      child: Column(
        children: [
          Expanded(
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
                      style: editorStyle,
                      strutStyle: StrutStyle.fromTextStyle(editorStyle, forceStrutHeight: true),
                      cursorColor: AppTheme.cursorColor(context),
                      selectionControls: materialTextSelectionHandleControls,
                      selectionHeightStyle: BoxHeightStyle.tight,
                      selectionWidthStyle: BoxWidthStyle.tight,
                      decoration: const InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        filled: false,
                      ),
                      inputFormatters: const [_AutoPairFormatter()],
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
          ),
          _EditorShortcutBar(
            onCopy: _copySelection,
            onPaste: _pasteFromClipboard,
            onInsert: (text) => _replaceSelection(text),
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
    final digits = lines.toString().length;

    return Container(
      width: 20 + (digits * widget.fontSize * 0.72),
      padding: const EdgeInsets.only(right: 6),
      color: AppTheme.editorSurface(context),
      child: ClipRect(
        child: AnimatedBuilder(
          animation: widget.scrollController,
          builder: (context, child) {
            final offset = widget.scrollController.hasClients ? widget.scrollController.offset : 0.0;
            return Transform.translate(offset: Offset(0, -offset), child: child);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(
              lines,
              (i) => SizedBox(
                height: widget.fontSize * 1.4,
                child: Text(
                  '${i + 1}',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: widget.fontSize,
                    color: AppTheme.editorMutedText(context),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EditorShortcutBar extends StatelessWidget {
  final Future<void> Function() onCopy;
  final Future<void> Function() onPaste;
  final ValueChanged<String> onInsert;

  const _EditorShortcutBar({
    required this.onCopy,
    required this.onPaste,
    required this.onInsert,
  });

  @override
  Widget build(BuildContext context) {
    final symbols = ['()', '{}', '[]', '""', "''", ':', ';', '=', '+', '-', '*', '/'];
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppTheme.editorSurface(context),
        border: Border(top: BorderSide(color: AppTheme.editorBorder(context))),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        children: [
          IconButton(
            tooltip: 'Copy',
            icon: const Icon(Icons.content_copy_outlined, size: 18),
            onPressed: onCopy,
          ),
          IconButton(
            tooltip: 'Paste',
            icon: const Icon(Icons.content_paste_outlined, size: 18),
            onPressed: onPaste,
          ),
          ...symbols.map(
            (symbol) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              child: OutlinedButton(
                onPressed: () => onInsert(symbol),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(38, 24),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(symbol),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AutoPairFormatter extends TextInputFormatter {
  const _AutoPairFormatter();

  static const Map<String, String> _pairs = {
    '(': ')',
    '{': '}',
    '[': ']',
    '"': '"',
    "'": "'",
  };

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final selection = newValue.selection;
    if (!selection.isCollapsed || !oldValue.selection.isCollapsed) return newValue;

    final insertedLength = newValue.text.length - oldValue.text.length;
    if (insertedLength != 1) return newValue;

    final caret = selection.baseOffset;
    if (caret <= 0 || caret > newValue.text.length) return newValue;

    final inserted = newValue.text.substring(caret - 1, caret);
    final closing = _pairs[inserted];
    if (closing == null) return newValue;

    final updated = newValue.text.replaceRange(caret, caret, closing);
    return newValue.copyWith(
      text: updated,
      selection: TextSelection.collapsed(offset: caret),
      composing: TextRange.empty,
    );
  }
}
