# ADR 0002: Feed = backward table walk with checked order invariant

Status: ACCEPTED (2026-11-22)
Context: REQ-URIK-F2, R4. Seed measurement: the newest 20 posts are ids 499981..500000,
all within one table leaf page; bodies average 131 B (no overflow cells); new posts at the
challenge's 310k-user rate add ~585 rows/s, extending the tail by ~2 leaf pages per minute.

## Decision

`GET /feed` reads the posts table's rightmost leaf (descend right spine), walks cells
backward, then resolves authors and like counts. The `(created_at DESC, id DESC)` order is
served by rowid order plus a per-pass invariant check: each feed-head cell's `created_at`
must be >= its successor's. On violation, the request falls back to the index walk
(posts_created_at_id_idx) which the reader also implements.

Why the invariant holds: SPEC-legal inserts always stamp `created_at` with insert time
(column default, challenge/SPEC.md) and rowids are monotonic, so rowid order refines
created_at order; the check converts an argument into a runtime assertion with a rescue path.

## Alternatives rejected

| Alternative | Why rejected |
|---|---|
| Index walk like the incumbent | pays an index walk plus 20 random table seeks per feed; the table tail is one hot page |
| Author range walk (authors cluster) | killed by data: newest-20 authors spread over all of 1..50k |
| Per-pass result dedup | challenge rule 5 forbids query-result caching; page-cache reuse (mmap) already covers it |

## Consequences

+ Feed DB work: one descent + leaf walk + 20 user seeks + rightmost likes walk; removes the
  index walk and 20 random seeks on the hottest endpoint.
+ Same rightmost trick applies to like counting (newest ids sit at the likes index tail).
- Invariant violation path must stay fast: fallback frequency is logged (metric, not silent).
