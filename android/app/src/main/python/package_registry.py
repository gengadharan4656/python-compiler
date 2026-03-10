"""PyDroid Package Registry."""
AVAILABLE_PACKAGES = {
    "requests": {"version": "2.31.0", "description": "HTTP library", "category": "Network"},
    "urllib3": {"version": "2.1.0", "description": "HTTP client", "category": "Network"},
    "numpy": {"version": "1.24.0", "description": "Numerical computing", "category": "Data Science", "native": True},
    "pandas": {"version": "2.0.0", "description": "Data analysis", "category": "Data Science", "native": True},
    "pillow": {"version": "10.0.0", "description": "Image processing", "category": "Image", "native": True},
    "sympy": {"version": "1.12", "description": "Symbolic math", "category": "Mathematics"},
    "python-dateutil": {"version": "2.8.2", "description": "Date utilities", "category": "Utilities"},
    "rich": {"version": "13.5.0", "description": "Rich text formatting", "category": "Utilities"},
    "faker": {"version": "20.0.0", "description": "Fake data generator", "category": "Utilities"},
    "colorama": {"version": "0.4.6", "description": "Colored terminal text", "category": "Utilities"},
    "pydantic": {"version": "2.5.0", "description": "Data validation", "category": "Utilities"},
}

def get_package_list(): return list(AVAILABLE_PACKAGES.keys())
def get_package_info(name): return AVAILABLE_PACKAGES.get(name)
def is_available(name): return name in AVAILABLE_PACKAGES
