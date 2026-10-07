#!/usr/bin/env python3
"""End-to-end subprocess checks; production helper never imports this module."""
import concurrent.futures
import json
import os
from pathlib import Path
import socket
import stat
import subprocess
import sys
import urllib.error
import urllib.request

HELPER = sys.argv[1]
BASE = os.environ["AINOTE_API_URL"]
CONFIG = Path(os.environ["XDG_CONFIG_HOME"]) / "ainote-clock"
CRED = CONFIG / "credentials.json"
PENDING = CONFIG / "pending.json"
passed = failed = 0


def api(path, body=None):
    if os.environ.get("AINOTE_MOCK_STATE"):
        from stdio_curl import dispatch
        code, result = dispatch("GET" if body is None else "POST", path, {}, body or {})
        if code >= 400:
            raise urllib.error.HTTPError(BASE + path, code, "mock error", {}, None)
        return result
    request = urllib.request.Request(BASE + path, data=None if body is None else json.dumps(body).encode(),
                                     headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(request, timeout=10) as response:
        return json.load(response)


def control(**values):
    api("/__control", values)


def state():
    return api("/__state")["data"]


def invoke(*args, content=None, env=None, error=None):
    proc = subprocess.run([HELPER, *args], input=content, text=True, capture_output=True,
                          env=env, timeout=30)
    assert len(proc.stdout.splitlines()) == 1, "stdout must have exactly one line"
    assert proc.stderr == "", "stderr must not leak diagnostics"
    result = json.loads(proc.stdout)
    assert proc.returncode == (0 if result["ok"] else 1), "exit status differs from JSON"
    if error:
        assert not result["ok"] and result["error"] == error, f"expected {error}"
    else:
        assert result["ok"], f"command failed: {result.get('error')}"
    return result


def check(name, function):
    global passed, failed
    try:
        function()
        passed += 1
        print("PASS " + name)
    except Exception as exc:
        failed += 1
        print(f"FAIL {name}: {type(exc).__name__}: {exc}")


def expect(value, message="unexpected result"):
    assert value, message


def login():
    control(reset=True)
    invoke("login-start")
    invoke("login-poll")
    invoke("login-poll")
    invoke("login-poll")


def edit_creds(**values):
    data = json.loads(CRED.read_text())
    data.update(values)
    CRED.write_text(json.dumps(data))


def listing(**kwargs):
    return invoke("list", "--from", "2026-10-07", "--to", "2026-10-08", **kwargs)


def flow():
    expect(invoke("status") == dict(ok=True, loggedIn=False, email=None))
    invoke("list", "--from", "2026-10-07", "--to", "2026-10-08", error="not_logged_in")
    start = invoke("login-start")
    expect(start["interval"] == 5 and start["expiresIn"] == 900)
    expect(stat.S_IMODE(PENDING.stat().st_mode) == 0o600)
    expect(len(json.loads(PENDING.read_text())["code_verifier"]) >= 43)
    expect(invoke("login-poll")["state"] == "pending")
    expect(invoke("login-poll") == dict(ok=True, state="slow_down", interval=10))
    expect(json.loads(PENDING.read_text())["interval"] == 10)
    expect(invoke("login-poll") == dict(ok=True, state="complete", interval=10))
    expect(not PENDING.exists())
    expect(invoke("status") == dict(ok=True, loggedIn=True, email="clock@example.test"))


def permissions():
    expect(stat.S_IMODE(CONFIG.stat().st_mode) == 0o700)
    expect(stat.S_IMODE(CRED.stat().st_mode) == 0o600)
    expect(not list(CONFIG.glob(".request.*")) and not list(CONFIG.glob(".atomic.*")))


def normalization():
    rows = {row["id"][-12:]: row for row in listing()["tasks"]}
    expect(rows["000000000001"]["date"] == "2026-10-07" and rows["000000000001"]["time"] is None)
    expect(rows["000000000002"]["time"] == "15:00")
    expect(rows["000000000003"]["date"] == "2026-10-08" and rows["000000000003"]["time"] == "08:30")
    expect(rows["000000000004"]["completed"])
    expect(rows["000000000013"]["important"])
    # Flagged rows that are not UTC midnight land on the owner's local day (KST here).
    for n in (9, 10):
        expect(rows[f"{n:012d}"]["date"] == "2026-10-08" and rows[f"{n:012d}"]["time"] is None)
    expect(rows["000000000011"]["date"] == "2026-10-07" and rows["000000000011"]["time"] is None)
    expect(rows["000000000012"]["date"] == "2026-10-07" and rows["000000000012"]["time"] == "08:30")
    expect(all(set(row) == {"id", "content", "date", "time", "important", "completed"} for row in rows.values()))


def range_pagination():
    rows = listing()["tasks"]
    expect(len(rows) == 101 and any(row["id"].endswith("000000000105") for row in rows))
    expect(all("2026-10-07" <= row["date"] <= "2026-10-08" for row in rows))
    queries = state()["queries"]
    expect(queries[-2]["page"] == "1" and queries[-1]["page"] == "2")
    expect(queries[-1]["start_date"] == "2026-10-06T00:00:00Z")
    expect(queries[-1]["end_date"] == "2026-10-09T00:00:00Z")
    expect("is_completed" not in queries[-1])
    rows = invoke("list", "--to", "2026-10-07", "--from", "2026-10-07")["tasks"]
    expect(all(row["date"] == "2026-10-07" for row in rows))


def overdue():
    rows = invoke("overdue", "--before", "2026-10-07")["tasks"]
    expect(len(rows) == 2 and all(not row["completed"] and row["date"] < "2026-10-07" for row in rows))
    expect(state()["queries"][-1]["is_completed"] == "false")
    control(overdue_many=True)
    expect(len(invoke("overdue", "--before", "2026-10-07")["tasks"]) == 100)
    login()


def retry():
    control(reject_access=True)
    listing()
    expect(state()["refresh_calls"] == 1)
    creds = json.loads(CRED.read_text())
    expect(creds["mcp_key"] == "mcp-secret" and creds["refresh_token"] == "refresh-1")
    try:
        api("/api/auth/token/refresh", dict(refresh_token="refresh-0"))
        raise AssertionError("old refresh token was accepted")
    except urllib.error.HTTPError as exc:
        expect(exc.code == 401)


def refresh_failure():
    control(refresh_fail=True)
    edit_creds(expires_at=0)
    original = CRED.read_bytes()
    listing(error="auth_expired")
    expect(CRED.read_bytes() == original)
    login()


def concurrency():
    edit_creds(expires_at=0)
    with concurrent.futures.ThreadPoolExecutor(2) as pool:
        futures = [pool.submit(listing) for _ in range(2)]
        for future in futures:
            future.result()
    expect(state()["refresh_calls"] == 1)
    permissions()


def content_exact():
    # Never delete /tmp/pwned: it may belong to the user. Compare its prior state.
    pwned = Path("/tmp/pwned")
    before = pwned.stat() if pwned.exists() else None
    dangerous = "a\"b'c $(touch /tmp/pwned) ` 한글"
    result = invoke("add", "--date", "2026-10-07", content=dangerous)
    expect(state()["added"]["content"] == dangerous)
    expect(result["task"]["date"] == "2026-10-07" and result["task"]["time"] is None)
    payload = state()["added"]
    expect(payload["due_date"] == "2026-10-07T00:00:00Z" and payload["skip_time"] is True)
    expect((pwned.stat() if pwned.exists() else None) == before)
    multiline = "첫째\n둘째\n\"quote\" \\ backslash"
    invoke("add", "--date", "2026-10-07", content=" \n" + multiline + "\n ")
    expect(state()["added"]["content"] == multiline)
    invoke("add", "--date", "2026-10-07", content="가" * 500)
    invoke("add", "--date", "2026-10-07", content="가" * 501, error="bad_request")
    invoke("add", "--date", "2026-10-07", content=" \n\t ", error="bad_request")


def completion():
    task_id = state()["tasks"][0]["id"]
    invoke("done", task_id)
    expect(state()["tasks"][0]["completed"] is True)
    invoke("undone", task_id)
    expect(state()["tasks"][0]["completed"] is False)
    invoke("done", "../secret", error="bad_request")
    invoke("done", "f" * 65, error="bad_request")


def mcp():
    result = invoke("mcp-call", "list_tasks", content='{"query":"한글"}')
    expect(result["result"] == dict(content=[dict(type="text", text="mock")], isError=False))
    expect(state()["mcp"] == dict(jsonrpc="2.0", id=1, method="tools/call", params=dict(name="list_tasks", arguments=dict(query="한글"))))
    for value in ("[]", "{} {}", "null", "invalid"):
        invoke("mcp-call", "list_tasks", content=value, error="bad_request")
    invoke("mcp-call", "error", content="{}", error="server_error")


def offline():
    if os.environ.get("AINOTE_MOCK_STATE"):
        env = dict(os.environ, AINOTE_API_URL="http://127.0.0.1:1")
        listing(env=env, error="offline")
        invoke("login-start", env=env, error="offline")
        invoke("login-cancel", env=env)
        return
    # Bound but not listening: no other process can steal the selected port.
    with socket.socket() as sock:
        sock.bind(("127.0.0.1", 0))
        env = dict(os.environ, AINOTE_API_URL=f"http://127.0.0.1:{sock.getsockname()[1]}")
        listing(env=env, error="offline")
        invoke("login-start", env=env, error="offline")
        invoke("login-cancel", env=env)


def terminals():
    for mode, code in (("key_limit", "key_limit"), ("denied", "denied"), ("expired", "expired")):
        control(mode=mode)
        invoke("login-start")
        invoke("login-poll", error=code)
        if mode != "key_limit":
            expect(not PENDING.exists())
    control(mode="normal")
    invoke("login-start")
    pending = json.loads(PENDING.read_text())
    pending["code_verifier"] = "wrong" * 10
    PENDING.write_text(json.dumps(pending))
    invoke("login-poll", error="denied")
    expect(not PENDING.exists())
    invoke("login-start")
    pending = json.loads(PENDING.read_text())
    pending["deadline"] = 0
    PENDING.write_text(json.dumps(pending))
    invoke("login-poll", error="expired")
    expect(not PENDING.exists())
    invoke("login-start")
    invoke("login-cancel")
    expect(not PENDING.exists() and state()["cancelled"] == 1)


def validation():
    for args in (("unknown",), ("status", "extra"), ("list",),
                 ("list", "--from", "2026-02-30", "--to", "2026-10-07"),
                 ("list", "--from", "2026-10-08", "--to", "2026-10-07"),
                 ("overdue", "--before", "tomorrow")):
        invoke(*args, error="bad_request")


def safety_caps():
    control(infinite=True)
    before = len(state()["queries"])
    listing(error="server_error")
    expect(len(state()["queries"]) - before == 10)
    control(infinite=False, always_401=True)
    before = state()["refresh_calls"]
    listing(error="auth_expired")
    expect(state()["refresh_calls"] - before == 1)
    control(always_401=False)


def logout():
    invoke("logout")
    expect(not CRED.exists() and state()["revoked"] == 1)
    expect(not invoke("status")["loggedIn"])
    invoke("logout")


for name, function in (("device flow + PKCE + status", flow), ("0600/0700 + temp cleanup", permissions),
                       ("date/time normalization", normalization), ("range + pagination", range_pagination),
                       ("overdue + cap 100", overdue), ("401 refresh/retry + rotation", retry),
                       ("refresh failure preserves credentials", refresh_failure),
                       ("two concurrent lists refresh once", concurrency),
                       ("add exact content + multiline + length", content_exact), ("done/undone", completion),
                       ("MCP raw result + object validation", mcp), ("offline", offline),
                       ("key limit + denied + expired + cancel", terminals), ("argument validation", validation),
                       ("10-page cap + bounded 401 retry", safety_caps), ("logout", logout)):
    check(name, function)
print(f"PASS {passed} / FAIL {failed}")
sys.exit(1 if failed else 0)
