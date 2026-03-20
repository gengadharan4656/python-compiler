import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_theme.dart';

class PythonSyntaxTextController extends TextEditingController {
  PythonSyntaxTextController({required this.context, super.text});

  BuildContext context;

  static const Set<String> _keywords = {
    'False', 'None', 'True', 'and', 'as', 'assert', 'async', 'await', 'break',
    'class', 'continue', 'def', 'del', 'elif', 'else', 'except', 'finally',
    'for', 'from', 'global', 'if', 'import', 'in', 'is', 'lambda', 'nonlocal',
    'not', 'or', 'pass', 'raise', 'return', 'try', 'while', 'with', 'yield',
    'match', 'case'
  };

  static const Set<String> _builtins = {
    'abs', 'all', 'any', 'bool', 'dict', 'enumerate', 'filter', 'float', 'input',
    'int', 'len', 'list', 'map', 'max', 'min', 'open', 'print', 'range', 'repr',
    'reversed', 'round', 'set', 'sorted', 'str', 'sum', 'tuple', 'type', 'zip'
  };

  static const Set<String> _operatorChars = {
    '+', '-', '*', '/', '%', '=', '!', '<', '>', '&', '|', '^', '~', ':', '.'
  };

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    this.context = context;
    final baseStyle = GoogleFonts.jetBrainsMono(
      fontSize: style?.fontSize,
      color: AppTheme.editorText(context),
      height: style?.height,
    );
    final spans = <TextSpan>[];
    final source = text;
    var index = 0;
    String? previousIdentifier;

    while (index < source.length) {
      final char = source[index];

      if (char == '#') {
        final end = _lineEnd(source, index);
        spans.add(_span(source.substring(index, end), AppTheme.syntaxComment(context), baseStyle));
        index = end;
        continue;
      }

      if (_isStringStart(source, index)) {
        final end = _consumeString(source, index);
        spans.add(_span(source.substring(index, end), AppTheme.syntaxString(context), baseStyle));
        index = end;
        continue;
      }

      if (_isNumberStart(source, index)) {
        final end = _consumeNumber(source, index);
        spans.add(_span(source.substring(index, end), AppTheme.syntaxNumber(context), baseStyle));
        index = end;
        continue;
      }

      if (char == '@') {
        final end = _consumeDecorator(source, index);
        spans.add(_span(source.substring(index, end), AppTheme.syntaxDecorator(context), baseStyle));
        index = end;
        continue;
      }

      if (_isIdentifierStart(char)) {
        final end = _consumeIdentifier(source, index);
        final token = source.substring(index, end);
        final color = _resolveIdentifierColor(source, index, end, token, previousIdentifier);
        spans.add(_span(token, color, baseStyle));
        previousIdentifier = token;
        index = end;
        continue;
      }

      if (_operatorChars.contains(char)) {
        final end = _consumeOperator(source, index);
        spans.add(_span(source.substring(index, end), AppTheme.syntaxOperator(context), baseStyle));
        index = end;
        continue;
      }

      spans.add(TextSpan(text: char, style: baseStyle));
      if (!RegExp(r'\s').hasMatch(char)) previousIdentifier = null;
      index += 1;
    }

