# SPEC: uring-http-kit

Status: DRAFT (challenge sprint, pre-submission)
Tier: k (library kit) with an application crate carrying normative endpoint rules
Citations: `challenge` = arjaythedev/twelve-dollar-server-challenge @ main (SPEC.md, schema.sql, bench/load.js, test/test.sh)

## 1. Scope

One server process serves five JSON endpoints over HTTP/1.1 keep-alive from a fixed SQLite
database file, on one CPU core, maximizing concurrent virtual users held under the challenge
bench (citation: challenge/bench/load.js; scoring: challenge/README.md).

Out of scope: TLS; HTTP/2; multi-node; any schema change; any kernel or box tuning
(challenge/README.md rule 11).

## 2. Environment requirements

| REQ | Statement | Enforcement |
|---|---|---|
| REQ-URIK-E1 | Process reads config only from `SQLITE_PATH`, `JWT_SECRET`, `HOST`, `PORT` (challenge/SPEC.md runtime contract) | `server/src/config.rs` tests |
| REQ-URIK-E2 | Direct mode: listen on `HOST:PORT`, tolerate up to 15,000 keep-alive connections; `LimitNOFILE=65535` is the fd budget (challenge/SPEC.md) | bench ladder at 15k+ conns passes |
| REQ-URIK-E3 | Healthy `/health` within 60 s of start (challenge/README.md rule 10) | `test/run.sh` gate |
| REQ-URIK-E4 | Built from source on the box by `install.sh` + `build.sh`; no prebuilt binaries; deps pinned (challenge/README.md rule 10) | CI + challenge CI |

## 3. Functional requirements

Error bodies are exactly `{"error":"<message>"}`; auth precedes id validation on authenticated
routes (challenge/SPEC.md). Key order and shapes are exactly as the SPEC shows.

| REQ | Endpoint | Contract | Enforcement |
|---|---|---|---|
| REQ-URIK-F1 | `GET /health` | 200 `{"status":"ok","db":"ok","uptime_s":N}` after a successful `SELECT 1`; 503 degraded on failure | challenge test checks; `handlers::health` tests |
| REQ-URIK-F2 | `GET /feed` | 200 `{"posts":[20 posts]}`, newest first by `(created_at DESC, id DESC)` | challenge test "feed has 20 posts", "new post is at the top", "feed entry matches the post" |
| REQ-URIK-F3 | `GET /posts/:id` | 200 `{"post":...}`; 404 `post not found`; 400 `invalid post id` for non-positive-integers (`0`, `-1`, `abc`, `1.5`) | challenge test group "read back" |
| REQ-URIK-F4 | `POST /posts` | auth then: 400 `malformed JSON body` / `body is required` / `body must be at most 500 characters`; 201 `{"post":{...}}` with trimmed body, `like_count:0`, author = token username | challenge test group "create" |
| REQ-URIK-F5 | `POST /posts/:id/like` | auth then id then existence; 201 first like, 200 repeat, 404 `post not found` | challenge test group "like" |

Auth error rows, in precedence order (challenge/SPEC.md errors table):

| Condition | Status | Message | Enforcement |
|---|---|---|---|
| no `Authorization`, or not `Bearer ` prefixed | 401 | `missing bearer token` | `jwt::verify` unit tests |
| bad signature, expired, non-HS256, malformed | 401 | `invalid or expired token` | `jwt::verify` unit tests (tamper, expire, alg rows) |
| valid sig, `sub` not positive int, or `username` absent | 401 | `invalid token payload` | `jwt::verify` unit tests (payload rows) |

## 4. Database access requirements

The reader (crate `sqlite-btree`) reads the database file and WAL directly via mmap and must
agree with SQLite on the fixed schema. Writes go through the bundled SQLite via `rusqlite`.

