#!/usr/bin/env python3
"""Hermetic Rails API stand-in. Test controls are loopback-only and never log secrets."""
import argparse
import base64
import datetime as dt
import hashlib
import json
import os
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlsplit


def task(number, date="2026-10-07T00:00:00Z", **fields):
    return dict(id=f"00000000-0000-4000-8000-{number:012d}", content=f"task {number}",
                due_date=date, due_time=None, is_all_day=False, skip_time=False,
                is_important=False, completed=False, **fields)


class State:
    def __init__(self):
        self.lock = threading.Lock()
        self.reset()

    def reset(self):
        self.mode = "normal"
        self.refresh_fail = False
        self.reject_access = False
        self.always_401 = False
        self.infinite = False
        self.generation = 0
        self.access = "access-0"
        self.refresh = "refresh-0"
        self.refresh_calls = 0
        self.polls = 0
        self.challenge = ""
        self.queries = []
        self.added = None
        self.cancelled = 0
        self.revoked = 0
        self.mcp = None
        self.tasks = [task(n) for n in range(1, 106)]
        self.tasks[1]["due_time"] = "15:00"
        self.tasks[2]["due_date"] = "2026-10-07T23:30:00Z"
        self.tasks[3]["completed"] = True
        self.tasks[4]["due_date"] = None
        self.tasks[5]["due_date"] = "2026-10-06T00:00:00Z"
        self.tasks[6]["due_date"] = "2026-10-05T00:00:00Z"
        self.tasks[7]["due_date"] = "2026-10-09T00:00:00Z"
        self.tasks[8].update(due_date="2026-10-07T23:00:00Z", skip_time=True)
        self.tasks[9].update(due_date="2026-10-07T23:00:00Z", is_all_day=True)
        self.tasks[10]["due_date"] = "2026-10-07T00:00:00.000Z"
        self.tasks[11]["due_date"] = "2026-10-06T23:30:00Z"
        self.tasks[12]["is_important"] = True

    def bundle(self):
        return dict(access_token=self.access, refresh_token=self.refresh,
                    expires_in=3600,
                    # Production sends a zone offset, not "Z" (observed 2026-10-07).
                    expires_at=(dt.datetime.now(dt.timezone(dt.timedelta(hours=9))) + dt.timedelta(hours=1))
                    .isoformat(timespec="seconds"),
                    user=dict(id="user-1", email="clock@example.test"))


