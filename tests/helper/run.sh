#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
export TZ=Asia/Seoul
export PYTHONDONTWRITEBYTECODE=1
unset AINOTE_MOCK_STATE AINOTE_MOCK_BASE AINOTE_CLOCK_LOCK_HELD
unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY all_proxy
export NO_PROXY=127.0.0.1 no_proxy=127.0.0.1
# All run artifacts stay inside this lane's directory; nothing touches real HOME.
TEST_TMP=$(mktemp -d "$ROOT/tests/helper/.run.XXXXXX")
SERVER_PID=
cleanup() {
  if [[ -n $SERVER_PID ]]; then
    kill "$SERVER_PID" 2>/dev/null || true
    wait "$SERVER_PID" 2>/dev/null || true
  fi
  rm -rf "$TEST_TMP"
}
trap cleanup EXIT
export HOME=$TEST_TMP/home XDG_CONFIG_HOME=$TEST_TMP/config
mkdir -p "$HOME" "$XDG_CONFIG_HOME"
python3 "$ROOT/tests/helper/mock_server.py" --port 0 --port-file "$TEST_TMP/port" >"$TEST_TMP/server.log" 2>&1 &
SERVER_PID=$!
for ((attempt=0; attempt<100; attempt++)); do
  [[ ! -s $TEST_TMP/port ]] || break
  kill -0 "$SERVER_PID" 2>/dev/null || break
  sleep 0.05
done
if [[ -s $TEST_TMP/port ]]; then
  AINOTE_API_URL="http://127.0.0.1:$(cat "$TEST_TMP/port")"
  printf 'TRANSPORT HTTP (real curl + loopback server)\n'
elif python3 -c 'import pathlib,sys; sys.exit(0 if "PermissionError: [Errno 1]" in pathlib.Path(sys.argv[1]).read_text() else 1)' "$TEST_TMP/server.log"; then
  # Explicitly report the narrower evidence when sandbox policy blocks sockets.
  AINOTE_API_URL=http://127.0.0.1:18080
  export AINOTE_MOCK_STATE=$TEST_TMP/mock-state AINOTE_MOCK_BASE=$AINOTE_API_URL
  mkdir -p "$TEST_TMP/transport"
  ln -s "$ROOT/tests/helper/stdio_curl.py" "$TEST_TMP/transport/curl"
  export PATH="$TEST_TMP/transport:$PATH"
  printf 'TRANSPORT stdio (sandbox denies sockets; real HTTP unverified)\n'
else
  cat "$TEST_TMP/server.log"
  printf 'PASS 0 / FAIL 1\n'
  exit 1
fi
export AINOTE_API_URL
python3 "$ROOT/tests/helper/cases.py" "$ROOT/bin/ainote-clock"
