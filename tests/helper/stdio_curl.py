#!/usr/bin/env python3
"""Socket-free contract testing ONLY; not a replacement for real curl HTTP QA.

Uses the same mock handler with file-persisted state when a sandbox denies bind.
The real-network run.sh path never places this adapter on PATH.
"""
import fcntl
import json
import os
from pathlib import Path
import pickle
import sys

from mock_server import Handler, STATE


def dispatch(method, url, headers, body):
    path = Path(os.environ["AINOTE_MOCK_STATE"])
    with path.with_suffix(".lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        if path.exists():
            STATE.__dict__.update(pickle.loads(path.read_bytes()))
        handler = object.__new__(Handler)
        handler.command = method
        handler.path = url
        handler.headers = headers
        response = []

        def send(code=200, data=None, *, raw=None, meta=None):
            response.extend([code, raw if raw is not None else dict(success=code < 400,
                status="success" if code < 400 else "error", data=data,
                message=None, meta=meta or {})])

        handler.send = send
        handler.dispatch(body)
        path.write_bytes(pickle.dumps({k: v for k, v in STATE.__dict__.items() if k != "lock"}))
        return response


def main():
    from urllib.parse import urlsplit
    args = sys.argv[1:]
    # The adapter also checks the helper's curl security/timeout contract.
    assert "--silent" in args and args[args.index("--max-time") + 1] == "15"
    assert args[args.index("--data-binary") + 1] == "@-"
    assert not any("access-" in arg or "refresh-" in arg or "mcp-secret" in arg for arg in args)
    url = args[-1]
    if not url.startswith(os.environ["AINOTE_MOCK_BASE"] + "/"):
        return 7
    header_arg = args[args.index("-H") + 1]
    assert header_arg.startswith("@")
    header_file = Path(header_arg[1:])
    assert header_file.stat().st_mode & 0o777 == 0o600
    headers = dict(line.split(": ", 1) for line in header_file.read_text().splitlines())
    raw = sys.stdin.read()
    parsed = urlsplit(url)
    code, body = dispatch(args[args.index("--request") + 1],
                          parsed.path + ("?" + parsed.query if parsed.query else ""),
                          headers, json.loads(raw) if raw else {})
    Path(args[args.index("--output") + 1]).write_text(json.dumps(body))
    sys.stdout.write(str(code))
    return 0


if __name__ == "__main__":
    sys.exit(main())
