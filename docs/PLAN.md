# PLAN: uring-http-kit challenge program

Status: ACTIVE (2026-11-22); owner: challenge sprint
Mission: beat 310,000 users (the $12 Server Challenge rank 1) with an estate-composed
server, and land the components as reusable estate kits regardless of score.

## Doc map (recall order after compaction or restart)

1. `~/dev/src/arjaythedev/LEDGER.md` ;  session ledger: status table, decisions, evidence
2. `docs/SPEC.md` ;  normative requirements REQ-URIK-* + verification matrix (s6) + dogfood ledger (s10)
3. this file, section "Current phase" below
4. the current phase's ADRs (`docs/adr/0001..0005`)
5. `docs/FRONTIER.md` ;  50-item improvement catalog; only items with A/B evidence ship

## Bars

| Bar | Number | Source |
|---|---|---|
| Target | > 310,000 users (29,284 req/s at 82% CPU on his core) | live leaderboard |
| Ship gate (local projection) | >= 40,000 req/s local, calibration factor applied, error bars stated | SPEC REQ-URIK-P1 |
| Correctness gate | 42/42 challenge conformance, differential oracle green, Lean targets green | SPEC s6 |
| Fallback | if reader not green by submission window: wire `csrc/shim.c` and ship (ADR 0001) | ADR 0001 |

## Phase gates

| # | Phase | Entry | Exit |
|---|---|---|---|
| G0 | Calibration | ladder5 quiet window | req/s-vs-CPU line + local-to-his-box factor + error bars |
| G1 | Reader core | varint/record tests green | page.rs + wal.rs + cursor stack + pagestore compile; MappedFile unsafe audited (shm-rings pattern) |
| G2 | Oracle | G1 | query_oracle.rs (audiobook-conformance pattern): ours == rusqlite on seed + random write batches; Kani/Miri clean |
| G3 | Server wiring | G2 + uring-kit integration | 42/42 via test/run.sh; degradation ladder exercised |
| G4 | Prove | G3 | Lean targets green (varint, record, cursor-height); lake build green |
| G5 | Performance | G3 (G4 parallel) | P-levers measured (SPEC s10 + FRONTIER); adaptive scheduler A/B decided; ship gate met or FFI fallback chosen |
| G6 | Submit | G5 | install/build/start on clean Ubuntu; conformance in challenge CI green; PR opened |

## Current phase

G0 (calibration, ladder5 in flight, gated on box quiet) + G1 (reader core: page.rs first).
No cargo builds in the calibration window (AGENTS.md rule 1).

## ADR index

| ADR | Decision | Status |
|---|---|---|
| 0001 | pure-Rust mmap reader; FFI fallback | ACCEPTED |
| 0002 | backward-walk feed + invariant check + index fallback | ACCEPTED |
| 0003 | single-thread pass model; uring-kit transport (amended) | ACCEPTED |
| 0004 | writes via rusqlite; own WAL frame index snapshot protocol | ACCEPTED |
| 0005 | objective-aware adaptive pass scheduler (percentile-kit estimator) | PROPOSED |

## Iteration protocol (hard rule)

Every optimization lands with an A/B measurement on `load-calib.js` at matched conditions
(REQ-URIK-P3). Unmeasured levers do not ship. Claims are recorded in a CLAIMS.md
(blobkit pattern) with the measurement attached.

## Estate obligations

- `kit-conformance` harness pass for all three crates
- upstream contributions owed: `SEND_ZC` in uring-kit (if it wins), `decode_hs256_raw` in
  oauth-toolkit
- estate.yml registration + OmniRust-template docs-gate alignment at release


## G5 baseline (2026-11-22, confined release measurements)

Protocol: server pinned core 2, k6 confined cores 3-5, load-calib.js
(THINK_SCALE demand staircase), CPU% from /proc utime+stime deltas.

| Server | Points (rate @ CPU%) | Marginal per-request cost |
|---|---|---|
| kensac (incumbent, rank 1) | paired: 11.1k / 11.3k / 14.3k req/s | ~2x OUR THROUGHPUT |
| ours (release, pre-levers) | paired: 6.4k / 6.0k / 6.6k req/s | ~2x SLOWER |

CORRECTION (2026-11-22, E17 paired interleaved runs — the cross-run
comparison below was invalid): kensac sustains 11-14k req/s on the confined
rig where ours sustains 6-6.5k. We are at ~HALF the incumbent, not parity.
The earlier "12.3 us/req kensac" figure came from a cross-run comparison
that mixed rig states; the paired protocol supersedes it.

Root cause candidates (code-reviewed, not yet profiled): per-request
allocations throughout our pipeline (buf.clone per parse, 3 Vec clones per
feed row, JSON double-buffering, outbox cloning) vs kensac's zero-alloc
arena design. The fix is the E18/F18 zero-copy emission discipline plus a
perf profile to rank the offenders.

