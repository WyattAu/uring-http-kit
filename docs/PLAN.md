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
