import os
from pathlib import Path
import re
import select
import subprocess
import sys
from tempfile import TemporaryDirectory
from time import monotonic, sleep

BANNER = b"Hello from honhon\r\n"
PAYLOAD = b"UART echo on honhon!\r\x00\x80\xff"


def read_until(fd, pattern, deadline):
    output = bytearray()
    while monotonic() < deadline:
        ready, _, _ = select.select([fd], [], [], max(0, deadline - monotonic()))
        if not ready:
            break
        chunk = os.read(fd, 4096)
        if not chunk:
            break
        output.extend(chunk)
        match = pattern.search(output)
        if match:
            return match
    raise AssertionError(f"Expected {pattern.pattern!r}, received {bytes(output)!r}")


def check_log(path, expected, deadline):
    while monotonic() < deadline:
        if path.is_file() and path.read_bytes() == expected:
            return
        sleep(0.01)
    actual = path.read_bytes() if path.is_file() else b""
    raise AssertionError(f"Unexpected UART log: {actual!r}")


def main():
    with TemporaryDirectory(prefix="honhon-uart-") as scratch:
        log = Path(scratch) / "uart0.log"
        with subprocess.Popen(
            [sys.argv[1], "--uart-log", str(log)],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        ) as vp:
            try:
                deadline = monotonic() + 10
                pty_path = read_until(
                    vp.stdout.fileno(), re.compile(rb"UART uart0: (/dev/pts/\d+)\n"), deadline
                ).group(1)

                # UART output must reach the log before a terminal attaches.
                check_log(log, BANNER, deadline)
                terminal = os.open(pty_path, os.O_RDWR | os.O_NOCTTY | os.O_NONBLOCK)
                try:
                    read_until(terminal, re.compile(re.escape(BANNER)), deadline)
                    if os.write(terminal, PAYLOAD) != len(PAYLOAD):
                        raise AssertionError("Could not write the complete UART test payload")
                    read_until(terminal, re.compile(re.escape(PAYLOAD)), deadline)
                    check_log(log, BANNER + PAYLOAD, deadline)
                finally:
                    os.close(terminal)
            finally:
                if vp.poll() is None:
                    vp.terminate()
                _, errors = vp.communicate(timeout=3)
                if errors:
                    sys.stderr.buffer.write(errors)

            if vp.returncode != 0:
                raise AssertionError(f"VP exited with code {vp.returncode}")


if __name__ == "__main__":
    main()
