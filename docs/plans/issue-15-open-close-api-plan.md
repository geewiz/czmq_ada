# Issue #15: In-Place Open/Close API — Implementation Plan

**Version:** 1.0
**Status:** Draft
**Date:** 2026-05-09

## Context

The `Socket`, `Certificate`, and `Poller` types are `Ada.Finalization.Limited_Controlled`. The Ada `Limited` rule forbids `:=` assignment, so consumers cannot populate a wrapper field after declaration. The only public API to acquire a handle is via constructor functions (`New_Pub`, `New_Certificate`, `New_Poller`, etc.), forcing factory-function shapes for two-phase init.

This plan adds `Open` / `Close` mutators to each type, enabling:
- `procedure Initialize (Self : in out My_Controller)` that calls `Self.Socket.Open_Router (...)`
- Default-empty fields that can be populated later
- Explicit, idempotent cleanup before scope exit

---

## Requirements Trace

| ID | Requirement | Source |
|----|-------------|--------|
| R1 | Add `Open` / `Open_*` / `Close` to `CZMQ.Sockets` | Issue #15 Proposal |
| R2 | Add `Generate` / `Load` (procedure) / `Close` to `CZMQ.Certificates` | Issue #15 Proposal |
| R3 | Add `Open` / `Close` to `CZMQ.Pollers` | Issue #15 Proposal |
| R4 | API-compatible: existing `New_*` constructors preserve their signatures and observable behavior | Issue #15 Backwards Compatibility |
| R5 | `Open` on already-valid object raises `Program_Error` | Issue #15 Precondition |
| R6 | `Close` is idempotent (no-op if already empty) | Issue #15 Close Spec |
| R7 | Existing constructors may be reimplemented in terms of `Open` internally | Issue #15 Backwards Compatibility |

---

## Units

### Unit 1: Socket Open/Close API

**Goal:** Add in-place `Open` / `Open_*` / `Close` procedures to `CZMQ.Sockets`, preserving all existing constructors.

**Requirements trace:** R1, R4, R5, R6, R7

**Dependencies:** None

**Files:**
- `src/czmq-sockets.ads` — add declarations for `Open` (no Endpoint), `Open_Pub`, `Open_Sub`, `Open_Req`, `Open_Rep`, `Open_Push`, `Open_Pull`, `Open_Dealer`, `Open_Router`, `Close`
- `src/czmq-sockets.adb` — add implementations; refactor `New_Socket`, `New_Pub`, etc. to delegate to `Open` for DRY

**Approach:**

1. In the spec, add the generic `Open` and the convenience wrappers alongside the existing `New_*` functions:

   ```ada
   procedure Open
     (Self : in out Socket;
      Kind : Socket_Type);

   procedure Open_Pub    (Self : in out Socket; Endpoint : String := "");
   procedure Open_Sub    (Self : in out Socket;
                          Endpoint  : String := "";
                          Subscribe : String := "");
   procedure Open_Req    (Self : in out Socket; Endpoint : String := "");
   procedure Open_Rep    (Self : in out Socket; Endpoint : String := "");
   procedure Open_Push   (Self : in out Socket; Endpoint : String := "");
   procedure Open_Pull   (Self : in out Socket; Endpoint : String := "");
   procedure Open_Dealer (Self : in out Socket; Endpoint : String := "");
   procedure Open_Router (Self : in out Socket; Endpoint : String := "");

   procedure Close (Self : in out Socket);
   ```

2. Implement `Open (Self, Kind)`:
   - If `Self.Handle /= null`, raise `Program_Error` with message `"Socket is already open"`.
   - Call `Low_Level.zsock_new (Socket_Type_To_Int (Kind))` and assign to `Self.Handle`.
   - Raise `CZMQ_Error` if the result is null.
   - Note: no `Endpoint` parameter. The generic `Open` creates a bare socket, matching `New_Socket`. Use the specific `Open_*` wrappers for endpoint handling, or call `Bind`/`Connect` after `Open`.

3. Implement each `Open_*` convenience wrapper by calling the C `zsock_new_*` function directly — do NOT delegate to the generic `Open`. The `@`/`>` endpoint prefix convention is handled internally by the CZMQ C constructors (`zsock_new_pub`, `zsock_new_sub`, etc.), and replicating that logic in Ada would be fragile and wrong. The generic `Open` and the specific `Open_*` wrappers serve distinct purposes:
   - `Open (Self, Kind)` — creates a bare socket with no endpoint.
   - `Open_Pub (Self, Endpoint)` — creates a PUB socket, binding/connecting via the C constructor's prefix handling.
   - The `Open_Sub` wrapper must pass the `Subscribe` filter as a C string even when empty (same bug-prevention as `New_Sub`).

