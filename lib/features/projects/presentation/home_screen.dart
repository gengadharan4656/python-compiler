import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/routes.dart';
import '../../../app/theme/app_theme.dart';
import '../data/models/project_model.dart';
import 'project_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(width: 28, height: 28,
            decoration: BoxDecoration(color: AppTheme.accentBlue, borderRadius: BorderRadius.circular(6)),
            child: const Center(child: Text('Py', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)))),
          const SizedBox(width: 8),
          const Text('PyDroid', style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: _ActionCard(icon: Icons.add, label: 'New Project',
                color: AppTheme.accentBlue, onTap: () => _showNewProjectDialog(context, ref))),
              const SizedBox(width: 12),
              Expanded(child: _ActionCard(icon: Icons.dashboard_outlined, label: 'Templates',
                color: AppTheme.accentGreen, onTap: () => Navigator.pushNamed(context, AppRoutes.templates))),
            ]),
            const SizedBox(height: 24),
            Text('Recent Projects', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (projects.isEmpty)
              _EmptyState(onCreateNew: () => _showNewProjectDialog(context, ref))
            else
              ...projects.take(10).map((p) => _ProjectTile(
                project: p,
                onTap: () => _openProject(context, ref, p),
                onDelete: () => _deleteProject(context, ref, p),
              )),
          ],
        ),
      ),
    );
  }

  void _openProject(BuildContext context, WidgetRef ref, ProjectModel project) {
    ref.read(currentProjectProvider.notifier).setProject(project);
    Navigator.pushNamed(context, AppRoutes.editor);
  }

  Future<void> _showNewProjectDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: 'My Project');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Project'),
        content: TextField(controller: controller, autofocus: true,
          decoration: const InputDecoration(labelText: 'Project name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Create')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      final project = await ref.read(projectsProvider.notifier).createProject(name: result);
      if (context.mounted) _openProject(context, ref, project);
    }
  }

  Future<void> _deleteProject(BuildContext context, WidgetRef ref, ProjectModel project) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text('Delete "${project.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRed),
            onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true) await ref.read(projectsProvider.notifier).deleteProject(project.id);
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3))),
        child: Row(children: [
          Icon(icon, color: color, size: 22), const SizedBox(width: 10),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _ProjectTile extends StatelessWidget {
  final ProjectModel project;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ProjectTile({required this.project, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(width: 42, height: 42,
              decoration: BoxDecoration(color: AppTheme.accentBlue.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.code, color: AppTheme.accentBlue, size: 20)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(project.name, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('Updated ${DateFormat.MMMd().format(project.updatedAt)} · ${project.files.length} file(s)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.darkTextSecondary)),
            ])),
            PopupMenuButton<String>(
              onSelected: (v) { if (v == 'delete') onDelete(); },
              itemBuilder: (_) => const [PopupMenuItem(value: 'delete', child: Text('Delete'))],
            ),
          ]),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreateNew;
  const _EmptyState({required this.onCreateNew});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(children: [
          Icon(Icons.folder_open_outlined, size: 64, color: AppTheme.darkTextSecondary.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text('No projects yet', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.darkTextSecondary)),
          const SizedBox(height: 8),
          Text('Create a new project to start coding', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.darkTextSecondary)),
          const SizedBox(height: 24),
          ElevatedButton.icon(onPressed: onCreateNew, icon: const Icon(Icons.add), label: const Text('New Project')),
        ]),
      ),
    );
  }
}
