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
/- Proof targets 2 and 3 are PROVED below (consumed_le, consumed_le_len):
   structural induction on fuel — the `fuel + 2` arm calls `fuel + 1`, so
   plain `succ` induction suffices. The recorded blocker (equation-lemma
   discriminant shape `f + 1 + 1` vs goal shape `fuel + 2`) dissolves by
   NOT rewriting: after `induction` + `cases`, the goal already carries the
   `g + 1 + 1` shape the equations are keyed on, and `simp [decodeSpec]`
   fires directly. -/

theorem consumed_le : ∀ (fuel : Nat) (buf : List Nat) (acc v n : Nat),
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
theorem consumed_le_len : ∀ (fuel : Nat) (buf : List Nat) (acc v n : Nat),
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

/- Proof target 4: the decoded value is bounded by 2 ^ 64. The model's
   bytes are `Nat`, so the bound needs the byte-range hypothesis (the Rust
   decoder reads `u8`s; the varint oracle drives every u64 encoding).
   Induction shape: each consumed byte contributes one 7-bit group
   (`step7`: `acc * 128 + b % 128`); the 9th byte contributes `acc * 256
   + b`. So a successful decode of `n` bytes from accumulator `acc` stays
   under `(acc + 1) * 128 ^ n * 2` — at the entry point (acc = 0, n <= 9
   by `consumed_le`) that is `128 ^ 9 * 2 = 2 ^ 64`. -/
theorem step_bound {x y : Nat} {n : Nat} (h : x < (y + 1) * 128 ^ n) :
    x * 128 < (y + 1) * 128 ^ (n + 1) := by
  rw [Nat.pow_succ]
  rw [← Nat.mul_assoc]
  exact Nat.mul_lt_mul_of_pos_right h (by omega)

theorem value_bound : ∀ (fuel : Nat) (buf : List Nat) (acc v n : Nat),
    decodeSpec fuel buf acc = some (v, n) →
    (∀ b ∈ buf, b < 256) → v < (acc + 1) * 128 ^ n * 2 := by
  intro fuel
  induction fuel with
  | zero =>
    intro buf acc v n h _
    cases buf with
    | nil => simp [decodeSpec] at h
    | cons b rest => simp [decodeSpec] at h
  | succ f ih =>
    intro buf acc v n h bytes
    cases buf with
    | nil => simp [decodeSpec] at h
    | cons b rest =>
      have hrest : ∀ x ∈ rest, x < 256 := fun x hx => bytes x
        (List.mem_cons_of_mem b hx)
      have bmod : b % 128 < 128 := Nat.mod_lt b (by omega)
      cases f with
      | zero =>
        -- fuel = 1: the 9th byte: v = acc * 256 + b, n = 1
        have hb : b < 256 := bytes b (by simp)
        have h1 : decodeSpec (0 + 1) (b :: rest) acc
            = some (acc * 256 + b, 1) := by
          simp [decodeSpec]
        rw [h1] at h
        simp at h
        obtain ⟨_hv, hn⟩ := h
        subst hn
        simp only [Nat.pow_one]
        omega
      | succ g =>
        -- fuel = g+2: 7-bit group step, then terminate or recurse
        have h2 : decodeSpec (g + 1 + 1) (b :: rest) acc
            = if b < 128 then some (acc * 128 + b % 128, 1)
              else (decodeSpec (g + 1) rest (acc * 128 + b % 128)).map
                (fun p => (p.1, p.2 + 1)) := by
          simp [decodeSpec, step7]
        rw [h2] at h
        split at h
        · -- b < 128: v = acc * 128 + b % 128, n = 1
          simp at h
          obtain ⟨_hv, hn⟩ := h
          subst hn
          simp only [Nat.pow_one]
          omega
        · cases hdec : decodeSpec (g + 1) rest (acc * 128 + b % 128) with
          | none => rw [hdec] at h; simp at h
          | some q =>
            obtain ⟨v', n'⟩ := q
            rw [hdec] at h
            simp at h
            obtain ⟨hv, hn⟩ := h
            -- IH: v' < ((acc*128 + b%128) + 1) * 128^n' * 2  (left-assoc)
            have hi :
                v' < (acc * 128 + b % 128 + 1) * 128 ^ n' * 2 :=
              ih rest (acc * 128 + b % 128) v' n' hdec hrest
            -- re-associate to right-grouped factor for the ≤ lift
            have hi2 :
                v' < (acc * 128 + b % 128 + 1) * (128 ^ n' * 2) := by
              rw [← Nat.mul_assoc]
              exact hi
            have key : acc * 128 + b % 128 + 1 ≤ (acc + 1) * 128 := by omega
            -- lift through the ≤ (right-multiplication preserves ≤)
            have s1 : (acc * 128 + b % 128 + 1) * (128 ^ n' * 2)
                ≤ (acc + 1) * 128 * (128 ^ n' * 2) :=
              Nat.mul_le_mul_right _ key
            have s2 : v' < (acc + 1) * 128 * (128 ^ n' * 2) :=
              Nat.lt_of_lt_of_le hi2 s1
            -- normalize the bound to the goal's shape
            have shr : (acc + 1) * 128 * (128 ^ n' * 2)
                = (acc + 1) * 128 ^ (n' + 1) * 2 := by
              have e : 128 ^ (n' + 1) = 128 ^ n' * 128 := by
                rw [show (n' + 1) = Nat.succ n' from rfl, Nat.pow_succ]
              rw [e]
              have e1 : (acc + 1) * 128 * (128 ^ n' * 2)
                  = (acc + 1) * (128 * (128 ^ n' * 2)) :=
                Nat.mul_assoc (acc + 1) 128 (128 ^ n' * 2)
              have e2 : 128 * (128 ^ n' * 2) = (128 ^ n' * 128) * 2 := by
                rw [← Nat.mul_assoc 128 (128 ^ n') 2,
                    Nat.mul_comm 128 (128 ^ n')]
              rw [e1, e2, ← Nat.mul_assoc (acc + 1) (128 ^ n' * 128) 2]
            rw [← hv, ← hn]
            rw [shr] at s2
            omega

/- Corollary (target 4): `decode` never produces a value at or above
    2 ^ 64 — it fits `u64`, matching the Rust decoder's semantics. -/
theorem decode_value_lt_u64_max {buf : List Nat} {v n : Nat}
    (h : decode buf = some (v, n))
    (bytes : ∀ b ∈ buf, b < 256) :
    v < 9223372036854775808 * 2 := by
  have hv : v < (0 + 1) * 128 ^ n * 2 := value_bound 9 buf 0 v n h bytes
  have hn : n ≤ 9 := consumed_le 9 buf 0 v n h
  have hpow : 128 ^ n ≤ 128 ^ 9 := Nat.pow_le_pow_right (by omega) hn
  have h9 : 128 ^ 9 = 9223372036854775808 := by decide
  simp only [Nat.zero_add, Nat.one_mul] at hv
  rw [h9] at hpow
  omega

end UringsHttpKitProof.Varint