STATE = State()


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *_args):
        pass

    def send(self, code=200, data=None, *, raw=None, meta=None):
        payload = raw if raw is not None else dict(success=code < 400,
                    status="success" if code < 400 else "error", data=data,
                    message=None, meta=meta or {})
        body = json.dumps(payload, ensure_ascii=False).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        self.handle_request()

    def do_POST(self):
        self.handle_request()

    def do_PATCH(self):
        self.handle_request()

    def handle_request(self):
        # Production Rack::Attack 403s User-Agents containing "curl" (rack_attack.rb bad_user_agents).
        if "curl" in self.headers.get("User-Agent", "").lower():
            self.send(403)
            return
        try:
            body = self.rfile.read(int(self.headers.get("Content-Length", 0)))
            body = json.loads(body) if body else {}
        except (ValueError, UnicodeDecodeError):
            self.send(400)
            return
        with STATE.lock:
            self.dispatch(body)

    def dispatch(self, body):
        s = STATE
        url = urlsplit(self.path)
        path = url.path
        if path == "/__control":
            if body.pop("reset", False):
                s.reset()
            for key, value in body.items():
                if key in ("mode", "refresh_fail", "reject_access", "always_401", "infinite"):
                    setattr(s, key, value)
                elif key == "overdue_many":
                    s.tasks = [task(n, "2026-10-01T00:00:00Z") for n in range(1, 151)]
            self.send(data={})
            return
        if path == "/__state":
            self.send(data=dict(refresh_calls=s.refresh_calls, queries=s.queries,
                               added=s.added, cancelled=s.cancelled, revoked=s.revoked,
                               mcp=s.mcp, tasks=s.tasks))
            return
        if path == "/api/auth/cli/device/start":
            if (body.get("client_name") != "Omarchy ainote clock" or
                    body.get("scopes") != ["read", "write", "mcp"] or
                    body.get("code_challenge_method") != "S256" or
                    len(body.get("code_challenge", "")) != 43):
                self.send(400)
                return
            s.challenge = body["code_challenge"]
            s.polls = 0
            self.send(data=dict(device_code="device-secret", user_code="ABCD-EFGH",
                               verification_uri="https://example.test/verify",
                               verification_uri_complete="https://example.test/verify?code=ABCD-EFGH",
                               expires_in=900, interval=5))
            return
        if path == "/api/auth/cli/device/cancel":
            s.cancelled += 1
            self.send(data={})
            return
        if path == "/api/auth/cli/device/poll":
            verifier = body.get("code_verifier", "")
            challenge = base64.urlsafe_b64encode(hashlib.sha256(verifier.encode()).digest()).decode().rstrip("=")
            if len(verifier) < 43 or challenge != s.challenge or body.get("device_code") != "device-secret":
                self.send(data=dict(error="invalid_grant"))
            elif s.mode == "key_limit":
                self.send(409, raw=dict(success=False, code="MCP_KEY_LIMIT", data=None))
            elif s.mode in ("denied", "expired"):
                self.send(data=dict(error="access_denied" if s.mode == "denied" else "expired_token"))
            elif s.polls == 0:
                s.polls += 1
                self.send(data=dict(error="authorization_pending"))
            elif s.polls == 1:
                s.polls += 1
                self.send(data=dict(error="slow_down", interval=10))
            else:
                self.send(data=dict(s.bundle(), status="complete", mcp_key="mcp-secret", scope="read write mcp"))
            return
        if path == "/api/auth/token/refresh":
            s.refresh_calls += 1
            time.sleep(0.1)  # Widen the race window for concurrent callers.
            if s.refresh_fail or body.get("refresh_token") != s.refresh:
                self.send(401)
            else:
                s.generation += 1
                s.access = f"access-{s.generation}"
                s.refresh = f"refresh-{s.generation}"
                s.reject_access = False
                self.send(data=s.bundle())  # No mcp_key: client must preserve it.
            return
        expected = "McpKey mcp-secret" if path == "/api/mcp" else "Bearer " + s.access
        if self.headers.get("Authorization") != expected or s.reject_access or s.always_401:
            self.send(401)
            return
        if path == "/api/auth/token/revoke":
            if body.get("token_type_hint") != "refresh_token" or body.get("token") != s.refresh:
                self.send(400)
            else:
                s.revoked += 1
                self.send(data={})
            return
        if path == "/api/mcp":
            s.mcp = body
            if body.get("params", {}).get("name") == "error":
                self.send(raw=dict(jsonrpc="2.0", id=1, error=dict(code=-32602, message="bad args")))
            else:
                self.send(raw=dict(jsonrpc="2.0", id=body.get("id"), result=dict(content=[dict(type="text", text="mock")], isError=False)))
            return
        if path == "/api/tasks" and self.command == "GET":
            query = {key: values[0] for key, values in parse_qs(url.query).items()}
            s.queries.append(query)
            if query.get("per_page") != "100":
                self.send(400)
                return
            rows = s.tasks
            if query.get("is_completed") == "false":
                rows = [row for row in rows if not row["completed"]]
            # Match Rails widened server-side UTC range, then client normalizes.
            for key, lower in (("start_date", True), ("end_date", False)):
                if key in query:
                    boundary = dt.datetime.fromisoformat(query[key].replace("Z", "+00:00"))
                    rows = [row for row in rows if row["due_date"] and
                            ((dt.datetime.fromisoformat(row["due_date"].replace("Z", "+00:00")) >= boundary)
                             if lower else (dt.datetime.fromisoformat(row["due_date"].replace("Z", "+00:00")) <= boundary))]
            page = int(query.get("page", 1))
            self.send(data=rows[(page-1)*100:page*100], meta=dict(has_more=s.infinite or len(rows) > page*100))
            return
        if path == "/api/tasks" and self.command == "POST":
            s.added = body
            row = task(999)
            row.update(body)
            s.tasks.append(row)
            self.send(201, data=row)
            return
        if path.startswith("/api/tasks/") and self.command == "PATCH":
            for row in s.tasks:
                if row["id"] == path.rsplit("/", 1)[1]:
                    row["completed"] = body["completed"]
                    self.send(data=row)
                    return
        self.send(404)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=int(os.getenv("PORT", "0")))
    parser.add_argument("--port-file")
    args = parser.parse_args()
    server = ThreadingHTTPServer(("127.0.0.1", args.port), Handler)
    if args.port_file:
        with open(args.port_file, "w", encoding="ascii") as port_file:
            port_file.write(str(server.server_port))
    server.serve_forever()
