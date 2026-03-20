import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color accentBlue = Color(0xFF4C9BE8);
  static const Color accentGreen = Color(0xFF4EC9B0);
  static const Color accentYellow = Color(0xFFD7BA47);
  static const Color accentOrange = Color(0xFFCE9178);
  static const Color accentPurple = Color(0xFFC586C0);
  static const Color accentRed = Color(0xFFF44747);
  static const Color darkBg = Color(0xFF1E1E1E);
  static const Color darkSurface = Color(0xFF252526);
  static const Color darkPanel = Color(0xFF2D2D30);
  static const Color darkBorder = Color(0xFF3E3E42);
  static const Color darkText = Color(0xFFD4D4D4);
  static const Color darkTextSecondary = Color(0xFF9A9A9A);
  static const Color lightBg = Color(0xFFF4F6F8);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightPanel = Color(0xFFF7F9FC);
  static const Color lightBorder = Color(0xFFD7DEE7);
  static const Color lightText = Color(0xFF17212B);
  static const Color lightTextSecondary = Color(0xFF5D6B79);

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color editorBackground(BuildContext context) =>
      isDark(context) ? darkBg : lightSurface;

  static Color editorSurface(BuildContext context) =>
      isDark(context) ? darkSurface : lightPanel;

  static Color editorPanel(BuildContext context) =>
      isDark(context) ? darkPanel : lightPanel;

  static Color editorBorder(BuildContext context) =>
      isDark(context) ? darkBorder : lightBorder;

  static Color editorText(BuildContext context) =>
      isDark(context) ? darkText : lightText;

  static Color editorMutedText(BuildContext context) =>
      isDark(context) ? darkTextSecondary : lightTextSecondary;

  static Color cursorColor(BuildContext context) => accentBlue;
  static Color selectionColor(BuildContext context) => accentBlue.withOpacity(isDark(context) ? 0.35 : 0.22);

  static Color terminalBackground(BuildContext context) =>
      isDark(context) ? const Color(0xFF111318) : const Color(0xFFF8FAFD);

  static Color terminalSurface(BuildContext context) =>
      isDark(context) ? darkPanel : lightSurface;

  static Color terminalText(BuildContext context) => editorText(context);
  static Color terminalHint(BuildContext context) => editorMutedText(context);
  static Color terminalPrompt(BuildContext context) => isDark(context) ? accentBlue : const Color(0xFF0B63C9);
  static Color terminalInput(BuildContext context) => isDark(context) ? const Color(0xFF9CDCFE) : const Color(0xFF0F4C81);
  static Color terminalError(BuildContext context) => isDark(context) ? accentRed : const Color(0xFFB42318);
  static Color terminalSuccess(BuildContext context) => isDark(context) ? accentGreen : const Color(0xFF0C8A5F);
  static Color terminalWarning(BuildContext context) => isDark(context) ? accentYellow : const Color(0xFF9A6700);

  static Color syntaxKeyword(BuildContext context) => isDark(context) ? const Color(0xFFC586C0) : const Color(0xFF7C3AED);
  static Color syntaxString(BuildContext context) => isDark(context) ? const Color(0xFFCE9178) : const Color(0xFFB54708);
  static Color syntaxComment(BuildContext context) => isDark(context) ? const Color(0xFF6A9955) : const Color(0xFF4E7A27);
  static Color syntaxNumber(BuildContext context) => isDark(context) ? const Color(0xFFB5CEA8) : const Color(0xFF0F766E);
  static Color syntaxOperator(BuildContext context) => isDark(context) ? const Color(0xFFD4D4D4) : const Color(0xFF344054);
  static Color syntaxFunction(BuildContext context) => isDark(context) ? const Color(0xFFDCDCAA) : const Color(0xFF175CD3);
  static Color syntaxClass(BuildContext context) => isDark(context) ? const Color(0xFF4EC9B0) : const Color(0xFF047857);
  static Color syntaxVariable(BuildContext context) => isDark(context) ? const Color(0xFF9CDCFE) : const Color(0xFF0F4C81);
  static Color syntaxDecorator(BuildContext context) => isDark(context) ? const Color(0xFFFFC66D) : const Color(0xFF9E4A03);
  static Color syntaxBuiltin(BuildContext context) => isDark(context) ? const Color(0xFF569CD6) : const Color(0xFF1D4ED8);
  static Color syntaxModule(BuildContext context) => isDark(context) ? const Color(0xFF4FC1FF) : const Color(0xFF155EEF);

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: accentBlue,
      secondary: accentGreen,
      surface: darkSurface,
      background: darkBg,
      error: accentRed,
      onSurface: darkText,
    ),
    scaffoldBackgroundColor: darkBg,
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkSurface,
      foregroundColor: darkText,
      elevation: 0,
    ),
    cardTheme: const CardThemeData(color: darkPanel, elevation: 0),
    dividerColor: darkBorder,
    iconTheme: const IconThemeData(color: darkTextSecondary),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkPanel,
      hintStyle: const TextStyle(color: darkTextSecondary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: darkBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: darkBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: accentBlue)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkSurface,
      selectedItemColor: accentBlue,
      unselectedItemColor: darkTextSecondary,
    ),
  );

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: accentBlue,
      secondary: accentGreen,
      surface: lightSurface,
      background: lightBg,
      error: accentRed,
      onSurface: lightText,
    ),
    scaffoldBackgroundColor: lightBg,
    textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).apply(bodyColor: lightText, displayColor: lightText),
    appBarTheme: const AppBarTheme(
      backgroundColor: lightSurface,
      foregroundColor: lightText,
      elevation: 0,
    ),
    cardTheme: const CardThemeData(color: lightSurface, elevation: 0),
    dividerColor: lightBorder,
    iconTheme: const IconThemeData(color: lightTextSecondary),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightSurface,
      hintStyle: const TextStyle(color: lightTextSecondary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: lightBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: lightBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: accentBlue)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: lightSurface,
      selectedItemColor: accentBlue,
      unselectedItemColor: lightTextSecondary,
    ),
  );
}
