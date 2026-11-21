/-
SQLite varint decoder — proof skeleton mirroring `crates/sqlite-btree/src/varint.rs`.

Contract under proof:
  1. Totality: `decode` returns a result on every input (never "stuck").
  2. Consumption bound: bytes consumed ≤ min(9, buf.len).
  3. Value bound: value < 2^64 (u64 fits by construction of the shifts).

The executable link to the Rust implementation is the differential/proptest
suite (tests/), not extraction: this file is the *specification*, the Rust
code is the *implementation*, the property tests are the *oracle*.
-/

namespace UringsHttpKitProof.Varint

/-- One decoding step over a byte: 7 payload bits + continuation flag. -/
structure Step where
  value : Nat
  consumed : Nat
  done : Bool

/-- Specification of one step, mirroring the Rust loop body. -/
def step (value : Nat) (byte : Nat) : Step :=
  if byte < 0x80 then
    -- high bit clear: last byte, 7 payload bits
    { value := value * 128 + (byte % 128), consumed := 1, done := true }
  else
    { value := value * 128 + (byte % 128), consumed := 1, done := false }

/-- Full decode spec over a byte list, ≤ 9 steps, mirroring `decode` in
varint.rs. `none` = truncated/too long (DecodeError), `some (v, n)` = OK. -/
def decodeSpec : Nat → List Nat → Nat → Option (Nat × Nat)
  | fuel, [], _ => none                       -- ran out of bytes
  | 0, _, _ => none                           -- fuel gone: ≥ 10 continuation bytes
  | fuel + 1, b :: rest, acc =>
      let s := step acc b
      if s.done then some (s.value, s.consumed)
      else (decodeSpec fuel rest (s.value)).map (fun (v, n) => (v, n + 1))

/-- The Rust decoder consumes at most 9 bytes. Mirrored here as fuel = 9. -/
def decode (buf : List Nat) : Option (Nat × Nat) := decodeSpec 9 buf 0

/-- **Proof target 1 (totality).** `decode` always produces a total function:
it is defined by structural recursion on fuel, hence terminates on every
input. This is free by definition; stated for the contract record. -/
theorem decode_terminates (buf : List Nat) :
    ∃ r, decode buf = r := ⟨decode buf, rfl⟩

/-- **Proof target 2 (consumption bound).** A successful decode consumes at
most 9 bytes — fuel starts at 9 and every step consumes exactly 1. -/
theorem consumed_le_nine :
    ∀ buf v n, decode buf = some (v, n) → n ≤ 9 := by
  intro buf v n h
  simp [decode] at h
  -- structural: each recursive level adds 1 to consumed, fuel caps levels at 9
  sorry -- TODO(proof): induct on fuel; 1-line omega after generalizing

/-- **Proof target 3 (no phantom progress).** Consumed bytes never exceed the
buffer length. -/
theorem consumed_le_len :
    ∀ buf v n, decode buf = some (v, n) → n ≤ buf.length := by
  intro buf v n h
  sorry -- TODO(proof): same induction as target 2, plus length conservation

end UringsHttpKitProof.Varint