    return TextSpan(style: baseStyle, children: spans);
  }

  TextSpan _span(String text, Color color, TextStyle baseStyle) => TextSpan(
        text: text,
        style: baseStyle.copyWith(color: color),
      );

  Color _resolveIdentifierColor(String source, int start, int end, String token, String? previousIdentifier) {
    if (_keywords.contains(token)) return AppTheme.syntaxKeyword(context);
    if (_builtins.contains(token)) return AppTheme.syntaxBuiltin(context);

    final previousWord = _previousWord(source, start);
    if (previousWord == 'def') return AppTheme.syntaxFunction(context);
    if (previousWord == 'class') return AppTheme.syntaxClass(context);
    if (previousWord == 'import' || previousWord == 'from') return AppTheme.syntaxModule(context);
    if (_looksLikeNamedArgument(source, start, end) || _looksLikeAssignment(source, start, end) || _looksLikeParameter(source, start, end, previousIdentifier)) {
      return AppTheme.syntaxVariable(context);
    }
    return AppTheme.editorText(context);
  }

  bool _looksLikeAssignment(String source, int start, int end) {
    final next = _nextNonWhitespaceIndex(source, end);
    if (next == null || source[next] != '=') return false;
    if (next + 1 < source.length && source[next + 1] == '=') return false;
    return true;
  }

  bool _looksLikeNamedArgument(String source, int start, int end) {
    final prev = _previousNonWhitespaceIndex(source, start - 1);
    final next = _nextNonWhitespaceIndex(source, end);
    if (next == null || source[next] != '=') return false;
    if (prev == null) return false;
    return source[prev] == '(' || source[prev] == ',';
  }

  bool _looksLikeParameter(String source, int start, int end, String? previousIdentifier) {
    final prev = _previousNonWhitespaceIndex(source, start - 1);
    if (prev == null) return false;
    final prevChar = source[prev];
    if (prevChar != '(' && prevChar != ',') return false;
    final previousWord = _previousWord(source, start);
    return previousWord == 'def' || previousIdentifier != null;
  }

  String? _previousWord(String source, int start) {
    var cursor = start - 1;
    while (cursor >= 0 && RegExp(r'\s').hasMatch(source[cursor])) {
      cursor -= 1;
    }
    if (cursor < 0 || !_isIdentifierChar(source[cursor])) return null;
    final end = cursor + 1;
    while (cursor >= 0 && _isIdentifierChar(source[cursor])) {
      cursor -= 1;
    }
    return source.substring(cursor + 1, end);
  }

  int _lineEnd(String source, int start) {
    final nextBreak = source.indexOf('\n', start);
    return nextBreak == -1 ? source.length : nextBreak;
  }

  bool _isStringStart(String source, int index) {
    final char = source[index];
    if (char == '\'' || char == '"') return true;
    if (index + 1 >= source.length) return false;
    final lower = source[index].toLowerCase();
    return 'rbfu'.contains(lower) && (source[index + 1] == '\'' || source[index + 1] == '"');
  }

  int _consumeString(String source, int start) {
    var index = start;
    if ('rbfuRBFU'.contains(source[index]) && index + 1 < source.length && (source[index + 1] == '\'' || source[index + 1] == '"')) {
      index += 1;
    }
    final quote = source[index];
    final triple = index + 2 < source.length && source[index + 1] == quote && source[index + 2] == quote;
    index += triple ? 3 : 1;
    while (index < source.length) {
      if (!triple && source[index] == '\\') {
        index += 2;
        continue;
      }
      if (triple) {
        if (index + 2 < source.length && source[index] == quote && source[index + 1] == quote && source[index + 2] == quote) {
          return index + 3;
        }
        index += 1;
      } else {
        if (source[index] == quote) return index + 1;
        index += 1;
      }
    }
    return source.length;
  }

  bool _isNumberStart(String source, int index) {
    final char = source[index];
    if (RegExp(r'[0-9]').hasMatch(char)) return true;
    return char == '.' && index + 1 < source.length && RegExp(r'[0-9]').hasMatch(source[index + 1]);
  }

  int _consumeNumber(String source, int start) {
    var index = start;
    while (index < source.length && RegExp(r'[0-9a-fA-FxXoObB_\.]').hasMatch(source[index])) {
      index += 1;
    }
    return index;
  }

  int _consumeDecorator(String source, int start) {
    var index = start + 1;
    while (index < source.length && RegExp(r'[A-Za-z0-9_\.]').hasMatch(source[index])) {
      index += 1;
    }
    return index;
  }

  int _consumeIdentifier(String source, int start) {
    var index = start + 1;
    while (index < source.length && _isIdentifierChar(source[index])) {
      index += 1;
    }
    return index;
  }

  int _consumeOperator(String source, int start) {
    var index = start + 1;
    while (index < source.length && _operatorChars.contains(source[index])) {
      index += 1;
    }
    return index;
  }

  int? _nextNonWhitespaceIndex(String source, int start) {
    var index = start;
    while (index < source.length && RegExp(r'\s').hasMatch(source[index])) {
      index += 1;
    }
    return index < source.length ? index : null;
  }

  int? _previousNonWhitespaceIndex(String source, int start) {
    var index = start;
    while (index >= 0 && RegExp(r'\s').hasMatch(source[index])) {
      index -= 1;
    }
    return index >= 0 ? index : null;
  }

  bool _isIdentifierStart(String char) => RegExp(r'[A-Za-z_]').hasMatch(char);
  bool _isIdentifierChar(String char) => RegExp(r'[A-Za-z0-9_]').hasMatch(char);
}
