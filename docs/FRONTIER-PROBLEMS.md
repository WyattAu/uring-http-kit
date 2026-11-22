# FRONTIER II: 50 problem-driven mechanisms (51..100)

Status: ACTIVE (2026-11-22). Companion to FRONTIER.md (directions); this file is
mechanisms, each anchored to a concrete problem the program actually has. Same rule:
ships only with an A/B measurement (SPEC REQ-URIK-P3). Cross-references are F-indices.

## S1. The fd wall at 310k users (ADR 0006)

| # | Mechanism | Problem it solves | Note |
|---|---|---|---|
| F51 | fd-budget controller: idle keep-alive timeout driven by fd count (65s -> 0.5s as fds approach 45k) | 310k VUs >> 65,535 LimitNOFILE | the enabling decision for direct mode past 15k users |
| F52 | server-first close after every response (immediate FIN, no linger) | TIME_WAIT must land on k6's side, not ours (ours costs kernel memory for 60s at ~29k closes/s) | Content-Length makes end unambiguous |
| F53 | accept-multishot re-arm depth tuned to reconnect rate | at churn, accept becomes a per-request cost | measure accept path us separately |
| F54 | listen backlog 65535 (process choice; somaxconn sysctl is untouchable) | reconnect storms during ramp phases | capped by somaxconn in practice |
| F55 | fd watchdog: at 50k fds shed idle conns only, never active | process death = lost run | metric + stderr journal |

## S2. GET /feed cost structure (hot path ~50% of requests)

| # | Mechanism | Problem | Note |
|---|---|---|---|
| F56 | per-pass descent-path reuse for users seeks | 20 seeks x ~3 interior touches each | same pass = same snapshot = paths valid for the pass only |
| F57 | sort 20 user_ids ascending, walk users leaves with overlap detection | consecutive ids often share a leaf | hit rate measured before keeping (F41) |
| F58 | within-pass feed decode memoization | two feeds in one pass see the identical snapshot | legal: same semantics as page-cache reuse; never across passes |
| F59 | prebuilt feed response skeleton (headers + {"posts":[ + ]}) | constant regions rebuilt per response | one memcpy into arena slot |
| F60 | like_count seek-pair with walk fallback | walk O(k) vs seeks O(log n) | measured k: avg 4.35, max 18 on newest 50; threshold from data |
| F61 | feed-head id range tracks like-tail walk bounds | avoids a separate index seek for counts | same rightmost insight as ADR 0002 |
| F62 | created_at bytes emitted straight from record view | no copy between decode and write | fused writer (F42) |
| F63 | skip GET-side body validation entirely | stored bodies passed CHECK constraints at insert | SPEC guarantees; trust the store |

## S3. Authed endpoints (POST /posts, POST like)

| # | Mechanism | Problem | Note |
|---|---|---|---|
| F64 | JWT header fast-path: constant compare against the seed tokens' shared header before decode | 3 base64 decodes per authed request | fallback to full decode on mismatch |
| F65 | payload single-scan extractor in expected key order | serde-free claims parse | SPEC-scoped; seed tokens are flat |
| F66 | KeyedMac clone cost measured vs fresh init | midstate reuse (P3) must prove itself | hmac crate clone = state copy |
| F67 | body validation in one scan: trim bounds + length + JSON shape | 3 scans on the create path | <=512B fast path covers all real traffic |
| F68 | like existence seek fused into the likes-tail walk when post_id >= feed-head min | separate seek per like | same leaf region |
| F69 | rusqlite raw bind (no IntoParams allocation) on prepared INSERT RETURNING | allocation on write path | prepared once at startup |
| F70 | 201 vs 200 decision from execute() rows-changed | sqlite3_changes equivalent | kensac's proven trick, rusqlite-native |

## S4. The pass engine

