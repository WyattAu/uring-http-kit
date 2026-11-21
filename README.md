# uring-http-kit

Single-thread io_uring HTTP/1.1 + bounds-checked SQLite B-tree/record decoding.
Built for the [arjaythedev $12 Server Challenge](https://github.com/arjaythedev/twelve-dollar-server-challenge);
usable wherever a raw, allocation-light HTTP/1.1 + SQLite read path is needed.

**Layer:** L1 substrate · **Estate deps:** zero · **Status:** draft (challenge sprint)

| crate | role |
|---|---|
| `sqlite-btree` | varint + record decoder (`no_std`, total, bounds-checked), amalgamation shim FFI |
| `uring-http` | event loop (multishot accept/recv, provided buffers), HTTP parser, JSON templates |
| `feed-server` | the five challenge endpoints (bin) |

## Proof obligations (Lean 4, `proof/`, planned)

1. `varint::decode` is total, consumes ≤ 9 bytes, agrees with SQLite's `getVarint`.
2. `record::decode_header` field offsets stay in bounds; declared sizes match.
3. HTTP parser totality: arbitrary bytes → request or error, never panic.

Executable oracles: proptest suites + differential fuzz vs the real `sqlite3`
on the challenge seed file.

## Notes

- Kernel: Ubuntu 6.8.0-136+ rejects buffer-ring registration with zeroed
  reserved words (Launchpad #2162843) — retry once with `resv[0] = 1`.
- Challenge context and benchmark calibration: `~/dev/src/arjaythedev/LEDGER.md`.