| REQ | Statement | Enforcement |
|---|---|---|
| REQ-URIK-R1 | Varint decode: total, consumes <= 9 bytes, agrees with SQLite `getVarint` on every input | Lean `proof/Varint.lean` targets 1..3; proptest `varint_oracle.rs`; RFC 4648 vectors |
| REQ-URIK-R2 | Record header decode: field offsets stay within the payload; declared sizes agree; serial types 10/11 rejected | Lean targets (record section); differential suite |
| REQ-URIK-R3 | Table seek by rowid, rightmost-descent, forward and backward cursor walks, index prefix count: results identical to SQLite's answers on the same snapshot | differential suite `tests/query_oracle.rs`: after random rusqlite write batches, the four canonical read patterns over random arguments must equal rusqlite's answers |
| REQ-URIK-R4 | Feed order equivalence: for inserts where `created_at` defaults to insert time, rowid order equals `(created_at, id)` order; the server checks the invariant at runtime and falls back to the index walk on any violation | ADR 0002; runtime check in `handlers::feed`; fallback covered by R3 path |
| REQ-URIK-R5 | Overflow cells: reader returns `Unsupported` and the request falls back to the bundled-SQLite path (bodies <= 500 B make overflow unreachable on this schema; assertion, not assumption) | differential suite includes a >4 KiB body case; fallback path tested |
| REQ-URIK-R6 | WAL snapshot protocol: a pass reads one frame snapshot `N`; `page(n, N)` = latest frame for `n` at index `<= N`, else db-file page; frames chain-verified incrementally; salts reset on checkpoint re-base the index | `wal.rs` unit tests; differential suite snapshot cases |
| REQ-URIK-R7 | Any reader error degrades that request (then that pass) to the bundled-SQLite path; the server never returns wrong data and never exits on reader faults | fallback tests; handler error mapping |

## 5. Concurrency and durability requirements

| REQ | Statement | Enforcement |
|---|---|---|
| REQ-URIK-C1 | No caching of request data across requests: every response's data is read from the database in the pass that serves it (challenge rule 5). Precomputed constants allowed: HTTP header templates, HMAC key midstates, page/buffer pools | code review gate + conformance |
| REQ-URIK-C2 | Writes are durable before their response: a pass's writes commit (rusqlite `COMMIT`) before that pass's responses are sent (challenge rule 6, group commit form) | conformance "created_at is now" and read-back checks |
| REQ-URIK-C3 | WAL mode with `synchronous=NORMAL` or stronger; autocheckpoint disabled; checkpoints run on the loop thread between passes, TRUNCATE mode, so the WAL mmap stays bounded | `store.rs` startup pragma tests |
| REQ-URIK-C4 | Single-threaded request work; no locks on the hot path; io_uring `DEFER_TASKRUN` + multishot accept/recv + provided buffer rings; send via `SEND_ZC` with `send` fallback (ADR 0003) | bench ladder; kernel-feature probe test |

## 6. Performance requirements (targets with a bench oracle)

| REQ | Target | Oracle |
|---|---|---|
| REQ-URIK-P1 | Projected score > 310,000 users on the challenge box; ship bar: local confined-ladder projection >= 40,000 req/s with the calibration factor applied | `bench/` ladder protocol + calibration ledger entry |
| REQ-URIK-P2 | p95 < 500 ms, p99 < 1 s, errors < 1% at the projected maximum (5-minute hold) | challenge `bench/load.js` |
| REQ-URIK-P3 | Every optimization lever lands with an A/B measurement on `load-calib.js`; unmeasured levers do not ship | ledger A/B table |

## 7. Failure modes

| Failure | Behavior |
|---|---|
| reader returns `Unsupported` (overflow cell, layout drift) | request-level fallback to bundled-SQLite path; hot path unaffected |
| WAL anomaly (salt mismatch, chain break) | pass-level fallback: all reads via bundled SQLite; log once |
| fd pressure | idle keep-alive close (300 s cap); active connections never closed |
| panic on request path | forbidden by construction (total parsers, no unwrap on request path); loop panic = process exit, systemd restart |
| memory | mmap pages are reclaimable; arena capped; anon budget <= 256 MB |

## 8. Packaging

