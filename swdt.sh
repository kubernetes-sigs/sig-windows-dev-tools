#!/bin/bash
set -euo pipefail

SWDT_CLI_ROOT="./experiments/swdt"

echo "[swdt.sh] $*"

if [[ ! -f ./go.work ]]; then
    go work init "$SWDT_CLI_ROOT"
fi

start_time=$(date +%s)
if [[ "$1" == "test" ]]; then
    go test -v "$SWDT_CLI_ROOT/..."
else
    go run -buildvcs=true "$SWDT_CLI_ROOT/main.go" "$@"
fi
stop_time=$(date +%s)

printf "[swdt.sh] Run in %d seconds and exited with $? code\n" $((stop_time-start_time))
