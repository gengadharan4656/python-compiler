import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/routes.dart';
import '../../../app/theme/app_theme.dart';
import '../../projects/presentation/project_provider.dart';
import '../data/template_data.dart';

class TemplatesScreen extends ConsumerWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: TemplateData.categories.length + 1,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Templates'),
          bottom: TabBar(
            isScrollable: true,
            tabs: [const Tab(text: 'All'), ...TemplateData.categories.map((c) => Tab(text: c))],
          ),
        ),
        body: TabBarView(children: [
          _TemplateGrid(templates: TemplateData.templates, onSelect: (t) => _useTemplate(context, ref, t)),
          ...TemplateData.categories.map((c) => _TemplateGrid(
            templates: TemplateData.templates.where((t) => t.category == c).toList(),
            onSelect: (t) => _useTemplate(context, ref, t),
          )),
        ]),
      ),
    );
  }

  Future<void> _useTemplate(BuildContext context, WidgetRef ref, TemplateItem template) async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Use "${template.name}"'),
        content: const Text('Create a new project with this template?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, template.name), child: const Text('Create Project')),
        ],
      ),
    );
    if (result != null && context.mounted) {
      final project = await ref.read(projectsProvider.notifier).createProject(name: result, initialCode: template.code);
      ref.read(currentProjectProvider.notifier).setProject(project);
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.editor, (route) => route.settings.name == AppRoutes.home);
      }
    }
  }
}

class _TemplateGrid extends StatelessWidget {
  final List<TemplateItem> templates;
  final void Function(TemplateItem) onSelect;
  const _TemplateGrid({required this.templates, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.3),
      itemCount: templates.length,
      itemBuilder: (_, i) => _TemplateCard(template: templates[i], onTap: () => onSelect(templates[i])),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final TemplateItem template;
  final VoidCallback onTap;
  const _TemplateCard({required this.template, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.darkBorder)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(template.icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text(template.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(template.description, style: const TextStyle(fontSize: 11, color: AppTheme.darkTextSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AppTheme.accentBlue.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
            child: Text(template.category, style: const TextStyle(fontSize: 10, color: AppTheme.accentBlue)),
          ),
        ]),
      ),
    );
  }
}
