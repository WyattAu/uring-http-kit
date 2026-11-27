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
