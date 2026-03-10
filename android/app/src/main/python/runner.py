"""PyDroid Python Runner - executes user code and captures output."""
import sys
import io
import traceback
import os
import threading

_stop_flag = threading.Event()

def stop_execution():
    _stop_flag.set()

def run_file(file_path: str, stdin_input: str = "", project_id: str = "") -> dict:
    _stop_flag.clear()
    work_dir = os.path.dirname(file_path)
    original_dir = os.getcwd()
    stdout_capture = io.StringIO()
    stderr_capture = io.StringIO()
    original_stdout = sys.stdout
    original_stderr = sys.stderr
    original_stdin = sys.stdin
    status = "success"

    try:
        os.chdir(work_dir)
        sys.stdin = io.StringIO(stdin_input)
        sys.stdout = stdout_capture
        sys.stderr = stderr_capture

        with open(file_path, 'r', encoding='utf-8') as f:
            code = f.read()

        exec(compile(code, file_path, 'exec'), {
            '__builtins__': __builtins__,
            '__name__': '__main__',
            '__doc__': None,
            '__file__': file_path,
        })
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
