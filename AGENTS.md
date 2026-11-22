# AGENTS.md; uring-http-kit

Single contract for this repo. Estate standards: `WyattAu/engineering-standards`;
normative rules live in `docs/SPEC.md` (tier k, status DRAFT).

## Truth table (endpoint behavior, from docs/SPEC.md section 3)

| Endpoint | Success | Error precedence | Oracle |
|---|---|---|---|
| GET /health | 200 ok/ok/uptime_s | 503 on SELECT 1 failure | handlers::health tests |
| GET /feed | 200 {"posts":[20]} | R4 invariant fallback path | query_oracle + conformance |
| GET /posts/:id | 200 {"post":...} | 400 invalid id; 404 not found | conformance |
| POST /posts | 201 | 401 rows, then 400 body rows | conformance + jwt tests |
| POST /posts/:id/like | 201 first / 200 repeat | 401 rows, 400 invalid id, 404 not found | conformance |

## Crate map

- `crates/sqlite-btree`: `no_std` decoders + page/WAL reader. Every decoder: total,
  bounds-checked, allocation-free. Panics and unwraps in non-test code are forbidden.
  Unsafe confined to mmap construction (`MappedFile`).
- `crates/uring-http`: io_uring loop, HTTP parser, JSON templates.
  `#![forbid(unsafe_op_in_unsafe_fn)]` everywhere.
- `server/`: challenge bin. Reads only SPEC env vars. Writes via rusqlite.
- `csrc/shim.c`: fallback path, unwired (ADR 0001).

## Rules

1. No `cargo` builds during benchmark calibration windows (they steal the
   pinned core; see ~/dev/src/arjaythedev/LEDGER.md for the current window).
2. Build artifacts go to the shared target: export
   `CARGO_TARGET_DIR="$HOME/.cache/cargo-target"`. Never commit a
   `.cargo/config.toml` carrying that path.
3. Proof targets in SPEC section 6 are contracts: changing a decoder signature
   invalidates the Lean obligation; update `proof/` in the same commit.
4. The differential oracle (tests vs real sqlite3) is semantic ground truth;
   Lean proves structure, the oracle proves meaning.
5. No em-dashes in any repo document (DOC-STYLE).
6. Pending estate wiring: CI rust-kit workflow, supply-chain, llms.txt refresh,
   estate.yml registration land with the first release.
