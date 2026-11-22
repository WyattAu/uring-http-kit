# FRONTIER III: experiment status audit + new wave

Status: ACTIVE (2026-11-22). Governing rule unchanged: nothing ships without an A/B
measurement (REQ-URIK-P3). This file audits FRONTIER I/II and adds wave III.

## Audit: what is actually TESTED vs merely BUILT vs UNTOUCHED

| State | Items |
|---|---|
| Correctness-TESTED | varint decode (unit + proptest + RFC vectors); record decode (oracle catches: NULL-slot layout); HTTP parser (totality corpus); JSON prepass/writer agreement; JWT rows; reader table seek/backward walk/feed order/index count vs SQLite (synthetic oracle 12 rounds + seed seeks/feed) |
| BUILT, perf-UNMEASURED | KeyedMac midstate (P3); in-order scanner (F44 walk vs F40 seek-pair undecided); backward-walk feed (design-validated by data, perf unmeasured); JSON size prepass |
| UNTOUCHED (no running server yet) | every transport lever (sendzc F01, batching F09, DEFER_TASKRUN F04), PGO F23, SIMD F13/F14, arena F18, adaptive scheduler F29/F71, percentile-kit integration, hw-kit pinning, all calibration-dependent claims |
| BLOCKED/failed once, understood | calibration (1 clean point, factor 2.28x, needs more quiet-window points); seed oracle count case id 65219 (subagent debugging, repro in ledger) |

Honest summary: 0 of the performance levers are measured. That is not a failure of the
catalog; it is the correct order ;  the server does not exist yet (G3). Measurement
without the machine is theater.

## Wave III: new experimental concepts (problem-driven, concrete)

### Correctness/verification experiments (run before G5; cheap, high trust value)

| # | Concept | Problem | Entry criterion |
|---|---|---|---|
| E01 | Structured-random DB oracle: generate valid random SQLite files (overflow cells, deep trees, freelist pages, 500-char bodies at page boundaries) and diff reader vs rusqlite | the current oracle only proves challenge-shaped data; generality is unproven | after G2 seed-green |
| E02 | Chaos-consistency: SIGKILL mid-write-batch, reopen, compare reader vs rusqlite post-recovery | WAL recovery semantics of the snapshot protocol are untested | with E01 |
| E03 | Checkpoint-mode fuzz: PASSIVE/FULL/RESTART/TRUNCATE interleaved with reads at random moments | refresh() paths beyond TRUNCATE are untested | with E01 |
| E04 | Latency-outlier attribution: capture the slowest 1% requests' page-touch sequences during saturation, offline analysis | prefetch design (F16) is blind without outlier anatomy | needs G3 + one saturation run |

### Reader-performance experiments

| # | Concept | Problem | Expected |
|---|---|---|---|
| E05 | Startup schema-specialization: read one sample record per table at open, compile a constant-offset fast-path decoder (branch-free for the observed serial types), fall back to generic | per-field varint/serial branching on every record | 1-3 us/req on feed+post paths |
| E06 | Scatter-gather send: response = iovecs pointing INTO the mmap for body/created_at bytes + small built segments (headers, ids) ;  bodies (60%+ of feed bytes) never copied | JSON buffer memcpy of 4.5 KB per feed | 2-4 us/req |
| E07 | SIMD leaf-page prefix counting: AVX2 compare-scan of encoded post_id bytes across a leaf page for like counts | decode-per-entry on 122-entry runs | sub-us per count |
| E08 | F40-vs-F44 A/B: seek-pair count vs merged tail walk on real distributions | two designed mechanisms, no data choosing between them | decides count path |
| E09 | users-seek leaf-overlap measurement then sorted-merge walk (F41) | 20 scattered seeks per feed | only if overlap rate says so |
| E10 | madvise profiles (RANDOM/WILLNEED) on likes-index region vs default | page-cache hint cost/benefit unknown | small, cheap to test |

### Transport/scheduler/build experiments

| # | Concept | Problem |
|---|---|---|
| E11 | uring-kit BufferPool/ReadFixed vs kensac-style provided-buffer rings | first real transport comparison; kit decision |
| E12 | SEND_ZC vs WriteFixed vs send at 0.2 KB and 4.5 KB | F01/F02 concretized |
| E13 | SQE batch size vs latency curve -> runtime-picked batch (pairs with F29/F71) | syscall amortization |
| E14 | SHA-NI (sha2 asm) vs scalar HMAC on real token sizes | F26 concretized |
| E15 | itoa 2-digit LUT for id/like_count formatting | fmt overhead on 5 ints per post |
| E16 | PGO profile driven by the ACTUAL bench mix (feed/post/like weights) vs generic warmup | F23 quality |
| E17 | Paired interleaved A/B harness automation (F97) | drift-free lever decisions |
| E18 | Synteq one-shot validation: spend the free credit on a single absolute run before the PR | converts factor-estimate into a measurement |

### Wave III governance

- E01-E03 gate G5 (they are correctness, cheap, and reusable).
- E05-E10 need the oracle green first (they sit on the reader).
- E11-E18 need G3 wired.
- The catalog is CLOSED after wave III for the sprint: 124 concepts total. Further ideas
  are parked in the ledger, not the repo; building beats listing from here.
