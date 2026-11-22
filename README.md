# uring-http-kit

Single-thread io_uring HTTP/1.1 + pure-Rust read-only SQLite reader (mmap B-tree + WAL).
Built for the [arjaythedev $12 Server Challenge](https://github.com/arjaythedev/twelve-dollar-server-challenge);
usable wherever a raw, allocation-light HTTP/1.1 + SQLite read path is needed.

Layer: L1 substrate; Estate deps: zero; Status: DRAFT (challenge sprint).

| crate | role |
|---|---|
| `sqlite-btree` | varint + record decoders (`no_std`, total, bounds-checked); page/WAL reader; cursor walks |
| `uring-http` | HTTP parser, router, JSON templates, pass scheduler (event loop comes from `uring-kit`) |
| `feed-server` | the five challenge endpoints (bin); writes via rusqlite |

Estate dependencies (dogfooded): `uring-kit` (transport), `percentile-kit` (latency
estimator + bench budget gates), `hw-kit` (core pinning). Full ledger: `docs/SPEC.md` s10.

Normative rules: `docs/SPEC.md` (REQ-URIK-*). Decisions: `docs/adr/0001..0004`.
Verification matrix: SPEC section 6 (Lean targets, proptest, differential query oracle,
challenge conformance suite, bench ladder).
