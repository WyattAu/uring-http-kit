//! Bounds-checked SQLite record/varint decoding.
//!
//! Layer: L1 substrate. `no_std`, zero runtime deps, allocation-free decode.
//! Proof targets (Lean, `proof/`): totality, bounds, and exact output-size
//! prediction for every decoder in this crate. Differential oracle
//! (`tests/`): decoded records must agree with `sqlite3` column values on
//! the actual seed file.
//!
//! References: https://www.sqlite.org/fileformat2.html (record format,
//! serial types) and the varint definition in the SQLite source.

#![no_std]
#![forbid(unsafe_op_in_unsafe_fn)]

pub mod record;
pub mod varint;

/// Decode error: every failure is a bounded, total, allocation-free `Option`/`Err`
/// — never a panic. A truncated or malformed buffer is data, not a bug.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum DecodeError {
    /// Buffer ended before the item completed.
    Truncated,
    /// A varint exceeded its 9-byte maximum.
    VarintTooLong,
    /// A serial type is not valid for a record body.
    BadSerialType,
    /// Declared record size does not match the payload available.
    SizeMismatch,
}
