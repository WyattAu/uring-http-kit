# ADR 0006: Connection lifecycle at 310k users ;  adaptive idle close

Status: PROPOSED (resolve with the fd-pressure test at G3)
Context: challenge LimitNOFILE=65535. In direct mode every k6 VU holds one keep-alive
connection, so the leaderboard's 310,000-user scores imply far more logical connections
than the fd budget allows. The SPEC's "~15,000 open connections" expectation predates the
modern scoreboard. The arithmetic is hard: 310k concurrent fds is impossible; therefore
the top entries must close idle connections and let k6 reconnect transparently (the 65 s
idle-keep requirement applies only to Nginx mode).

## Decision

Direct mode with three fixed rules plus one controller:

1. Server-first close: after a response is fully sent, close the connection. The server
   never lingers; TIME_WAIT lands on the load generator's side, never ours.
2. No half-open grace: `close` immediately on response completion (Content-Length makes
   the end unambiguous; k6 reconnects on its next request).
3. Active requests are never dropped: close only connections with no in-flight request.
4. Adaptive idle timeout: with keep-alive enabled up to `T` seconds of idleness, `T` is
   driven by an fd-budget controller (target < 45,000 fds; shed toward `T = 0` under
   pressure, relax toward `T = 65 s` when idle). The connection count at steady state is
   approximately `request_rate x T`, so `T = 1 s` holds ~30k fds at 310k-user rates.

## Alternatives rejected

| Alternative | Why rejected |
|---|---|
| Unbounded keep-alive | fd exhaustion near 65k VUs; process death |
| Nginx fronting | 14-20% CPU tax measured in the video; Nginx's own 310k-connection memory on a 2 GB box |
| Aggressive fixed T = 0 always | reconnect handshake CPU on every request; keep-alive helps when the fd budget allows |

## Consequences

+ The fd wall scales past 310k users; memory and fds track active work, not user count.
- Reconnect handshakes cost CPU on our core at high churn; the A/B sweep over T
  (0 s / 1 s / 65 s) measures the trade directly (FRONTIER F51..F55).
- k6 reconnect transparency must be verified empirically: fd-pressure test at 20k local
  VUs with forced T = 0 must hold error rate < 1%.