4. Implement `Close (Self)`:
   - If `Self.Handle = null`, return immediately (idempotent).
   - Create a local `aliased Low_Level.zsock_t_Access := Self.Handle`, call `Low_Level.zsock_destroy` on it.
   - **Critical:** Set `Self.Handle := null` after destroy. The C destroy function nulls the *local* pointer copy, not `Self.Handle`. If `Self.Handle` is not nulled here, `Finalize` will double-free when the object goes out of scope.

5. Refactor existing `New_*` constructors to delegate to `Open`:
    - Change each to call the corresponding `Open_*` procedure inside an extended return statement. Limited types require extended return — a simple `return Result;` is illegal.
    - Example: `New_Dealer` becomes:
      ```ada
      function New_Dealer (Endpoint : String := "") return Socket is
      begin
         return Result : Socket do
            Open_Dealer (Result, Endpoint);
         end return;
      end New_Dealer;
      ```
    - `New_Socket` delegates to `Open` (no endpoint). `New_Sub` delegates to `Open_Sub` (preserving the Subscribe parameter).
    - This is required, not optional — it keeps the constructor logic in one place and ensures the new `Open` path is exercised by the existing test suite.

**Patterns:**
- Follow the existing C-string handling pattern: `CS.New_String` + `CS.Free`, with `Null_Ptr` guard for optional endpoints.
- Follow existing error style: `raise CZMQ_Error with "..."` for CZMQ failures; `raise Program_Error` for precondition violations.
- The `Open_Sub` empty-string handling must match `New_Sub` exactly (always allocate the C string, never pass `NULL`).

**Test scenarios:**
- [ ] Happy path: default-empty socket → `Open_Pub` → `Is_Valid = True` → `Close` → `Is_Valid = False`
- [ ] Error path: `Open_Pub` on already-open socket raises `Program_Error`
- [ ] Error path: `Close` on already-closed socket is a no-op (does not raise)
- [ ] Error path: `Bind` on a closed socket raises `CZMQ_Error`
- [ ] Edge case: `Open` creates a bare socket with no endpoint (mirrors `New_Socket` behavior)
- [ ] Edge case: `Open_Sub` with empty `Subscribe` filter subscribes to all messages
- [ ] Safety: open → close → let go out of scope; no double-free or memory leak
- [ ] Regression: existing `New_Pub`, `New_Sub`, etc. constructors still work correctly after refactor

**Verification:**
- `alr build` compiles library and tests without errors or warnings.
- `bin/test_sockets` passes all assertions (including new Open/Close tests).
- Valgrind / ASan run (if available) shows no leaks on the "open → close → scope exit" path.

**Planning-time unknowns:**
- None. The CZMQ `zsock_destroy` behavior is well-documented and the existing `Finalize` pattern is established.

---

### Unit 2: Certificate Open/Close API

**Goal:** Add in-place `Generate`, `Load` (procedure overload), and `Close` to `CZMQ.Certificates`.

**Requirements trace:** R2, R4, R5, R6, R7

**Dependencies:** None

**Files:**
- `src/czmq-certificates.ads` — add `Generate`, `Load` (procedure), `Close`
- `src/czmq-certificates.adb` — add implementations; refactor `New_Certificate` and `Load` (function) to delegate to new procedures

**Approach:**

1. In the spec, add:

   ```ada
   procedure Generate (Self : in out Certificate);
   procedure Load     (Self : in out Certificate; Filename : String);
   procedure Close    (Self : in out Certificate);
   ```

2. Implement `Generate (Self)`:
   - If `Self.Handle /= null`, raise `Program_Error`.
   - Call `Low_Level.zcert_new`, assign to `Self.Handle`.
   - Raise `CZMQ_Error` on null result.

3. Implement `Load (Self, Filename)`:
   - If `Self.Handle /= null`, raise `Program_Error`.
   - Convert `Filename` to C string, call `Low_Level.zcert_load`, assign to `Self.Handle`.
   - Raise `CZMQ_Error` on null result.

4. Implement `Close (Self)`:
   - Idempotent no-op if `Self.Handle = null`.
   - Local aliased copy → `zcert_destroy` → **set `Self.Handle := null`** (same double-free prevention as Socket).

5. Refactor `New_Certificate` and `Load` (function) to delegate to `Generate` / `Load` (procedure) for DRY. This ensures the new procedure path is covered by existing tests.

**Patterns:**
- Same as Unit 1: local aliased copy for destroy, null `Self.Handle` afterward.
- Same C-string and error-handling patterns as existing code.

