//! HTTP/1.1 request parsing: fixed route set, zero-copy header views.
//! Totality over arbitrary bytes — any input yields a request or an
//! error response, never a panic (Lean target).

/// Parsed request line + headers we care about. Bytes borrow from the
/// provided-buffer ring; nothing is copied.
pub struct Request<'a> {
    pub method: Method,
    pub path: &'a [u8],
    /// Raw `Authorization` header value (without name), if present.
    pub authorization: Option<&'a [u8]>,
    /// Declared body length from `Content-Length`, if any.
    pub content_length: Option<usize>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Method {
    Get,
    Post,
    Other,
}

// TODO(challenge): parser state machine; keep it total and branch-light:
// one pass, memchr for CRLFCRLF, integer parse for content-length.
