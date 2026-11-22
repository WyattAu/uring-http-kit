# FRONTIER: 50 directions past the leaderboard

Status: ACTIVE catalog (2026-11-22); governed by PLAN.md iteration protocol: an item
ships only with an A/B measurement (SPEC REQ-URIK-P3) or it is listed dead with a reason.

Legend: V = expected value (H/M/L); E = effort (H/M/L); R = rule risk (none/gray/high);
S = status (planned/lever/explorable/dead).

## A. Transport and kernel (on top of uring-kit)

| # | Item | V | E | R | S | Note |
|---|---|---|---|---|---|---|
| F01 | io_uring SEND_ZC for responses >= 1 KB, notification coalescing | H | M | none | lever P1 | kills the 4.5 KB feed kernel copy; upstream to uring-kit on win |
| F02 | provided-buffer-ring recv vs registered ReadFixed: A/B both paths | M | M | low | explorable | provided rings hit the Ubuntu resv[0] bug; ReadFixed does not |
| F03 | registered fd table (fixed files) for every socket op | M | L | none | lever | removes fd-table lookups on submit |
| F04 | DEFER_TASKRUN vs COOP_TASKRUN vs plain wait | M | L | none | explorable | wait-path cost differs per kernel |
| F05 | adaptive spin-vs-block wait: spin while CQEs pending, block when idle | M | M | none | explorable | trades idle CPU for wake latency; irrelevant at 100% CPU, wins below |
| F06 | TCP_CORK around multi-iovec feed sends; flush once | L | L | none | lever | fewer partial segments |
| F07 | IORING_OP_FUSED_CMD op chaining (kernel >= 6.6) | M | H | none | explorable | probe-gated; batch send+close style chains |
| F08 | multishot send for response bursts | L | M | none | explorable | one submit, many sends |
| F09 | fixed CQE batch drain (collect K completions before working) | M | L | none | lever | pairs with the pass scheduler; K is the scheduler knob |
| F10 | MSG_ZEROCOPY fallback path if sendzc unavailable | L | M | none | explorable | error-path handling is the cost |

## B. Storage reader (sqlite-btree)

| # | Item | V | E | R | S | Note |
|---|---|---|---|---|---|---|
| F11 | branchless interior-page binary search (LUT dispatch) | M | M | none | lever | no per-step branches on the seek path |
| F12 | fixed-width created_at compare: 3x u64 loads instead of memcmp | M | L | none | lever | 24 bytes exactly, byte-order trick per SQLite text encoding |
| F13 | SIMD varint decode (parallel prefix, Lemire-style) for record headers | M | M | none | lever | headers are 3..5 varints per record |
| F14 | SIMD escape scan + memcpy pass-through for bodies (simdjson classify style) | M | M | none | lever P5 | bodies are 99%+ escape-free ASCII (measured: avg 131 B) |
| F15 | MADV_HUGEPAGE on db/wal mappings | M | L | none | lever | TLB miss reduction; hw-kit hugepage hooks |
| F16 | MADV_WILLNEED prefetch of the predicted next leaf during like walks | M | L | none | lever | overlap prefetch with compute |
| F17 | io_uring READ for predicted-cold pages instead of fault stalls | M | H | none | explorable | keeps the loop responsive on cold seeks; post-warmup mostly moot (238 MB db fits page cache) |
| F18 | per-pass arena + size-class response recycling | M | M | none | lever P4 | malloc/free off the hot path |
| F19 | cursor stack as fixed inline array; height bound proven in Lean | L | L | none | planned | depth <= 5 by G4 theorem |
| F20 | overflow-cell support behind the R5 fallback | L | M | none | explorable | completeness insurance; unreachable on this data |
| F21 | O(new frames) WAL index maintenance + salt-reset rebase tests | M | M | none | planned | ADR 0004 protocol |
| F22 | startup prefault of the feed-tail page range | L | L | none | explorable | warm-up phase makes it near-free anyway |

## C. Codegen and CPU

| # | Item | V | E | R | S | Note |
|---|---|---|---|---|---|---|
| F23 | PGO two-phase build (profile = the bench itself on the build box) | H | M | gray | lever P2 | rule 10 says built from source on the box: a profile run inside build.sh is a build step; verify conformance accepts it |
| F24 | post-link layout (BOLT/Propeller style) on the locally built binary | M | H | gray | explorable | same rule-10 reading as F23; BOLT paper: Panchenko et al., CGO 2019 |
| F25 | codegen-units=1, fat LTO, `-C target-cpu=skylake-avx512` (pinned, not native) | M | L | none | lever | deterministic on his Xeon 8260 |
| F26 | SHA-NI: sha2 crate asm/nightly feature for HMAC | M | L | none | lever P3 | verify feature on the pinned toolchain |
| F27 | branchless route dispatch on method + path prefix bytes | L | L | none | explorable | 5 routes; match is probably already optimal |
| F28 | 64-byte-aligned connection table entries; hot structs padded | L | L | none | lever | false-sharing insurance for any future second thread |

## D. Scheduling and control

