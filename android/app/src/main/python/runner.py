"""PyDroid Python runner with streaming terminal-style I/O."""
import builtins
import importlib.abc
import importlib.machinery
import io
import os
import queue
import sys
import threading
import time
import traceback
from dataclasses import dataclass, field

from sandbox import install_sandbox

_stop_flag = threading.Event()
_session_lock = threading.Lock()
_current_session = None
_MAX_CAPTURE_CHARS = 100000


class _UnsupportedGuiImporter(importlib.abc.MetaPathFinder, importlib.abc.Loader):
    """Provide a clearer message for desktop-only GUI stacks."""

    UNSUPPORTED = {"tkinter", "_tkinter"}

    def find_spec(self, fullname, path=None, target=None):
        if fullname.split(".", 1)[0] in self.UNSUPPORTED:
            return importlib.machinery.ModuleSpec(fullname, self)
        return None

    def create_module(self, spec):
        return None

    def exec_module(self, module):
        raise ImportError(
            "tkinter is not supported in this mobile runtime. "
            "Use terminal output, saved files, or a mobile-safe plotting workflow instead.",
        )


class StreamCapture(io.TextIOBase):
    def __init__(self, session, stream_name: str):
        self._session = session
        self._stream_name = stream_name

    def write(self, data):
        if not data:
            return 0
        self._session.emit(self._stream_name, str(data))
        return len(data)

    def flush(self):
        return None


@dataclass
class ExecutionSession:
    file_path: str
    project_id: str = ""
    project_path: str = ""
    packages_path: str = ""
    status: str = "running"
    stdout_parts: list[str] = field(default_factory=list)
    stderr_parts: list[str] = field(default_factory=list)
    output_queue: "queue.Queue[dict]" = field(default_factory=queue.Queue)
    input_queue: "queue.Queue[str]" = field(default_factory=queue.Queue)
    done_event: threading.Event = field(default_factory=threading.Event)
    waiting_for_input: bool = False
    prompt: str = ""
    execution_time_ms: int = 0
    _thread: threading.Thread | None = None

    def start(self):
        self._thread = threading.Thread(target=self._run, name="PyDroidExec", daemon=True)
        self._thread.start()

    def emit(self, event_type: str, text: str = ""):
        if text:
            if event_type == "stdout":
                self.stdout_parts.append(text)
                self.stdout_parts = _trim_parts(self.stdout_parts)
            elif event_type == "stderr":
                self.stderr_parts.append(text)
                self.stderr_parts = _trim_parts(self.stderr_parts)
        self.output_queue.put({"type": event_type, "text": text})

    def request_input(self, prompt: str) -> str:
        self.waiting_for_input = True
        self.prompt = prompt
        if prompt:
            self.emit("stdout", str(prompt))
        self.output_queue.put({"type": "input_request", "prompt": prompt, "text": ""})

        while not _stop_flag.is_set():
            try:
                line = self.input_queue.get(timeout=0.1)
                self.waiting_for_input = False
                self.prompt = ""
                if _stop_flag.is_set():
                    raise KeyboardInterrupt
                return line
            except queue.Empty:
                continue
        raise KeyboardInterrupt

    def submit_input(self, line: str):
        self.input_queue.put(line)

    def poll_events(self, max_events: int = 200) -> list[dict]:
        events = []
        for _ in range(max_events):
            try:
                events.append(self.output_queue.get_nowait())
            except queue.Empty:
                break
        return events

    def snapshot(self) -> dict:
        return {
            "status": self.status,
            "stdout": _joined_output(self.stdout_parts),
            "stderr": _joined_output(self.stderr_parts),
            "executionTimeMs": self.execution_time_ms,
            "done": self.done_event.is_set(),
            "waitingForInput": self.waiting_for_input,
            "prompt": self.prompt,
        }

    def _run(self):
        start = time.time()
        work_dir = os.path.dirname(self.file_path)
        original_dir = os.getcwd()
        original_stdout = sys.stdout
        original_stderr = sys.stderr
        original_stdin = sys.stdin
        original_input = builtins.input
        original_meta_path = list(sys.meta_path)

        try:
            os.chdir(work_dir)
            if self.project_path and os.path.isdir(self.project_path) and self.project_path not in sys.path:
                sys.path.insert(0, self.project_path)
            if self.packages_path and os.path.isdir(self.packages_path) and self.packages_path not in sys.path:
                sys.path.insert(0, self.packages_path)

            install_sandbox()
            if not any(isinstance(hook, _UnsupportedGuiImporter) for hook in sys.meta_path):
                sys.meta_path.insert(0, _UnsupportedGuiImporter())

            os.environ.setdefault("MPLBACKEND", "Agg")
            mpl_dir = os.path.join(self.project_path or work_dir, ".matplotlib")
            os.makedirs(mpl_dir, exist_ok=True)
            os.environ.setdefault("MPLCONFIGDIR", mpl_dir)

            try:
                import matplotlib

                matplotlib.use("Agg", force=True)
                try:
                    import matplotlib.pyplot as plt

                    def _mobile_safe_show(*args, **kwargs):
                        sys.stderr.write(
                            "matplotlib GUI windows are not available on mobile; "
                            "use savefig(...) to create image files.\n",
                        )

                    plt.show = _mobile_safe_show
                except Exception:
                    pass
            except Exception:
                pass

            sys.stdin = self
            sys.stdout = StreamCapture(self, "stdout")
            sys.stderr = StreamCapture(self, "stderr")

            def patched_input(prompt=""):
                return self.request_input(str(prompt or ""))

            builtins.input = patched_input

            with open(self.file_path, "r", encoding="utf-8") as handle:
                code = handle.read()

            exec(
                compile(code, self.file_path, "exec"),
                {
                    "__builtins__": __builtins__,
                    "__name__": "__main__",
                    "__doc__": None,
                    "__file__": self.file_path,
                },
            )
            self.status = "success"
        except SystemExit as exc:
            if exc.code not in (None, 0):
                self.emit("stderr", f"SystemExit: {exc.code}\n")
                self.status = "error"
            else:
                self.status = "success"
        except KeyboardInterrupt:
            self.emit("stderr", "KeyboardInterrupt\n")
            self.status = "interrupted"
        except SyntaxError as exc:
            self.emit("stderr", f"SyntaxError: {exc.msg}\n")
            self.emit("stderr", f"  File \"{exc.filename}\", line {exc.lineno}\n")
            if exc.text:
                self.emit("stderr", f"    {exc.text.rstrip()}\n")
            self.status = "error"
        except Exception:
            self.emit("stderr", traceback.format_exc())
            self.status = "error"
        finally:
            builtins.input = original_input
            sys.stdout = original_stdout
            sys.stderr = original_stderr
            sys.stdin = original_stdin
            sys.meta_path[:] = original_meta_path
            try:
                os.chdir(original_dir)
            except Exception:
                pass
            self.execution_time_ms = int((time.time() - start) * 1000)
            self.waiting_for_input = False
            self.prompt = ""
            self.done_event.set()

    def readline(self, size=-1):
        return self.request_input("") + "\n"


