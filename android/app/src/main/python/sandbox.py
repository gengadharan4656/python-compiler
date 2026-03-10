"""PyDroid Sandbox - import restrictions for security."""
import sys

BLOCKED_MODULES = {'subprocess', 'multiprocessing', 'ctypes', '_socket', 'pty', 'termios', 'tty', 'fcntl', 'grp', 'pwd', 'resource', 'mmap', 'msvcrt', 'winreg'}

class SandboxImporter:
    def find_module(self, name, path=None):
        if name.split('.')[0] in BLOCKED_MODULES:
            return self
        return None
    def load_module(self, name):
        raise ImportError(f"Module '{name.split('.')[0]}' is restricted in PyDroid sandbox.")

def install_sandbox():
    hook = SandboxImporter()
    if hook not in sys.meta_path:
        sys.meta_path.insert(0, hook)
