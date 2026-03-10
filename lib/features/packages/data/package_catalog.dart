class PackageInfo {
  final String name;
  final String version;
  final String description;
  final String category;
  final String sizeMB;
  final bool isNative;

  const PackageInfo({required this.name, required this.version, required this.description,
    required this.category, required this.sizeMB, this.isNative = false});
}

class PackageCatalog {
  static const List<PackageInfo> packages = [
    PackageInfo(name: 'requests', version: '2.31.0', description: 'Elegant HTTP library for making web requests', category: 'Network', sizeMB: '0.2'),
    PackageInfo(name: 'urllib3', version: '2.1.0', description: 'HTTP client for Python, used by requests', category: 'Network', sizeMB: '0.3'),
    PackageInfo(name: 'numpy', version: '1.24.0', description: 'Fundamental package for numerical computing', category: 'Data Science', sizeMB: '3.5', isNative: true),
    PackageInfo(name: 'pandas', version: '2.0.0', description: 'Data analysis and manipulation library', category: 'Data Science', sizeMB: '4.1', isNative: true),
    PackageInfo(name: 'sympy', version: '1.12', description: 'Symbolic mathematics in Python', category: 'Mathematics', sizeMB: '2.1'),
    PackageInfo(name: 'pillow', version: '10.0.0', description: 'Python Imaging Library — image processing', category: 'Image', sizeMB: '2.8', isNative: true),
    PackageInfo(name: 'python-dateutil', version: '2.8.2', description: 'Extensions to the standard Python datetime module', category: 'Utilities', sizeMB: '0.2'),
    PackageInfo(name: 'rich', version: '13.5.0', description: 'Rich text and beautiful formatting in the terminal', category: 'Utilities', sizeMB: '0.5'),
    PackageInfo(name: 'faker', version: '20.0.0', description: 'Generate fake data for testing and development', category: 'Utilities', sizeMB: '0.8'),
    PackageInfo(name: 'colorama', version: '0.4.6', description: 'Cross-platform colored terminal text', category: 'Utilities', sizeMB: '0.1'),
    PackageInfo(name: 'pydantic', version: '2.5.0', description: 'Data validation using Python type annotations', category: 'Utilities', sizeMB: '0.6'),
  ];

  static List<String> get categories => packages.map((p) => p.category).toSet().toList()..sort();
}