def _trim_parts(parts: list[str]) -> list[str]:
    joined_length = sum(len(part) for part in parts)
    while joined_length > _MAX_CAPTURE_CHARS and parts:
        joined_length -= len(parts[0])
        parts.pop(0)
    return parts


def _joined_output(parts: list[str]) -> str:
    value = "".join(parts)
    if len(value) > _MAX_CAPTURE_CHARS:
        return value[-_MAX_CAPTURE_CHARS:]
    return value


def run_file(
    file_path: str,
    project_id: str = "",
    project_path: str = "",
    packages_path: str = "",
):
    global _current_session
    _stop_flag.clear()
    session = ExecutionSession(
        file_path=file_path,
        project_id=project_id,
        project_path=project_path,
        packages_path=packages_path,
    )
    with _session_lock:
        _current_session = session
    session.start()
    return {"status": "running"}


def poll_events(max_events: int = 200):
    with _session_lock:
        session = _current_session
    if session is None:
        return []
    return session.poll_events(max_events=max_events)


def get_session_result():
    with _session_lock:
        session = _current_session
    if session is None:
        return {
            "status": "error",
            "stdout": "",
            "stderr": "No execution session is active.",
            "executionTimeMs": 0,
            "done": True,
            "waitingForInput": False,
            "prompt": "",
        }
    return session.snapshot()


def submit_input(line: str):
    with _session_lock:
        session = _current_session
    if session is None:
        raise EOFError("No execution session is active.")
    session.submit_input(line)
    return True


def stop_execution():
    _stop_flag.set()
    with _session_lock:
        session = _current_session
    if session is not None:
        session.submit_input("")
