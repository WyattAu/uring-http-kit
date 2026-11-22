# ADR 0003: Single-thread pass model on io_uring DEFER_TASKRUN

Status: ACCEPTED (2026-11-22)
Context: REQ-URIK-C4; one CPU core; 15,000 keep-alive connections; challenge rule 6 allows
group commit when each response waits for its commit.

## Decision

One thread does everything: io_uring event loop (multishot accept/recv, provided buffer
rings), HTTP parse, JWT, reads, rusqlite writes, response build (per-pass arena), send
(SEND_ZC with fallback), checkpoints between passes. No helper threads, no locks.

Pass structure: drain completions; parse+route; if DB work queued, open a read snapshot
(frame count), execute reads against it, run the batched writes via rusqlite, COMMIT,
then send that pass's responses. Read-your-writes across passes holds because a commit
always lands before its response leaves; within a pass, reads share one snapshot.

## Alternatives rejected

| Alternative | Why rejected |
|---|---|
| Thread per core / SO_REUSEPORT workers | the box has one core; fan-out only adds contention and snapshot complexity |
| Checkpoint thread (incumbent design) | adds cross-thread sync on the WAL index; checkpoints are rare and 2..4 ms; running them on the loop thread between passes is simpler and the pause is invisible at the p99 budget |
| Fixed 2 ms batching timer | arbitrary latency floor; event-immediate is the default, fixed batching is an A/B lever (SPEC Q1) |

## Consequences

+ No locking, trivial snapshot reasoning, natural group commit.
- A slow request in a pass delays its peers (mitigation: per-request work is bounded and
  the degradation ladder caps worst cases; measure in the ladder).
- Checkpoint pauses appear on the loop; at ~1 s cadence and 2..4 ms cost they stay under
  0.5% of requests (verify in bench, SPEC Q4).

## Amendment (2026-11-22, sweep v2)

The loop is **uring-kit's** (`UringEngine` + `BufferPool`), not hand-written: registered
`ReadFixed`/`WriteFixed` buffers replace provided-buffer rings (equivalent zero-malloc goal;
sidesteps the Ubuntu resv[0] registration bug by construction); multishot accept becomes
completion-driven re-arm accept; `probe` handles kernel feature detection (SEND_ZC
availability). `uring-http` keeps: HTTP parser, router, JSON templates, pass scheduler,
degradation ladder. The event-loop layer is deleted from this repo's scope.
