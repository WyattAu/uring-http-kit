# ADR 0004: Writes via rusqlite; reader/writer snapshot protocol

Status: ACCEPTED (2026-11-22)
Context: REQ-URIK-R6, C3; the seed is WAL mode; challenge rule 6 requires commit-before-
response; writes on the fixed schema include posts inserts and likes upserts plus their
index updates.

## Decision

All writes run through `rusqlite` (bundled SQLite 3.54.x) on one connection opened at
startup with `synchronous=NORMAL`, `wal_autocheckpoint=0`, `temp_store=MEMORY`. The reader
does not write. Coordination protocol on the loop thread:

1. At pass start, snapshot `N` = current WAL frame count (tracked incrementally: after each
   rusqlite commit, scan the appended frames' 24-byte headers, verify salt + checksum
   chain, extend the pgno -> frame index).
2. Reads use `page(n, N)`: newest frame for `n` at index <= N, else the db-file page.
3. Writes bind + step through prepared statements inside one rusqlite transaction;
   `COMMIT` returns, then responses go out.
4. Checkpoints (TRUNCATE) run between passes when frames exceed a threshold or the WAL mmap
   grows past its bound; after a successful truncate the frame index re-bases to zero and
   the db-file mmap is re-sized (file grew).

## Alternatives rejected

| Alternative | Why rejected |
|---|---|
| Pure-Rust writer (btree splits, WAL commit protocol) | writing SQLite correctly is far harder than reading; rusqlite is explicitly legal; risk belongs on the read side where it pays |
| Parse -shm wal-index for snapshots | we are the only writer; own commit counter is simpler and exact |
| Checkpoint from a second connection | same process, no benefit; loop-thread checkpoints keep one moving part |

## Consequences

+ Writes are SQLite-native: durability, group commit, and index maintenance are delegated
  and correct by construction.
+ Frame scanning is incremental and cheap (only new frames, checksum chain verified).
- The reader must re-base cleanly after truncate; wal.rs owns that state machine and its
  tests cover salt reset + remap.