`install.sh`: Ubuntu 24.04 build-essential, curl, pinned Rust toolchain tarball (sha256-verified).
`build.sh`: `cargo build --release --locked` with pinned `Cargo.lock`; vendored amalgamation
sha256-checked (rusqlite bundled); optional `PGO=1` two-phase profile build (ADR 0001 consequences).
`start.sh`: exec the binary in the foreground, env-only config.

## 9. Open questions

| # | Question | Resolution path |
|---|---|---|
| Q1 | Pass cadence: event-immediate vs fixed vs adaptive cap (ADR 0005) | A/B on load-calib.js (P3 protocol) |
| Q2 | sendzc vs send crossover point by response size | A/B at 0.2 KB and 4.5 KB responses |
| Q3 | Calibration factor error bars (local confined vs challenge box) | ladder5 result + sensitivity note in ledger |
| Q4 | Checkpoint cadence vs WAL mmap growth | frame-threshold sweep in bench |

## 10. Estate dogfood ledger

Sweep v1 (2026-11-22) covered the local dev tree only (228 repos). Sweep v2 (same day)
reconciled against GitHub (311 repos authenticated, 276 public): 98 repos were missing
locally, including the transport and measurement layers below. Local clones added:
uring-kit, hw-kit, percentile-kit, kit-conformance, metrics-kit, OmniRust-template.

| Estate asset | Outcome | Note |
|---|---|---|
| `uring-kit` | **adopted as dependency** | UringEngine + BufferPool (registered ReadFixed/WriteFixed, zero-malloc hot path) + probe + net helpers replace the planned hand-written loop_.rs; provided-buffer-ring design dropped (registered buffers sidestep the Ubuntu resv[0] bug); SEND_ZC absent from its surface: our P1 lever, contribute upstream if it wins |
| `percentile-kit` | **adopted as dependency** | lock-free sliding-window p50/p95/p99 = the adaptive scheduler's estimator (ADR 0005); percentile-budgets.toml gates the bench ladder |
| `hw-kit` | **adopted as dependency** | core pinning for bench confinement and the loop thread (process-internal, rule-11 legal); mmap/mbind hooks for pagestore |
| `kit-conformance` | **obligation** | shared harness the crates must pass (forbid(unsafe_code) policy per its rules; sqlite-btree's mmap unsafe scoped and justified) |
| `metrics-kit` | candidate | lock-free counters for fallback/pass-length metrics; adopt at handlers stage |
| OmniRust-template | pending alignment | repo scaffolding predates discovery; align docs-gate artifacts with the template at release |
| `oauth-toolkit` (jwt/crypto) | lineage + primitives | HS256 contract and test cases mirrored; hot path uses a specialized zero-copy parser (serde decode_hs256 costs ~2-4 us/authed request); upstream `decode_hs256_raw` contribution filed as follow-up |
| `hmac` + `base64` crates (as used by oauth-toolkit) | adopted | hand-rolled HMAC/base64 removed; `hmac` clonable MAC state = midstate-reuse lever (P3) |
| `errcode` (http-error successor) | rejected | maps Validation to 422; SPEC mandates 400 with exact challenge strings (exact bytes win) |
| `audiobook-conformance` | pattern adopted | corpus + independent-reference + disagreement-report structure for `tests/query_oracle.rs` |
| `wire-kit`, `dbc-parse` | discipline adopted | bounds-checked, total, zero-dep, `no_std` decode style |
| `shm-rings` | pattern adopted | THREAT-MODEL treatment for the inherent-unsafe mmap surface (`MappedFile`) |
| `blobkit` | pattern adopted | CLAIMS.md + PERF-SLO format for every landed lever; io_uring bench harness shape |
| `app-error` (error-classify) | candidate | recovery classification maps to the degradation ladder; revisit at handlers stage |
| `feedkit` | rejected | OSINT feed adapters (argus), not a feed server; name-only overlap |
| `json-envelope` | rejected | SPEC fixes exact response shapes; no envelope allowed |
| `cachekit` | rejected | challenge rule 5 forbids exactly this |
| `latent-oracle` | rejected | chess research engine; name coincidence |
