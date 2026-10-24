"""Check that a desktop build stays open without initialization failures."""

from pathlib import Path
import subprocess
import sys
import tempfile


def main():
    executable = Path(sys.argv[1]).resolve()
    with tempfile.TemporaryFile(mode="w+") as output:
        process = subprocess.Popen([str(executable)], stdout=output, stderr=output)
        try:
            process.wait(timeout=15)
        except subprocess.TimeoutExpired:
            pass
        else:
            raise RuntimeError(f"Musify exited during startup: {process.returncode}")
        finally:
            if process.poll() is None:
                process.terminate()
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()
            output.seek(0)
            logs = output.read()
            print(logs)
        for failure in (
            "Initialization Error",
            "LateInitializationError",
            "MissingPluginException",
            "Could not initialize Linux media controls",
            "Could not initialize Windows media controls",
        ):
            assert failure not in logs, f"Startup failed: {failure}"
    print("Musify remained open without initialization errors.")


if __name__ == "__main__":
    main()