| # | Item | V | E | R | S | Note |
|---|---|---|---|---|---|---|
| F29 | objective-aware adaptive pass cap (ADR 0005) | H | M | none | proposed | the breakthrough candidate; Tail at Scale (Dean and Barroso, CACM 2013) is the theory base |
| F30 | escalation-band control for the cap (Hysteria/PBS-style step control) | M | M | none | explorable | DCTCP-style multiplicative decrease, additive increase on the cap |
| F31 | commit/parse pipelining: parse next pass while COMMIT is in flight | M | M | none | explorable | responses still wait commit (rule 6); overlap is rule-clean |
| F32 | load absorption via queue growth, never rejection | M | L | none | constraint | errors > 1% kills a run; the scheduler must prefer latency over errors |
| F33 | opportunistic checkpoint + prefetch during idle gaps | L | L | none | lever | free work when the ring is empty |
| F34 | two-timescale control: pass cap (fast) vs checkpoint threshold (slow) | M | M | none | planned | avoids controller fighting itself |
| F35 | p99-budgeted write batching window | M | M | none | explorable | likes accumulate to commit boundary bounded by tail budget |

## E. Protocol layer

| # | Item | V | E | R | S | Note |
|---|---|---|---|---|---|---|
| F36 | pre-serialized header templates with Content-Length slot patch | M | L | none | lever | one memcpy, no format call |
| F37 | Date header elision if the suite ignores it (RFC 9112 SHOULD) | L | L | none | explorable | verify against test.sh first |
| F38 | single contiguous response buffer (headers + body): one send | M | L | none | lever | fewer ring ops |
| F39 | keep-alive LRU ordering: close oldest idle first, never active | L | L | none | constraint | 15k connection budget |

## F. Algorithms and data

| # | Item | V | E | R | S | Note |
|---|---|---|---|---|---|---|
| F40 | like_count via two index seeks (lower/upper bound) instead of a walk | M | M | none | lever | O(log n) vs O(k); wins on hot posts (measured max 18 on newest 50) |
| F41 | users resolve: sort 20 ids, single descending leaf walk (leaf overlap) | M | M | none | lever | authors scatter (measured) but leaves may still overlap; measure hit rate |
| F42 | fused decode-then-encode: record bytes straight to JSON in one pass | M | M | none | lever | no intermediate field views on the feed path |
| F43 | LUT serial-type dispatch (256-entry table to handler enum) | L | L | none | lever | branchless record walking |
| F44 | likes-index tail walk for newest-post counts (feed trick reuse) | M | L | none | lever | same rightmost insight as ADR 0002, applied to likes |

## G. Verification and methods

| # | Item | V | E | R | S | Note |
|---|---|---|---|---|---|---|
| F45 | Kani bounded model checking of the HTTP parser state machine | M | M | none | planned | exhaustiveness for bounded heads; estate precedent: cbmc seen in the wild |
| F46 | Miri over the unsafe core (MappedFile + walker slices) | M | L | none | planned | catches UB the tests miss |
| F47 | SQLancer-style corpus generator for the query oracle (Rigger and Su, VLDB 2020) | M | M | none | planned | random schema-conformant mutations, disagreements reported per audiobook-conformance |
| F48 | Lean cursor-height theorem feeding F19's inline array | L | M | none | planned | proof produces the constant |
| F49 | conformance corpus as fuzz seeds (42 checks replayed as fuzz input) | L | L | none | lever | free seed corpus from the gate itself |
| F50 | ARIES-cited correctness argument for the snapshot protocol (Mohan et al., TODS 1992) | L | M | none | planned | the write-up defending ADR 0004 against review |

## References (confident citations)

- Dean, Barroso: The Tail at Scale. CACM 56(2), 2013. (F29/F30/F32)
- Langdale, Lemire: Parsing Gigabytes of JSON per Second. VLDB Journal 28(4), 2019. (F13/F14)
- Lemire, Keiser: Parsing Integers at Gigabytes per Second. Software: Practice and Experience, 2021. (F13)
- Panchenko et al.: BOLT: A Practical Binary Optimizer for Data Centers and Beyond. CGO 2019. (F24)
- Alizadeh et al.: DCTCP. SIGCOMM 2010. (control-theory analog for F30)
- Rigger, Su: SQLancer. VLDB 2020 (tool demonstration). (F47)
- Mohan et al.: ARIES. ACM TODS 17(1), 1992. (F50)
- FlexSC: Exception-Less System Calls. OSDI 2010. (philosophy behind F05/F09)
- SQLite file format: sqlite.org/fileformat2.html (the reader's normative source).

## Dead ends (explored and forbidden; do not revisit)

| Item | Why dead |
|---|---|
| AF_XDP / userspace TCP | needs CAP_BPF/CAP_SYS_ADMIN; challenge process has only CAP_NET_BIND_SERVICE |
| eBPF sockmap/sk_msg steering | same capability wall; also smells like rule 7 |
| kernel sysctl tuning (busy_poll, tcp_fastopen server, port ranges) | challenge rule 11 forbids box tuning |
| CPU frequency/cache-allocation hints | rule 11; needs root or MSR writes |
| tmpfs snapshots of hot pages / feed page cache | rule 5: in-memory table copies are named illegal |
| result dedup across passes | rule 5: query-result caches named illegal; page-cache reuse via mmap is the legal form |
| fork/COW reader processes | fork cost per pass dwarfs the budget; COW after writes breaks the single-writer snapshot model |
| gzip/br compression | optional per SPEC; pure CPU loss on a 1-core box at datacenter bandwidth |
| HTTP/2 or pipelining tricks | k6 speaks HTTP/1.1 keep-alive; no multiplexing in play |
| SQPOLL | the kernel poller thread would eat the same single core we are optimizing |