**Test scenarios:**
- [ ] Happy path: default-empty cert → `Generate` → `Is_Valid = True` → `Close` → `Is_Valid = False`
- [ ] Happy path: default-empty cert → `Load` from saved file → keys match
- [ ] Error path: `Generate` on already-valid cert raises `Program_Error`
- [ ] Error path: `Close` on already-closed cert is a no-op
- [ ] Error path: `Public_Key` on closed cert raises `CZMQ_Error`
- [ ] Safety: generate → close → scope exit; no double-free
- [ ] Regression: existing `New_Certificate` and `Load` (function) still work after refactor

**Verification:**
- `alr build` compiles library and tests cleanly.
- `bin/test_certificates` passes all assertions.

**Planning-time unknowns:**
- None.

---

### Unit 3: Poller Open/Close API

**Goal:** Add in-place `Open` and `Close` to `CZMQ.Pollers`.

**Requirements trace:** R3, R4, R5, R6, R7

**Dependencies:** None (Pollers already depends on Sockets package, but does not depend on Unit 1's new API)

**Files:**
- `src/czmq-pollers.ads` — add `Open`, `Close`
- `src/czmq-pollers.adb` — add implementations; refactor `New_Poller` to delegate to `Open`

**Approach:**

1. In the spec, add:

   ```ada
   procedure Open  (Self : in out Poller; Socket : in out Sockets.Socket);
   procedure Close (Self : in out Poller);
   ```

2. Implement `Open (Self, Socket)`:
   - If `Self.Handle /= null`, raise `Program_Error`.
   - If `not Socket.Is_Valid`, raise `CZMQ_Error` (same validation as `New_Poller`).
   - Call `Low_Level.zpoller_new (Socket.Get_Handle, System.Null_Address)`, assign to `Self.Handle`.
   - Reset `Self.Last_Ready := System.Null_Address`.
   - Raise `CZMQ_Error` on null result.

3. Implement `Close (Self)`:
   - Idempotent no-op if `Self.Handle = null`.
   - Local aliased copy → `zpoller_destroy` → **set `Self.Handle := null`**.
   - Reset `Self.Last_Ready := System.Null_Address`.

4. Refactor `New_Poller` to delegate to `Open` for DRY. This ensures the new procedure path is covered by existing tests.

**Patterns:**
- Same as Units 1 and 2 for Close.
- `Open` validates socket validity before creating the poller, mirroring `New_Poller`.

**Test scenarios:**
- [ ] Happy path: default-empty poller → `Open` with valid socket → `Is_Valid = True` → `Close` → `Is_Valid = False`
- [ ] Error path: `Open` on already-valid poller raises `Program_Error`
- [ ] Error path: `Open` with invalid socket raises `CZMQ_Error`
- [ ] Error path: `Close` on already-closed poller is a no-op
- [ ] Error path: `Wait` on closed poller raises `CZMQ_Error`
- [ ] Safety: open → close → scope exit; no double-free
- [ ] Regression: existing `New_Poller` still works after refactor

**Verification:**
- `alr build` compiles library and tests cleanly.
- `bin/test_pollers` passes all assertions.

**Planning-time unknowns:**
- None.

---

## Quality Bar Checklist

- [x] Every unit has a requirements trace (R1–R7 mapped above)
- [x] Dependencies form a DAG (no cycles; Units 1–3 are independent)
- [x] Every unit has at least 3 test scenarios (6+ per unit listed)
- [x] No unit touches >8 files (each touches 2–3 files)
- [x] No more than 2 new abstractions introduced per unit (0 new abstractions; only procedures)
- [x] Every planning-time unknown is classified (all "None")
- [x] Handoff completeness test: an engineer would not need to invent product behavior — only translate the Ada patterns shown into code

---

## Critical Safety Note

The current `Finalize` implementations for all three types create a **local aliased copy** of the handle, pass its access to the C destroy function, and then do not null `Self.Handle`. This is acceptable for `Finalize` because the Ada object is being destroyed and will not be accessed again. However, the new `Close` procedures **must** set `Self.Handle := null` after calling destroy, because the Ada object remains alive and `Finalize` will be invoked later when it goes out of scope. Failure to do this will cause a double-free.

Example correct `Close` skeleton:

```ada
procedure Close (Self : in out Socket) is
begin
   if Self.Handle /= null then
      declare
         Handle_Copy : aliased Low_Level.zsock_t_Access := Self.Handle;
      begin
         Low_Level.zsock_destroy (Handle_Copy'Access);
      end;
      Self.Handle := null;
   end if;
end Close;
```

---

## Next Steps

1. Create a feature branch (e.g., `feature/issue-15-open-close`).
2. Implement Unit 1, Unit 2, Unit 3 in any order (or in parallel).
3. Run the full test suite (`bin/test_sockets`, `bin/test_certificates`, `bin/test_pollers`, plus existing tests) to confirm no regressions.
4. Open a PR referencing Issue #15.
