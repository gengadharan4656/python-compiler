"""PyDroid Python Runner - executes user code and captures output."""
import builtins
import io
import os
import sys
import traceback
import threading

_stop_flag = threading.Event()


class ScriptInput(io.TextIOBase):
    def __init__(self, raw_input: str = ""):
        if not raw_input:
            self._lines = []
        else:
            normalized = raw_input.replace("\r\n", "\n")
            self._lines = normalized.split("\n")
        self._index = 0

    def readline(self, size=-1):
        if self._index >= len(self._lines):
            return ""
        line = self._lines[self._index]
        self._index += 1
        return line + "\n"


def stop_execution():
    _stop_flag.set()


def run_file(
    file_path: str,
    stdin_input: str = "",
    project_id: str = "",
    project_path: str = "",
    packages_path: str = "",
) -> dict:
    _stop_flag.clear()
    work_dir = os.path.dirname(file_path)
    original_dir = os.getcwd()
    stdout_capture = io.StringIO()
    stderr_capture = io.StringIO()
    original_stdout = sys.stdout
    original_stderr = sys.stderr
    original_stdin = sys.stdin
    original_input = builtins.input
    status = "success"

    try:
        os.chdir(work_dir)
        if project_path and os.path.isdir(project_path) and project_path not in sys.path:
            sys.path.insert(0, project_path)
        if packages_path and os.path.isdir(packages_path) and packages_path not in sys.path:
            sys.path.insert(0, packages_path)

        script_stdin = ScriptInput(stdin_input)
        sys.stdin = script_stdin
        sys.stdout = stdout_capture
        sys.stderr = stderr_capture

        def patched_input(prompt=""):
            if prompt:
                sys.stdout.write(str(prompt))
            line = script_stdin.readline()
            if line == "":
                raise EOFError(
                    "No stdin input provided. Add input lines in the app before running this script.",
                )
            return line.rstrip("\n")

        builtins.input = patched_input

        with open(file_path, "r", encoding="utf-8") as f:
            code = f.read()

        exec(
            compile(code, file_path, "exec"),
            {
                "__builtins__": __builtins__,
                "__name__": "__main__",
                "__doc__": None,
                "__file__": file_path,
            },
        )
    except SystemExit as e:
        if e.code not in (None, 0):
            stderr_capture.write(f"SystemExit: {e.code}\n")
            status = "error"
    except KeyboardInterrupt:
        stderr_capture.write("KeyboardInterrupt\n")
        status = "interrupted"
    except SyntaxError as e:
        stderr_capture.write(f"SyntaxError: {e.msg}\n")
        stderr_capture.write(f"  File \"{e.filename}\", line {e.lineno}\n")
        if e.text:
            stderr_capture.write(f"    {e.text.rstrip()}\n")
        status = "error"
    except Exception:
        stderr_capture.write(traceback.format_exc())
        status = "error"
    finally:
        sys.stdout = original_stdout
        sys.stderr = original_stderr
        sys.stdin = original_stdin
        builtins.input = original_input
        try:
            os.chdir(original_dir)
        except Exception:
            pass

    stdout_val = stdout_capture.getvalue()
    stderr_val = stderr_capture.getvalue()
    max_chars = 100000
    if len(stdout_val) > max_chars:
        stdout_val = stdout_val[:max_chars] + "\n... [output truncated]"
    if len(stderr_val) > max_chars:
        stderr_val = stderr_val[:max_chars] + "\n... [error truncated]"

    return {"status": status, "stdout": stdout_val, "stderr": stderr_val}
