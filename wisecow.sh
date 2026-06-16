#!/usr/bin/env bash
set -euo pipefail

SRVPORT="${SRVPORT:-4499}"
RSPFILE="/tmp/wisecow-response"

rm -f "$RSPFILE"
mkfifo "$RSPFILE"

get_api() {
  read -r line || true
  echo "$line"
}

handle_request() {
  get_api >/dev/null
  mod="$(fortune)"

  cat <<EOF > "$RSPFILE"
HTTP/1.1 200 OK
Content-Type: text/plain; charset=utf-8
Connection: close

$(cowsay "$mod")
EOF
}

prerequisites() {
  command -v cowsay >/dev/null 2>&1 &&
    command -v fortune >/dev/null 2>&1 &&
    command -v nc >/dev/null 2>&1 || {
      echo "Install prerequisites: cowsay, fortune, netcat."
      exit 1
    }
}

main() {
  prerequisites
  echo "Wisdom served on port=${SRVPORT}..."

  while true; do
    cat "$RSPFILE" | nc -l -p "$SRVPORT" -q 1 | handle_request
    sleep 0.01
  done
}

main
