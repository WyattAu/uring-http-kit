/-
SQLite varint decoder — proof file mirroring
`crates/sqlite-btree/src/varint.rs`. The Rust implementation is the
executable counterpart; the differential/proptest suite
(tests/varint_oracle.rs) is the oracle.

Contract:
  1. Totality: `decode` always produces a result (structural recursion).
  2. Consumption bound: a successful decode consumes at most 9 bytes.
  3. No phantom progress: consumed bytes never exceed the buffer length.

Model: bytes 1..8 shift 7 bits each; a 9th byte shifts 8 — exactly the Rust
decoder's structure. Fuel counts remaining byte slots and starts at 9 in
`decode`; fuel = 1 is the 9th byte (8-bit shift, must terminate); fuel = 0
is malformed input (10th+ byte).
-/

namespace UringsHttpKitProof.Varint

/-- One 7-bit-group decoding step (bytes 1..8 of the varint). -/
def step7 (acc : Nat) (b : Nat) : Nat :=
  acc * 128 + (b % 128)

/-- Decoder specification (patterns mirror the Rust `i == 8` arm). -/
def decodeSpec : Nat → List Nat → Nat → Option (Nat × Nat)
  | _, [], _ => none
  | 0, b :: _, _ => none -- 10th+ byte: malformed
  | 1, b :: _, acc => some (acc * 256 + b, 1) -- 9th byte: 8-bit shift
  | fuel + 2, b :: rest, acc =>
      let nv := step7 acc b
      if b < 128 then
        some (nv, 1)
      else
        (decodeSpec (fuel + 1) rest nv).map (fun p => (p.1, p.2 + 1))

/-- The Rust decoder consumes at most 9 bytes: fuel starts at 9. -/
def decode (buf : List Nat) : Option (Nat × Nat) :=
  decodeSpec 9 buf 0

/- Proof targets 2 and 3 are PROVED below (consumed_le, consumed_le_len):
   structural induction on fuel — the `fuel + 2` arm calls `fuel + 1`, so
   plain `succ` induction suffices. The recorded blocker (equation-lemma
   discriminant shape `f + 1 + 1` vs goal shape `fuel + 2`) dissolves by
   NOT rewriting: after `induction` + `cases`, the goal already carries the
   `g + 1 + 1` shape the equations are keyed on, and `simp [decodeSpec]`
   fires directly. Target 4 (value bound < 2^64) remains the open target,
   enforced empirically by tests/varint_oracle.rs. -/

/-- Proof target 1 (totality): `decode` is total by structural recursion. -/
theorem decode_terminates (buf : List Nat) :
    ∃ r, decode buf = r := ⟨decode buf, rfl⟩

/- Proof target 4 (value bound: decoded value < 2 ^ 64) is an OPEN target
   tracked in the ledger; enforced empirically by the proptest round-trip
   over all u64 (tests/varint_oracle.rs). -/


/- Proof targets 2 and 3: consumption bounds, by induction on `fuel`.
   The recursion pattern `fuel + 2` calls `fuel + 1`: exactly one step
   down, so structural induction suffices. The equation lemmas are keyed
   on `f + 1 + 1`-shaped discriminants — which is exactly the shape the
   goal carries after `succ`/`cases` splitting, so `simp [decodeSpec]`
   fires without any arithmetic rewriting. -/
theorem consumed_le : ∀ (fuel : Nat) (buf : List Nat) (acc : Nat) (v n : Nat),
    decodeSpec fuel buf acc = some (v, n) → n ≤ fuel := by
  intro fuel
  induction fuel with
  | zero =>
    intro buf acc v n h
    cases buf with
    | nil => simp [decodeSpec] at h
    | cons b rest => simp [decodeSpec] at h
  | succ f ih =>
    intro buf acc v n h
    cases buf with
    | nil => simp [decodeSpec] at h
    | cons b rest =>
      cases f with
      | zero =>
        -- fuel = 1: the 9th-byte arm consumes exactly 1
        simp [decodeSpec] at h
        omega
      | succ g =>
        -- fuel = g+2: the general arm (7-bit group; b < 128 terminates)
        simp [decodeSpec] at h
        split at h
        · simp at h; omega
        · cases hdec : decodeSpec (g + 1) rest (step7 acc b) with
          | none => rw [hdec] at h; simp at h
          | some q =>
            obtain ⟨v', n'⟩ := q
            rw [hdec] at h
            simp at h
            have hle := ih rest (step7 acc b) v' n' hdec
            omega

/-- Target 3: consumed bytes never exceed the buffer length. -/
theorem consumed_le_len : ∀ (fuel : Nat) (buf : List Nat) (acc : Nat) (v n : Nat),
    decodeSpec fuel buf acc = some (v, n) → n ≤ buf.length := by
  intro fuel
  induction fuel with
  | zero =>
    intro buf acc v n h
    cases buf with
    | nil => simp [decodeSpec] at h
    | cons b rest => simp [decodeSpec] at h
  | succ f ih =>
    intro buf acc v n h
    cases buf with
    | nil => simp [decodeSpec] at h
    | cons b rest =>
      cases f with
      | zero =>
        simp [decodeSpec] at h
        simp only [List.length_cons]
        omega
      | succ g =>
        simp [decodeSpec] at h
        split at h
        · simp at h
          simp only [List.length_cons]
          omega
        · cases hdec : decodeSpec (g + 1) rest (step7 acc b) with
          | none => rw [hdec] at h; simp at h
          | some q =>
            obtain ⟨v', n'⟩ := q
            rw [hdec] at h
            simp at h
            have hle := ih rest (step7 acc b) v' n' hdec
            simp only [List.length_cons]
            omega

/-- Corollary: the Rust decoder (fuel starts at 9) consumes at most 9
    bytes and never reads past the buffer. -/
theorem decode_bounds (buf : List Nat) (v n : Nat)
    (h : decode buf = some (v, n)) : n ≤ 9 ∧ n ≤ buf.length :=
  ⟨consumed_le 9 buf 0 v n h, consumed_le_len 9 buf 0 v n h⟩

end UringsHttpKitProof.Varint
