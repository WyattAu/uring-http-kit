#!/usr/bin/env bash
# ab-ladder.sh — the ring-flag A/B ladder (A2/A3 experiments).
# Runs baseline vs URING_COOP/DEFER/ISSUER variants under the calib
# staircase, one run per variant, interleaved once (paired protocol).
# Claims land in CLAIMS.md format; ship only on quiet-window wins.
# THIS IS NOT THE SHIP MEASUREMENT — arjay's box is the instrument.
set -u
CALIB=${CALIB:-$HOME/.cache/calib}
DB=$CALIB/seed.db
OUT=$CALIB/ab-results
mkdir -p "$OUT"
[ -f "$DB" ] || { echo "seed DB missing at $DB"; exit 1; }
command -v k6 >/dev/null || { echo "k6 missing"; exit 1; }
SRV=${CARGO_TARGET_DIR:-$HOME/.cache/cargo-target}/release/feed-server
[ -x "$SRV" ] || { echo "release server missing"; exit 1; }

# quiet-window gate: load < 6 AND no swap delta over 3s
LOAD=$(cut -d' ' -f1 /proc/loadavg)
S1=$(awk '/pswpin/{print $2}' /proc/vmstat); sleep 3
S2=$(awk '/pswpin/{print $2}' /proc/vmstat)
if (( ${LOAD%%.*} > 6 )) || (( S2 > S1 )); then
  echo "WINDOW CLOSED: load=$LOAD swap_delta=$((S2 - S1)) — rerun when quiet"
  exit 2
fi
echo "window open: load=$LOAD"

run_variant () {
  local name=$1; shift
  local envs=("$@")
  env "${envs[@]}" SQLITE_PATH="$DB" JWT_SECRET=calib-secret HOST=127.0.0.1 PORT=8080 \
    taskset -c 2 "$SRV" & local pid=$!
  sleep 2
  curl -sf http://127.0.0.1:8080/health >/dev/null || { echo "$name: server dead"; kill $pid; return 1; }
  # CPU% from /proc utime+stime delta across the run
  local u0 s0
  read -r u0 s0 <<< "$(awk '{print $14, $15}' /proc/$pid/stat)"
  taskset -c 3-5 k6 run --quiet "$CALIB/load-calib.js" > "$OUT/$name.json" 2>&1
  local u1 s1
  read -r u1 s1 <<< "$(awk '{print $14, $15}' /proc/$pid/stat)"
  local ticks=$(( (u1 + s1) - (u0 + s0) ))
  local rate
  rate=$(grep -o '"iteration_duration[^,]*' "$OUT/$name.json" | head -1)
  local reqs
  reqs=$(python3 -c "
import json,sys
try:
    d=json.load(open('$OUT/$name.json'))
    m=d.get('metrics',{})
    its=m.get('iterations',{})
    print(round(its.get('count',0)/60,1))
except Exception: print('?')
")
  echo "$name: ${reqs} iter/s cpu_ticks=$ticks" >> "$OUT/summary.txt"
  kill $pid 2>/dev/null
  wait $pid 2>/dev/null
  echo "$name done: $reqs iter/s cpu=$ticks ticks"
}

: > "$OUT/summary.txt"
# paired interleave: A,B,A,B halves the rig-state bias (E17 protocol)
run_variant base   URING_COOP=0
run_variant coop   URING_COOP=1 URING_DEFER=1
run_variant base2  URING_COOP=0
run_variant coop2  URING_COOP=1 URING_DEFER=1
run_variant issuer URING_COOP=1 URING_DEFER=1 URING_ISSUER=1
echo "== summary =="
cat "$OUT/summary.txt"
