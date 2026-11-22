# ADR 0005: Objective-aware adaptive pass scheduler

Status: PROPOSED (validate in bench before adoption; SPEC Q5)
Context: the score is the highest user count holding p95 < 500 ms and p99 < 1 s
(challenge/README.md). Under saturation, a single-thread server controls its own tail:
longer passes favor throughput, shorter passes favor latency. No leaderboard entry adapts
its batching; the incumbent uses a fixed ~2 ms cadence.

## Decision (proposed)

The loop keeps an exponentially weighted latency estimate from its own completed requests
and adjusts the maximum requests-per-pass between bounds (order 8..256):

- estimate drifting toward the p95 budget: shrink the pass cap (favor latency)
- estimate comfortably under budget: grow the cap (favor throughput)

The controller reacts only to the server's own latency; it never inspects load patterns
(challenge rule 7 compliant). Degradation is smooth by construction: queue depth, not
rejection, is the adjustment variable.

## Why this is a design contribution

Every prior entry fixes a cadence a priori. The score function is threshold-based, so the
optimal cadence is load-dependent by definition; a controller closing the loop on its own
measured tail converts the benchmark's objective into the scheduler's objective. Expected
effect materializes only near saturation, which is exactly where the score is set.

## Validation plan

A/B on `load-calib.js` at matched CPU% near the knee: fixed vs adaptive cap. Adopt only on
a measured p95/p99 improvement at equal or better throughput (REQ-URIK-P3 discipline).

## Estate inputs

The estimator is `percentile-kit`'s lock-free sliding window (p50/p95/p99 at runtime), not
a bespoke EMA; regression gates ride `percentile-budgets.toml`. Bench confinement uses
`hw-kit` core pinning (process-internal, rule-11 legal; a no-op on the challenge's
single-vCPU box).

## Risks

- Controller oscillation near the knee: bound the step, average over windows, and cap
  the adaptation rate; worst case degenerates to the fixed-cadence A/B arm.
- Interaction with group-commit latency: pass length changes commit batch size; monitor
  write-path latency in the same A/B.
