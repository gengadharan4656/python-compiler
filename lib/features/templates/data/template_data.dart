class TemplateItem {
  final String id;
  final String name;
  final String description;
  final String category;
  final String icon;
  final String code;
  const TemplateItem({required this.id, required this.name, required this.description, required this.category, required this.icon, required this.code});
}

class TemplateData {
  static const List<TemplateItem> templates = [
    TemplateItem(id: 'hello_world', name: 'Hello World', description: 'The classic first program', category: 'Basics', icon: '👋',
      code: '# Hello World\nprint("Hello, World!")\nprint("Welcome to PyDroid!")\n'),
    TemplateItem(id: 'variables', name: 'Variables & Types', description: 'Explore Python data types', category: 'Basics', icon: '📦',
      code: '# Variables and Data Types\nname = "PyDroid"\nversion = 1.0\nis_awesome = True\nitems = [1, 2, 3, 4, 5]\nprint(f"App: {name}")\nprint(f"Version: {version}")\nprint(f"Awesome: {is_awesome}")\nprint(f"Items: {items}")\nprint(f"Type of name: {type(name)}")\n'),
    TemplateItem(id: 'calculator', name: 'Calculator', description: 'Simple arithmetic operations', category: 'Basics', icon: '🔢',
      code: '# Simple Calculator\ndef add(a, b): return a + b\ndef subtract(a, b): return a - b\ndef multiply(a, b): return a * b\ndef divide(a, b):\n    if b == 0: return "Error: Division by zero"\n    return a / b\n\na, b = 10, 3\nprint(f"{a} + {b} = {add(a, b)}")\nprint(f"{a} - {b} = {subtract(a, b)}")\nprint(f"{a} * {b} = {multiply(a, b)}")\nprint(f"{a} / {b} = {divide(a, b):.2f}")\n'),
    TemplateItem(id: 'loops', name: 'Loops', description: 'For and while loop examples', category: 'Basics', icon: '🔄',
      code: '# Loop Examples\nprint("For loop:")\nfor i in range(1, 6):\n    print(f"  {i}")\n\nprint("\\nWhile countdown:")\nn = 5\nwhile n > 0:\n    print(f"  {n}...")\n    n -= 1\nprint("  Go!")\n\nsquares = [x**2 for x in range(1, 6)]\nprint(f"\\nSquares: {squares}")\n'),
    TemplateItem(id: 'functions', name: 'Functions', description: 'Define and use functions', category: 'Basics', icon: '⚡',
      code: '# Functions in Python\ndef greet(name, greeting="Hello"):\n    return f"{greeting}, {name}!"\n\ndef factorial(n):\n    if n <= 1: return 1\n    return n * factorial(n - 1)\n\ndef fibonacci(n):\n    a, b = 0, 1\n    result = []\n    for _ in range(n):\n        result.append(a)\n        a, b = b, a + b\n    return result\n\nprint(greet("World"))\nprint(greet("PyDroid", "Welcome to"))\nprint(f"5! = {factorial(5)}")\nprint(f"Fibonacci(10): {fibonacci(10)}")\n'),
    TemplateItem(id: 'oop', name: 'OOP Example', description: 'Classes and objects', category: 'OOP', icon: '🧱',
      code: '# Object-Oriented Programming\nclass Animal:\n    def __init__(self, name, sound):\n        self.name = name\n        self.sound = sound\n    def speak(self):\n        return f"{self.name} says {self.sound}!"\n    def __repr__(self):\n        return f"Animal({self.name!r})"\n\nclass Dog(Animal):\n    def __init__(self, name):\n        super().__init__(name, "Woof")\n    def fetch(self, item):\n        return f"{self.name} fetches the {item}!"\n\ndog = Dog("Buddy")\ncat = Animal("Whiskers", "Meow")\nprint(dog.speak())\nprint(cat.speak())\nprint(dog.fetch("ball"))\n'),
    TemplateItem(id: 'file_handling', name: 'File Handling', description: 'Read and write files', category: 'Files', icon: '📁',
      code: '# File Handling\nimport os\n\nfilename = "test.txt"\nwith open(filename, "w") as f:\n    f.write("Hello from PyDroid!\\n")\n    f.write("This is line 2.\\n")\n    f.write("File handling is easy!\\n")\nprint(f"Written to {filename}")\n\nwith open(filename, "r") as f:\n    content = f.read()\nprint(f"\\nContent:\\n{content}")\n\nos.remove(filename)\nprint(f"Deleted {filename}")\n'),
    TemplateItem(id: 'data_structures', name: 'Data Structures', description: 'Lists, dicts, sets, tuples', category: 'Data', icon: '🗃️',
      code: '# Python Data Structures\nfruits = ["apple", "banana", "cherry"]\nfruits.append("date")\nprint(f"List: {fruits}")\n\nperson = {"name": "Alice", "age": 30}\nperson["job"] = "Developer"\nprint(f"Dict: {person}")\n\nunique_nums = {1, 2, 3, 2, 1, 4}\nprint(f"Set: {unique_nums}")\n\ncoordinates = (10.5, 20.3)\nlat, lon = coordinates\nprint(f"Tuple: lat={lat}, lon={lon}")\n\nsquares = {x: x**2 for x in range(1, 6)}\nprint(f"Squares dict: {squares}")\n'),
    TemplateItem(id: 'error_handling', name: 'Error Handling', description: 'Try/except and exceptions', category: 'Basics', icon: '🛡️',
      code: '# Error Handling\ndef safe_divide(a, b):\n    try:\n        result = a / b\n        return result\n    except ZeroDivisionError:\n        print("Cannot divide by zero!")\n        return None\n    finally:\n        print("Division attempted.")\n\nprint(safe_divide(10, 2))\nprint(safe_divide(10, 0))\n\nclass ValidationError(Exception):\n    pass\n\ndef validate_age(age):\n    if age < 0 or age > 150:\n        raise ValidationError(f"Invalid age: {age}")\n    return True\n\ntry:\n    validate_age(25)\n    print("\\nAge 25 is valid")\n    validate_age(-5)\nexcept ValidationError as e:\n    print(f"Validation failed: {e}")\n'),
    TemplateItem(id: 'algorithms', name: 'Sorting Algorithms', description: 'Bubble, selection, merge sort', category: 'Algorithms', icon: '🔢',
      code: '# Sorting Algorithms\ndef bubble_sort(arr):\n    arr = arr.copy()\n    n = len(arr)\n    for i in range(n):\n        for j in range(0, n-i-1):\n            if arr[j] > arr[j+1]: arr[j], arr[j+1] = arr[j+1], arr[j]\n    return arr\n\ndef merge_sort(arr):\n    if len(arr) <= 1: return arr\n    mid = len(arr) // 2\n    left = merge_sort(arr[:mid])\n    right = merge_sort(arr[mid:])\n    result, i, j = [], 0, 0\n    while i < len(left) and j < len(right):\n        if left[i] <= right[j]: result.append(left[i]); i += 1\n        else: result.append(right[j]); j += 1\n    return result + left[i:] + right[j:]\n\ndata = [64, 34, 25, 12, 22, 11, 90]\nprint(f"Original:  {data}")\nprint(f"Bubble:    {bubble_sort(data)}")\nprint(f"Merge:     {merge_sort(data)}")\n'),
  ];

  static List<String> get categories => templates.map((t) => t.category).toSet().toList()..sort();
}
