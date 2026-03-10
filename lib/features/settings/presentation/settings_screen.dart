import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_theme.dart';
import 'settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(children: [
        _SectionHeader('Appearance'),
        SwitchListTile(title: const Text('Dark Mode'), subtitle: const Text('Use dark theme'),
          value: settings.isDarkMode, onChanged: (_) => notifier.toggleDarkMode(),
          secondary: const Icon(Icons.dark_mode_outlined)),
        SwitchListTile(title: const Text('Line Numbers'), subtitle: const Text('Show line numbers in editor'),
          value: settings.showLineNumbers, onChanged: (v) => notifier.setShowLineNumbers(v),
          secondary: const Icon(Icons.format_list_numbered_outlined)),
        _SectionHeader('Editor'),
        ListTile(
          leading: const Icon(Icons.text_fields_outlined),
          title: const Text('Font Size'),
          subtitle: Text('${settings.fontSize.toInt()}px'),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(icon: const Icon(Icons.remove),
              onPressed: settings.fontSize > 10 ? () => notifier.setFontSize(settings.fontSize - 1) : null),
            Text('${settings.fontSize.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold)),
            IconButton(icon: const Icon(Icons.add),
              onPressed: settings.fontSize < 24 ? () => notifier.setFontSize(settings.fontSize + 1) : null),
          ]),
        ),
        ListTile(
          leading: const Icon(Icons.space_bar_outlined),
          title: const Text('Tab Width'),
          subtitle: Text('${settings.tabWidth} spaces'),
          trailing: DropdownButton<int>(
            value: settings.tabWidth,
            items: [2, 4, 8].map((v) => DropdownMenuItem(value: v, child: Text('$v spaces'))).toList(),
            onChanged: (v) { if (v != null) notifier.setTabWidth(v); },
          ),
        ),
        SwitchListTile(title: const Text('Word Wrap'), subtitle: const Text('Wrap long lines'),
          value: settings.wordWrap, onChanged: (v) => notifier.setWordWrap(v),
          secondary: const Icon(Icons.wrap_text_outlined)),
        _SectionHeader('Execution'),
        ListTile(
          leading: const Icon(Icons.timer_outlined),
          title: const Text('Execution Timeout'),
          subtitle: Text('${settings.executionTimeoutSeconds} seconds'),
          trailing: DropdownButton<int>(
            value: settings.executionTimeoutSeconds,
            items: [5, 10, 15, 30, 60].map((v) => DropdownMenuItem(value: v, child: Text('${v}s'))).toList(),
            onChanged: (v) { if (v != null) notifier.setExecutionTimeout(v); },
          ),
        ),
        _SectionHeader('About'),
        ListTile(
          leading: Container(width: 36, height: 36,
            decoration: BoxDecoration(color: AppTheme.accentBlue, borderRadius: BorderRadius.circular(8)),
            child: const Center(child: Text('Py', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)))),
          title: const Text('PyDroid'),
          subtitle: const Text('Version 1.0.0 · Python IDE for Android'),
        ),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('PyDroid embeds Python 3.11 runtime using Chaquopy.\nCode runs locally on your device, no internet required.',
            style: TextStyle(fontSize: 12, color: AppTheme.darkTextSecondary)),
        ),
      ]),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.accentBlue, letterSpacing: 1.2)),
    );
  }
}
