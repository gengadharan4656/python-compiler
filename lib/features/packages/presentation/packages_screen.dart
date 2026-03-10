import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../projects/data/repositories/project_repository.dart';
import '../../projects/presentation/project_provider.dart';
import '../data/package_catalog.dart';

class PackagesScreen extends ConsumerStatefulWidget {
  const PackagesScreen({super.key});

  @override
  ConsumerState<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends ConsumerState<PackagesScreen> {
  String _search = '';
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(currentProjectProvider);
    final enabledPackages = project?.enabledPackages ?? <String>[];

    final filtered = PackageCatalog.packages.where((p) {
      final matchSearch =
          _search.isEmpty ||
              p.name.toLowerCase().contains(_search.toLowerCase()) ||
              p.description.toLowerCase().contains(_search.toLowerCase());

      final matchCategory =
          _selectedCategory == null || p.category == _selectedCategory;

      return matchSearch && matchCategory;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Package Library'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              onChanged: (value) => setState(() => _search = value),
              decoration: InputDecoration(
                hintText: 'Search packages...',
                prefixIcon: const Icon(Icons.search, size: 18),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                isDense: true,
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  onPressed: () => setState(() => _search = ''),
                )
                    : null,
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _CategoryChip(
                  label: 'All',
                  selected: _selectedCategory == null,
                  onTap: () => setState(() => _selectedCategory = null),
                ),
                ...PackageCatalog.categories.map(
                      (category) => _CategoryChip(
                    label: category,
                    selected: _selectedCategory == category,
                    onTap: () => setState(() => _selectedCategory = category),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) =>
              const Divider(height: 1, indent: 16),
              itemBuilder: (_, index) {
                final pkg = filtered[index];
                final enabled = enabledPackages.contains(pkg.name);

                return _PackageTile(
                  pkg: pkg,
                  enabled: enabled,
                  projectSelected: project != null,
                  onToggle: project == null
                      ? null
                      : () => _togglePackage(
                    ref,
                    project.id,
                    pkg.name,
                    enabled,
                    project.enabledPackages,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _togglePackage(
      WidgetRef ref,
      String projectId,
      String packageName,
      bool currentlyEnabled,
      List<String> currentPackages,
      ) async {
    final repo = ref.read(projectRepositoryProvider);
    final project = repo.getProject(projectId);
    if (project == null) return;

    final updated = currentlyEnabled
        ? (List<String>.from(currentPackages)..remove(packageName))
        : (List<String>.from(currentPackages)..add(packageName));

    final updatedProject = project.copyWith(enabledPackages: updated);

    await repo.saveProject(updatedProject);
    ref.read(currentProjectProvider.notifier).updateProject(updatedProject);
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accentBlue : AppTheme.darkPanel,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppTheme.darkTextSecondary,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _PackageTile extends StatelessWidget {
  final PackageInfo pkg;
  final bool enabled;
  final bool projectSelected;
  final VoidCallback? onToggle;

  const _PackageTile({
    required this.pkg,
    required this.enabled,
    required this.projectSelected,
    this.onToggle,
  });

  Color _catColor(String category) {
    switch (category) {
      case 'Data Science':
        return AppTheme.accentBlue;
      case 'Network':
        return AppTheme.accentGreen;
      case 'Image':
        return AppTheme.accentPurple;
      case 'Mathematics':
        return AppTheme.accentYellow;
      default:
        return AppTheme.accentOrange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _catColor(pkg.category);

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            pkg.name[0].toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      title: Row(
        children: [
          Text(
            pkg.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.darkPanel,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'v${pkg.version}',
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.darkTextSecondary,
              ),
            ),
          ),
          if (pkg.isNative) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.accentGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'native',
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.accentGreen,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(
            pkg.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            '${pkg.sizeMB} MB · ${pkg.category}',
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.darkTextSecondary,
            ),
          ),
        ],
      ),
      isThreeLine: true,
      trailing: projectSelected
          ? Switch(
        value: enabled,
        onChanged: onToggle == null ? null : (_) => onToggle!(),
        activeColor: AppTheme.accentBlue,
      )
          : null,
    );
  }
}