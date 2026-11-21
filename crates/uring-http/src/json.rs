//! Fixed-shape JSON response templates. Key order is fixed by the SPEC;
//! bodies are written into pre-sized buffers (size prepass mirrors the
//! record decoder — Lean target: sizes agree).

// TODO(challenge): post-object writer: {"id":…,"body":…,"created_at":…,
// "author":…,"like_count":…} with exact byte-length prepass.
