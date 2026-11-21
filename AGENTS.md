# AGENTS.md — uring-http-kit

Single contract for this repo. Estate standards: `WyattAu/engineering-standards`.

## Crate map

- `crates/sqlite-btree` — `no_std` decoders. Every decoder: total, bounds-checked,
  allocation-free. Panics and unwraps in non-test code are forbidden.
- `crates/uring-http` — io_uring loop, HTTP parser, JSON templates. Unsafe is
  confined to FFI shims; `#![forbid(unsafe_op_in_unsafe_fn)]` everywhere.
- `server/` — challenge bin. Reads only SPEC env vars.

## Rules

1. No `cargo` builds during benchmark calibration windows (they steal the
   pinned core; see ~/dev/src/arjaythedev/LEDGER.md for the current window).
2. Build artifacts go to the shared target: export
   `CARGO_TARGET_DIR="$HOME/.cache/cargo-target"`. Never commit a
   `.cargo/config.toml` carrying that path.
3. Proof targets listed in README are contracts: changing a decoder signature
   invalidates the Lean obligation — update `proof/` in the same commit.
4. Differential oracle (tests vs real sqlite3) is the semantic ground truth;
   Lean proves structure, the oracle proves meaning.
5. Pending estate wiring: REQUIREMENTS/SECURITY/THREAT-MODEL/supply-chain/CI
   rust-kit workflow + estate.yml registration land with the first real release.