Rig limit: confined k6 (3 cores) saturates ~6.4k req/s; server capacity
beyond that is unmeasurable locally -> absolute number needs arjay's box
(PR #547 in the batch queue) or a second load generator.

Gotchas recorded: NEVER measure a debug build (5-20x skew, caught 2026-11-22);
confined p95/p99 are client-artifact-dominated (kensac showed 700ms-1s too);
THINK_SCALE requires /tmp/opencode/calib/load-calib.js not bench/load.js.


## Lever A/B log (E17 discipline: measured or does not ship)

| Lever | Result | Verdict |
|---|---|---|
| F23/E16 PGO (profile = 30s bench burst) | rate -10..12% at matched CPU vs plain release (4838 vs 5096 @ ~66%); 5600 vs 6380 @ ~80% | **REJECTED** — profile mismatch; revisit with a full-mix, longer profile |
| E17 paired A/B harness | adopted: THINK_SCALE staircase + /proc CPU deltas, run-to-run noise ±8% measured | baseline protocol |


## A/B run 3 (2026-11-22, box-degraded — INCONCLUSIVE)
Heavy external load (other sessions: rustc builds, docker, ML trainer) suppressed
both arms 2-3x vs their ab2 runs. Paired ratios ours/kensac: 0.73, 0.61, 0.39 —
no clean verdict possible. The ab2 dataset (quiet window) remains the reference.
Rule: definitive A/Bs only in quiet windows (the ladder gate) or on the
benchmark box itself.


## DEFINITIVE paired baseline (2026-11-23, quiet window, both release builds)

Same rig, same calib script, sequential arms, CPU% from /proc deltas:

| Scale | ours (slot-free + fixes) | kensac | ours per-req | kensac per-req |
|---|---|---|---|---|
| 30 | 6,610 @ 78.5% | 10,023 @ 9.9% | ~11.9 us | ~9.9 us |
| 60 | 6,911 @ 85.3% | 14,224 @ 13.3% | ~12.3 us | ~10.5 us |
| 150 | 7,777 @ 90.8% | 16,614 @ 15.9% | ~11.7 us | ~10.4 us |

VERDICT: kensac is ~20% more efficient per request. Supersedes ALL prior
estimates (the "parity" and "2x gap" figures were both artifacts of
contaminated or mismatched rig states).

The ~2 us/req gap decomposes (code-audit): per-request allocations (conn.buf
drain-compaction, PostFull-style intermediates in the PostGet path, jwt
Claims.username Vec), our bounds-checked page() dispatch vs their direct
cursor+page pointers, and the absence of send-zc. The lever queue (E05/E06/
SHA-NI + in-place consume) targets exactly these.

Ship bar math: <= 11.2 us/req local -> 341k projection (rank 1 outright).
With E06+E05 landing: 7-9 us/req -> 430-550k projection.


## QUIET-WINDOW paired verdict (2026-11-23)

Clean paired rounds in an open quiet window (load 3.3-5.7, no compilers),
release builds, THINK_SCALE=60 staircase, 2 interleaved rounds:

| Arm | rate |
|---|---|
| ours round 1 / round 2 | 6,556 / 5,734 req/s |
| kensac round 1 / round 2 | 8,256 / 14,175 req/s |

VERDICT: kensac holds a real ~2x throughput advantage on identical hardware.
Not a rig artifact (quiet window, paired interleaving). The slot-free recv
and emitter are correct (42/42) but the per-request pipeline carries ~2x the
cost of kensac's arena design.

The gap decomposes into (code-audit, next session):
1. buf.clone() per parse iteration (the whole accumulated request buffer)
2. PostFull intermediates in PostGet path (feed is fused; get is not)
3. format!()-built response heads (per response)
4. jwt Claims.username Vec allocation per authed request
5. gen_conn HashMap lookup + bounds-check per page touch

All five are mechanical eliminations against the documented zero-copy
discipline. Target: match kensac's ~12 us/req, then the levers (E05/E06/
SHA-NI) push past it. The leaderboard position updates with each PR push.

## Elimination-list A/B (2026-11-23)

5-point list landed (182afe2) with two gate-caught fixes (75afea4 range
panic; b8ee2b0 route-error close). 42/42 green. Paired ladder vs kensac
running in a quiet window; result appended when AB_NOW_DONE lands.


## Elimination-list A/B (2026-11-23) — RESULTS

Within-window adjacent pair (old->kensac->new, one window): old 7202/s,
NEW 8145/s = +13% throughput from the 5-point list (new ran under
equal-or-worse box conditions; lower bound). Gate: 42/42.

kensac relative numbers INVALID this session: kensac itself swung
14751/s -> 8208/s between windows (page-ins under memory pressure;
vmstat si=416 during arms). Protocol hardened: quiet gate now requires
si/so == 0 for 30s + no external process > 50% CPU + per-arm MHz log;
adjacent-arm deltas only, never cross-window.