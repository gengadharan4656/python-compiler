"""PyDroid Sandbox - import restrictions for security and mobile-safe compatibility."""
import sys

BLOCKED_MODULES = {
    'subprocess', 'multiprocessing', 'ctypes', '_socket', 'pty', 'termios',
    'tty', 'fcntl', 'grp', 'pwd', 'resource', 'mmap', 'msvcrt', 'winreg',
    'tkinter', '_tkinter'
}

_BLOCK_MESSAGES = {
    'tkinter': "Module 'tkinter' is not supported in this mobile runtime. Use terminal output, saved files, or mobile-safe plotting instead.",
    '_tkinter': "Module '_tkinter' is not supported in this mobile runtime. Use terminal output, saved files, or mobile-safe plotting instead.",
}


class SandboxImporter:
    def find_module(self, name, path=None):
        if name.split('.')[0] in BLOCKED_MODULES:
            return self
        return None

    def load_module(self, name):
        root = name.split('.')[0]
        raise ImportError(_BLOCK_MESSAGES.get(root, f"Module '{root}' is restricted in PyDroid sandbox."))


def install_sandbox():
    hook = SandboxImporter()
    if hook not in sys.meta_path:
        sys.meta_path.insert(0, hook)