| # | Mechanism | Problem | Note |
|---|---|---|---|
| F71 | pass cap = CQE drain count K, swept over {8..256} | batching vs latency knob | concrete form of ADR 0005 |
| F72 | ring sizing SQ 4096 / CQ 8192 + overflow watchdog | CQE overflow = lost completions = hung connections | logged, never silent |
| F73 | idle-close timeout wheel (1s buckets, no per-conn timers) | 15k+ conns need cheap timeouts | F51's mechanism |
| F74 | commit-duration p99 per pass measured | responses block on COMMIT; must stay under budget | rusqlite txn timing |
| F75 | commit/parse overlap: parse queued requests while COMMIT is in flight | commit is kernel-side memcpy at NORMAL | rule 6 kept: responses after commit |
| F76 | arena reset by bump pointer (no memset) | free() traffic off the hot path | F18 concrete |

## S5. Conformance exactness (42 checks)

| # | Mechanism | Problem | Note |
|---|---|---|---|
| F77 | 10 error responses as precomputed byte strings + status lines | exact bytes demanded | zero formatting on error path |
| F78 | auth-before-id precedence encoded in router order | SPEC precedence is normative | testable per row |
| F79 | "like counted at once (12)" as a named oracle case | suite expects exact count on a seeded post | post id discovered offline, added to corpus |
| F80 | 400-vs-404-vs-401 precedence tests on POST /posts/abc/like | with token: 400; without: 401 | router unit tests |
| F81 | unknown-path 404 for every method, forever | /metrics would fail conformance | no extra endpoints, ever; metrics via stderr journal only |
| F82 | trailing-newline tolerance on JSON bodies | SPEC allows; suite may send both | parser accepts and ignores |
| F83 | created_at echo conformance from INSERT RETURNING bytes | stored format must round-trip byte-exact | oracle case |

## S6. Box realities (2 GB, no swap, Ubuntu 24.04, systemd)

| # | Mechanism | Problem | Note |
|---|---|---|---|
| F84 | error-only logging | journald writes cost CPU on the box | no per-request logging, ever |
| F85 | RSS watchdog with arena + mmap anon budget <= 256 MB | OOM on a no-swap box = dead process | shed idle conns before kernel acts |
| F86 | MALLOC_ARENA_MAX=1 in start.sh env | glibc arena overhead single-threaded | process-internal, legal |
| F87 | heap THP default check; mmap hugepages via F15 only | THP regressions are real in the literature | measure, do not assume |
| F88 | hw-kit pinning of loop thread on the calibration box | noise isolation locally | no-op on his 1-vCPU box, keep for symmetry |
| F89 | zero libc time calls on the request path | created_at is DB bytes; uptime_s once per call | clock_gettime per pass only |
| F90 | fd inventory budget: sockets + 3 files + rings | 65535 must cover churn peak | ties to F51 |

## S7. Measurement discipline (the program's own calibration)

| # | Mechanism | Problem | Note |
|---|---|---|---|
| F91 | ladder knee refinement: 100-user steps after doubling | his protocol is coarse near the knee | local mirror for tighter curves |
| F92 | bimodality noise guard: median/mean divergence > 3x aborts a stage | contaminated stages look like real data (our v2/v3 lesson) | concrete detector in ladder |
| F93 | k6 CPU% capture per stage; discard load-gen-limited stages | his rule applied locally | we measured k6 limit at 25k VUs |
| F94 | server-side per-pass timing histogram (percentile-kit) to stderr | latency attribution without endpoints | /metrics is forbidden (F81) |
| F95 | calibration ledger format: factor + error bars + state markers | recall without re-derivation | AGENTSPEAK-style |
| F96 | build anytime, bench in gaps | quiet windows are scarce; builds are not | decouples G1-G4 from G0/G5 |
| F97 | paired interleaved A/B runs (A/B/A/B) | drift cancels between arms | harness flag |

## S8. Submission and review

| # | Mechanism | Problem | Note |
|---|---|---|---|
| F98 | toolchain pin via official tarball + sha256 in install.sh | clean-box build must be boring | kensac's proven pattern |
| F99 | README optimization notes cite proofs + CLAIMS entries | arjay reads these; review quality is real | evidence-backed claims only |
| F100 | local pre-flight of test/run.sh in an Ubuntu 24.04 container | catches install.sh gaps before the queue | docker available on the fleet |

## Overlap note

Items 60, 61, 62, 68, 71, 75 concretize F40, F44, F42, F09, F31 respectively; where both
exist, the mechanism here is the implementable form and FRONTIER.md carries the direction.
