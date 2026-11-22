# ADR 0001: Read path is a pure-Rust mmap B-tree/WAL reader

Status: ACCEPTED (2026-11-22)
Context: REQ-URIK-R1..R7; challenge rules allow any SQLite usage in-process; rule 5
explicitly blesses mmap. The leaderboard's winning entries bypass the SQL engine for
reads; the incumbent (310k users) does it through SQLite's internal C cursor API.

## Decision

Reads parse the database file and WAL directly through mmap in `sqlite-btree` (pure Rust,
`no_std` core). Writes go through `rusqlite` (bundled amalgamation). No C on the read path;
`unsafe` confined to mmap construction.

## Alternatives rejected

| Alternative | Why rejected |
|---|---|
| FFI into amalgamation internals (`csrc/shim.c`, kept unwired) | C on the hot path, worse estate fit, Lean cannot see across the boundary; kept as fallback |
| rusqlite for all reads | SQL engine tax is the leaderboard's known gap: prepared-query VDBE + value boxing on a 34 us/req budget |
| `sqlite3_blob_open` tricks | covers single columns only; feed needs index walk + counts |
| Depend on limbo/turso | full-DB compat surface we do not need; four read patterns suffice; reference, not dependency |

## Consequences

+ An estate asset: reusable read-only SQLite reader, proofable in Lean end to end.
+ Zero-copy: pages consumed in place, no C-to-Rust payload copies.
- Correctness burden (page walk, WAL chain, snapshots) moves to us; mitigated by the
  differential oracle (R3), conformance suite, and the degradation ladder (R7).
- Ship risk: if R3 is not green by the submission window, wire `csrc/shim.c` and ship that.
