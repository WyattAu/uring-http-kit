#!/usr/bin/env bash
# pgo.sh — B4 experiment: profile-guided optimization build.
# profile-generate build -> train under the calib staircase ->
# llvm-profdata merge -> profile-use rebuild.
# Requires: llvm-tools (rustup component), k6, the calib seed DB.
set -euo pipefail
CALIB=${CALIB:-$HOME/.cache/calib}
DB=${SQLITE_PATH:-$CALIB/seed.db}
PROF_DIR=$CALIB/pgo
mkdir -p "$PROF_DIR"
rm -f "$PROF_DIR"/*.profraw

command -v llvm-profdata >/dev/null || { echo "llvm-profdata missing (rustup component add llvm-tools)"; exit 1; }
command -v k6 >/dev/null || { echo "k6 missing"; exit 1; }
[ -f "$DB" ] || { echo "seed DB missing at $DB"; exit 1; }

echo "== profile-generate build =="
RUSTFLAGS="-Cprofile-generate=$PROF_DIR" cargo build --release -p feed-server
SRV=${CARGO_TARGET_DIR:-$HOME/.cache/cargo-target}/release/feed-server

SQLITE_PATH="$DB" JWT_SECRET=calib-secret HOST=127.0.0.1 PORT=8080 taskset -c 2 "$SRV" &
SRV_PID=$!
sleep 2
curl -sf http://127.0.0.1:8080/health >/dev/null || { echo "server not healthy"; kill $SRV_PID; exit 1; }

echo "== training run (staircase) =="
taskset -c 3-5 k6 run --quiet "$CALIB/load-calib.js" > /dev/null 2>&1 || true
kill $SRV_PID 2>/dev/null || true
wait $SRV_PID 2>/dev/null || true

echo "== merge + profile-use rebuild =="
llvm-profdata merge -o "$PROF_DIR/pgo.profdata" "$PROF_DIR"/*.profraw
RUSTFLAGS="-Cprofile-use=$PROF_DIR/pgo.profdata" cargo build --release -p feed-server
echo "PGO binary at target/release/feed-server (baseline binary kept at $CALIB/server-baseline)"
