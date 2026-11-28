# CLAIMS

## CL-001: 97.9% of hot-path instructions live in FOUR btree-decode functions (2026-11-27)

Instrument: in-process ranking driver (server/tests → handlers::ranking::ranking_driver,
1000 iterations of feed_emit(25) + post_get + parse) under callgrind,
3.83B Ir total. Diagnostic-grade (not an A/B): ranking only.

| Function | Ir share |
|---|---|
| sqlite_btree::record::decode_header | 36.10% |
| IndexScan::key_of | 18.96% |
| sqlite_btree::varint::decode | 18.09% |
| IndexScan::count_prefix | 14.46% |
| IndexScan::cell_entry_raw | 9.31% |
| uring_http::json::write_escaped | 0.61% |
| Cursor::table_seek | 0.53% |

READING: the cost is NOT in JSON emission or HTTP parsing (noise-level).
It is the record/index DECODE layer — varint-by-varint header parsing
per row, and the per-row LIKE-index walk (key_of + count_prefix = 33%).

FIX CLASS (pre-registered, measured before ship):
1. varint 1-byte fast path inlined into decode_header (54% combined
   share sits behind varint decode call overhead + bounds checks)
2. IndexScan batch walk: one sorted range scan collecting the feed's
   like-counts, replacing 25 independent walks per feed emit
3. posts schema is fixed — a specialized decode for the known
   serial-type sequence (validate once, then fixed offsets)

## CL-001a: varint 1-byte fast path = −16.7% total Ir (2026-11-27)

MEASURED (callgrind driver, same flags both sides — attribution clean):
- old decode_header: 3,833,775,847 Ir
- new (inline 1-byte varint in header-size + serial-type positions):
  3,193,456,574 Ir
- delta: −640M Ir (−16.7% of total workload instructions)
- compile-flag ladder contribution to this driver: ~0 (3,833,775,847
  under new flags matches 3,833,776,175 under old flags)
- oracle re-run GREEN (query_oracle + varint_oracle + unit tests) AFTER
  the fix, per the CL-001 gate
CAVEAT: cargo's dep-binary HASH does not track source content — two
builds shared hash 6419a63 while differing in Ir by 640M. Measure by
mtime + behavior, never by hash.
NEXT (CL-001b, spec'd): IndexScan batch walk — feed ids are a
consecutive descending window; one forward scan from
lower_bound(min_id) counting into a (max-min+1)-slot vector replaces
25 independent walks. Targets the 51% IndexScan class.

## CL-001b: IndexScan batch walk = −89.4% total Ir (2026-11-27)

MEASURED (same driver, same flags): 3,193,456,574 -> 337,556,628 Ir.
One sequential index scan (single B-tree descent + sequential advance,
counting into a slot vector) replaces 25 independent root-to-leaf
walks per feed. IndexScan class: 51% -> ~23% of a 9.5x-smaller total.
Oracle re-run GREEN after the rewiring (query_oracle + varint + all
feed-server tests). decode_header now 25.3% of the remainder.
CUMULATIVE CL-001 program: 3.834B -> 337.6M Ir = -91.2% (11.4x).
HONEST CAVEAT: the driver measures the decode layer in isolation; the
real server's wall now shifts to transport/syscalls. arjay's box
remains the instrument (paired A/B on his harness is the ship gate).
NEXT: re-profile the full server under load to find the NEW top —
the decode layer is no longer it.

## CL-001c: io_uring_enter = 88.4% of syscall time, 37% error rate (2026-11-28)

Instrument: full server under strace -c -f (ancestor tracing), k6
burst, diagnostic-grade (box load 14-17, client SIGKILLed at end —
counts are partial but the signal is unmistakable).

| syscall | % time | calls | errors |
|---|---|---|---|
| io_uring_enter | 88.38% | 5,271 | 1,972 |
| mmap | 2.36% | 405 | |
| statx | 2.22% | 746 | |
| openat | 2.11% | 385 | |

FINDINGS:
1. io_uring_enter dominates with a 37% error rate (1,972/5,271) —
   the pass loop's enter pattern wastes ~1.2 syscalls/iteration on
   enters that return without completions. Fix class: adaptive enter
   policy (block when no work in flight, skip when completions are
   pending) + DEFER_TASKRUN/COOP_TASKRUN (env-ready, URING_DEFER=1).
2. NEW: the snapshot refresh costs 2-3 syscalls/request (statx on the
   WAL path + WalIndex::open's openat+read of the header). Fix class:
   cache the WAL fd at Reopen; fstat(fd) + header pread on the cached
   fd. Rule-5-correct (the check still happens every request — only
   the mechanics get cheaper).
3. Decode layer confirmed out of the way (CL-001b's -91.2% holds).

## CL-001c-fix: WAL refresh syscalls eliminated per request (2026-11-28)

Fix shipped: (a) None-branch size gate — skip WalIndex::open while the
WAL is smaller than a header (was: openat+mmap+munmap of the empty WAL
EVERY pass); (b) Some-branch fstat on the cached fd instead of a path
statx walk. Rule-5-correct: the freshness check still runs every
refresh — only the mechanics got cheaper.
MEASURED (strace, 40 requests): openat 385 -> 10 (startup-only);
statx 746 -> 82 (~1/refresh, the gate itself). io_uring_enter remains
dominant (792 calls, 196 errors, 66%) — the adaptive enter policy is
the next fix (CL-001d), spec: block-when-idle, skip-when-pending.
Oracle re-run GREEN after the fix (sqlite-btree 5+1+3, feed-server 3+15).

## CL-001d: adaptive enter policy = −48% enters, zero no-ops (2026-11-28)

MEASURED (20-request strace, same protocol as baseline): enters
398 -> 206 (-48%); provably-no-op enter(0,0,0) flushes: many -> 0.
Remaining errors (90 ETIME) are the idle-pass 250ms heartbeat —
correct and required. Fix: poll flushes only when SQEs are pending
and waits only when the CQ ring is empty (uring-kit b67bb9f).
Combined CL-001 program effect: decode -91.2% Ir, WAL refresh cycle
eliminated, transport enters -48%. NEXT WALL (post-profiling):
whatever the full-server strace shows now — likely the pass cadence
itself (ADR 0005 adaptive scheduler) or multishot recv.
