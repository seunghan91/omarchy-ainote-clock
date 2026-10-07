# Helper tests

Run `tests/helper/run.sh`. Requires bash, curl, jq, openssl and Python 3;
Linux uses `flock`, and macOS uses Python's `fcntl.flock` when the utility is
unavailable. The helper also runs with macOS's bundled bash 3.2.

The normal suite starts a Python stdlib HTTP server on an ephemeral loopback
port, uses real curl, and isolates HOME/config in a temporary directory under
`tests/helper/`. `mock_server.py --port N` or `PORT=N` can select a port.

Some execution sandboxes deny even local socket creation. Only on that specific
startup failure, the runner prints `TRANSPORT stdio` and uses `stdio_curl.py` to
dispatch the same mock handlers through private files. That mode checks command
contracts, persisted state, rotation, locking, normalization and curl argument
construction, but **does not verify real HTTP/curl transport**. The helper itself
has no mock mode. HTTP results must not be inferred from stdio results.

## Decisions left open by the interface

- `status` reports locally stored credential presence, not server validity.
- Scopes are the Rails service's required array `["read", "write", "mcp"]`.
- The config lock covers each command, not just refresh: login/logout cannot race
  rotation. Credentials are re-read after lock acquisition. Stored expiry is Unix
  seconds; a server ISO timestamp is converted when saving.
- Date-only classification uses explicit flags or UTC midnight, as Spec A asks.
  Owner-local midnight cannot be inferred without the owner's timezone; the
  helper does not substitute the viewer's timezone for that missing information.
- `add` trims outer whitespace while preserving internal newlines and characters.
  It sends UTC midnight, `due_time:null`, `skip_time:true`, `is_all_day:false`.
  REST permits these fields and parses ISO dates; the web form's date parser
  stores `Date.parse(...).to_datetime` (UTC midnight). See the source references
  beside the payload in `bin/ainote-clock`.
- `invalid_grant` maps to `denied` and clears pending state. `key_limit` retains
  pending state so the user can remove a key and retry. Slow-down uses at least
  the old interval plus five seconds; polling never sleeps inside the helper.
- A 10-page truncation returns `server_error`, rather than a misleading complete
  result. Overdue stops after 100 matching tasks; results are deduplicated by id
  and sorted by date/time/id. No oldest-first selection is promised by the API.
- A JSON-RPC error maps to `server_error`; a tools result (including an MCP
  `isError` result) is returned unchanged for its caller to interpret.
- Logout attempts refresh-token revocation with the current access token, then
  clears both credential and pending state even if the server is unreachable.
