//! The event loop (ADR 0003): one thread, uring-kit transport, pass-based
//! group commit. Reads run at one snapshot; writes batch through rusqlite;
//! COMMIT lands before the pass's responses flush; reader.refresh() at the
//! start of the next pass advances the snapshot.
//!
//! DESIGN (complete, in docs/PLAN.md + ledger; implementation is the next
//! session's single task — this file is the seam it lands in):
//!
//! 1. UringEngine::new(RING_ENTRIES, Some(&BufferPool(16k x 2KB)), sqpoll=false)
//! 2. listener via uring_kit::net::tcp_listener + add_listener(accept token)
//! 3. drain CQEs (engine.poll(250ms)): Accept -> admit (pool.take slot,
//!    add_stream, submit read); Read -> conn.buf.extend(slot[..n]) + parse;
//!    Write -> outstanding_sends -= 1, re-arm read; Close -> release slot
//! 4. parse per SPEC: unknown path/method -> 404 not found; id all-digits > 0
//!    else 400 invalid post id; deeper path shapes -> 404
//! 5. pass (when requests queued):
//!    a. auth via store.keyed_mac (jwt::verify) - 401 rows first
//!    b. reads against the current reader snapshot (handlers::read_*)
//!    c. writes batched: BEGIN; insert_post/insert_like; COMMIT
//!    d. store.refresh_snapshot(&writer) - advances for the NEXT pass
//!    e. build responses into the arena; write_vectored per response;
//!       outstanding_sends bookkeeping; re-arm reads
//! 6. SPEC responses: exact bytes via router::errors + uring_http::json
//!    writers (write_post_json / feed assembled); created_at echo from the
//!    writer's RETURNING; like 201/200 via rusqlite changes()
//! 7. body validation: one-scan JSON "body" extraction, ASCII-trim, <=500
//!    after trim (error rows: malformed JSON / body is required / at most 500)
//! 8. degradation ladder: reader fault -> handlers fall back to bundled
//!    sqlite per request; repeated faults -> reader disabled (store)
//!
//! Kernel note: Ubuntu 6.8 refuses buffer-ring registration with zeroed
//! reserved words (Launchpad #2162843); registered buffers via
//! IORING_REGISTER_BUFFERS do not take that path.

#![forbid(unsafe_op_in_unsafe_fn)]

// implementation lands next session (see docs/PLAN.md G3)
