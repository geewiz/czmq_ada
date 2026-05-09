# Issue #14: Expose zsys_interrupted as CZMQ.Signals — Implementation Plan

**Version:** 1.0
**Status:** Draft
**Date:** 2026-05-09

## Context

CZMQ's `zsys_init` (called during socket creation) installs its own SIGINT/SIGTERM handler via `sigaction`, silently overwriting any handler installed via `GNAT.Ctrl_C.Install_Handler`. The only working approach for Ada users is to check the C global variable `zsys_interrupted` directly, but that requires knowing this CZMQ implementation detail and manually importing a C global. This plan adds a `CZMQ.Signals` package that provides a clean, high-level Ada API for interrupt detection and signal handler control.

---

## Requirements Trace

| ID | Requirement | Source |
|----|-------------|--------|
| R1 | Provide `Is_Interrupted` function returning Boolean | Issue #14 Proposal |
| R2 | Bind `zsys_interrupted` in `CZMQ.Low_Level` as an imported C variable | R1 Implementation |
| R3 | Provide `Set_Handler` procedure to register custom interrupt handler | Issue #14 Optional |
| R4 | Provide `Reset_Handler` procedure to restore default handlers | Issue #14 Optional |
| R5 | Package name must not collide with Ada's `System` package | Design Decision |
| R6 | Package must be usable without prior CZMQ socket creation | Issue #14 Context |

---

## Units

### Unit 1: Low-Level Binding and CZMQ.Signals Package

**Goal:** Add `zsys_interrupted` binding to `CZMQ.Low_Level` and create `CZMQ.Signals` package with `Is_Interrupted`, `Set_Handler`, and `Reset_Handler`.

**Requirements trace:** R1, R2, R3, R4, R5, R6

**Dependencies:** None

**Files:**
- `src/czmq-low_level.ads` — add `zsys_interrupted` import and `zsys_handler_fn` type + `zsys_handler_set` / `zsys_handler_reset` imports
- `src/czmq-signals.ads` — new file: public spec for `CZMQ.Signals`
- `src/czmq-signals.adb` — new file: implementation body

**Approach:**

1. In `czmq-low_level.ads`, add the C variable import and handler function bindings after the existing `zsys_init` / `zsys_shutdown` declarations:

   ```ada
   --  Signal handling types and functions
   type zsys_handler_fn is access procedure with Convention => C;
   pragma Convention (C, zsys_handler_fn);

   procedure zsys_handler_set (handler_fn : zsys_handler_fn) with
     Import        => True,
     Convention    => C,
     External_Name => "zsys_handler_set";

   procedure zsys_handler_reset with
     Import        => True,
     Convention    => C,
     External_Name => "zsys_handler_reset";

   --  Global interrupt flag — set by CZMQ's signal handler on SIGINT/SIGTERM.
   --  Read this instead of using GNAT.Ctrl_C, which CZMQ silently overrides.
   Zsys_Interrupted : Interfaces.C.int
     with Import        => True,
          Convention    => C,
          External_Name => "zsys_interrupted";
   ```

   Note: `Zsys_Interrupted` is imported as `Interfaces.C.int` (not Boolean) because the C type is `volatile int`. The Ada wrapper converts it to Boolean.

2. Create `src/czmq-signals.ads`:

   ```ada
   --  CZMQ Ada Bindings - Signal Handling API
   --
   --  Provides a high-level Ada interface to CZMQ's interrupt detection
   --  and signal handler management. CZMQ installs its own SIGINT/SIGTERM
   --  handler during zsys_init (called when creating sockets), which
   --  silently overrides GNAT.Ctrl_C. Use Is_Interrupted to detect
   --  signals in CZMQ-based applications.
   --
   --  Copyright (c) 2026 Jochen Lillich <contact@geewiz.dev>
   --
   --  This Source Code Form is subject to the terms of the Mozilla Public
   --  License, v. 2.0. If a copy of the MPL was not distributed with this
   --  file, You can obtain one at http://mozilla.org/MPL/2.0/.

   package CZMQ.Signals is
      pragma Pure;

      --  Check if a SIGINT or SIGTERM signal has been received.
      --  Returns True after CZMQ's signal handler fires.
      --  Use this instead of GNAT.Ctrl_C in CZMQ-based applications.
      function Is_Interrupted return Boolean;

      --  Handler procedure type for custom signal callbacks.
      --  Convention => C is required for compatibility with CZMQ's handler API.
      type Handler_Type is access procedure with Convention => C;

      --  Set a custom interrupt handler. This saves the default handlers
      --  so that Reset_Handler can restore them later. Calling multiple times
      --  replaces the previous custom handler. Passing null disables CZMQ's
      --  default SIGINT/SIGTERM handling entirely.
      procedure Set_Handler (Handler : Handler_Type);

      --  Restore the default interrupt handlers that were active before
      --  Set_Handler was called. Call this at exit if you used Set_Handler.
      procedure Reset_Handler;

   end CZMQ.Signals;
   ```

3. Create `src/czmq-signals.adb`:

   ```ada
   --  CZMQ Ada Bindings - Signal Handling API Implementation
   --
   --  Copyright (c) 2026 Jochen Lillich <contact@geewiz.dev>
   --
   --  This Source Code Form is subject to the terms of the Mozilla Public
   --  License, v. 2.0. If a copy of the MPL was not distributed with this
   --  file, You can obtain one at http://mozilla.org/MPL/2.0/.

   with CZMQ.Low_Level;

   package body CZMQ.Signals is

      function Is_Interrupted return Boolean is
         use type Low_Level.C.int;
      begin
         return Low_Level.Zsys_Interrupted /= 0;
      end Is_Interrupted;

      procedure Set_Handler (Handler : Handler_Type) is
      begin
         Low_Level.zsys_handler_set (Low_Level.zsys_handler_fn (Handler));
      end Set_Handler;

      procedure Reset_Handler is
      begin
         Low_Level.zsys_handler_reset;
      end Reset_Handler;

   end CZMQ.Signals;
   ```

   The `Handler_Type` to `zsys_handler_fn` conversion is an unchecked conversion or a direct type conversion — both are `access procedure with Convention => C`, so a direct type conversion should work. If the compiler rejects it, use `Ada.Unchecked_Conversion`. This is a planning-time unknown (Q1 in the deferred section).

**Patterns:**
- Follow existing low-level binding pattern: `with Import, Convention => C, External_Name => "..."` — same as all other `zsys_*` bindings in `czmq-low_level.ads`
- Follow existing high-level package pattern: header comment, copyright, `pragma Pure`/`Preelaborate`, clean public API hiding C details
- Follow existing error style: no exceptions here — these functions cannot fail in CZMQ's API

**Test scenarios:**
- [ ] Happy path: `Is_Interrupted` returns `False` on startup (no signal received)
- [ ] Happy path: `Reset_Handler` can be called without prior `Set_Handler` (no crash)
- [ ] Edge case: `Set_Handler` with `null` disables default handling (CZMQ documented behavior)
- [ ] Integration: `Is_Interrupted` is callable before any socket creation (R6)

**Verification:**
- `alr build` compiles the library with the new `czmq-signals.ads` and `czmq-signals.adb` files
- `with CZMQ.Signals;` compiles in a test program without errors
- `Is_Interrupted` returns `False` when called before any signal

**Planning-time unknowns:**
- Q1: `Handler_Type` to `zsys_handler_fn` conversion — both are `access procedure with Convention => C`, but they are different Ada types. Direct conversion may work; if not, `Ada.Unchecked_Conversion` will. **Deferred to implementation** — this is a mechanical compiler-acceptance question, not a design decision.

---

### Unit 2: Test File for CZMQ.Signals

**Goal:** Add `test_signals.adb` to the test suite covering the `CZMQ.Signals` API.

**Requirements trace:** R1, R3, R4, R6

**Dependencies:** Unit 1

**Files:**
- `tests/test_signals.adb` — new file: tests for CZMQ.Signals
- `tests/tests.gpr` — add `"test_signals.adb"` to the `Main` list

**Approach:**

1. Create `tests/test_signals.adb` following the existing test pattern (custom Assert, Pass/Fail counters, Program_Error on failure):

   ```ada
   --  Tests for CZMQ.Signals
   --
   --  Tests interrupt detection and signal handler management.

   with Ada.Text_IO;
   with CZMQ.Signals;

   procedure Test_Signals is

      use Ada.Text_IO;

      Pass_Count : Natural := 0;
      Fail_Count : Natural := 0;

      procedure Assert (Condition : Boolean; Description : String) is
      begin
         if Condition then
            Pass_Count := Pass_Count + 1;
            Put_Line ("  PASS: " & Description);
         else
            Fail_Count := Fail_Count + 1;
            Put_Line ("  FAIL: " & Description);
         end if;
      end Assert;

      --  Custom handler for testing Set_Handler
      Signal_Count : Natural := 0;
      procedure Custom_Handler with Convention => C is
      begin
         Signal_Count := Signal_Count + 1;
      end Custom_Handler;

   begin
      Put_Line ("=== CZMQ.Signals Tests ===");
      Put_Line ("");

      --  Test 1: Is_Interrupted returns False before any signal
      Put_Line ("-- Is_Interrupted initial state --");
      Assert (not CZMQ.Signals.Is_Interrupted,
              "Is_Interrupted returns False on startup");

      Put_Line ("");

      --  Test 2: Is_Interrupted is callable without socket creation
      --  (This implicitly tests R6 — no CZMQ initialization needed)
      Put_Line ("-- Is_Interrupted without socket --");
      declare
         --  Deliberately no socket creation — just check the global
         Result : Boolean := CZMQ.Signals.Is_Interrupted;
      begin
         Assert (not Result,
                 "Is_Interrupted works without socket creation");
      end;

      Put_Line ("");

      --  Test 3: Set_Handler with custom handler
      Put_Line ("-- Set_Handler with custom handler --");
      declare
         Handler : constant CZMQ.Signals.Handler_Type :=
                     Custom_Handler'Unrestricted_Access;
      begin
         CZMQ.Signals.Set_Handler (Handler);
         Assert (True, "Set_Handler accepts custom handler");
         CZMQ.Signals.Reset_Handler;
         Assert (True, "Reset_Handler succeeds after Set_Handler");
      end;

      Put_Line ("");

      --  Test 4: Set_Handler with null disables default handling
      Put_Line ("-- Set_Handler with null --");
      begin
         CZMQ.Signals.Set_Handler (null);
         Assert (True, "Set_Handler accepts null (disables default)");
         CZMQ.Signals.Reset_Handler;
         Assert (True, "Reset_Handler restores after null handler");
      end;

      Put_Line ("");

      --  Test 5: Reset_Handler without prior Set_Handler
      Put_Line ("-- Reset_Handler without Set_Handler --");
      begin
         CZMQ.Signals.Reset_Handler;
         Assert (True, "Reset_Handler works without prior Set_Handler");
      end;

      Put_Line ("");

      --  Summary
      Put_Line ("=== Results: " & Natural'Image (Pass_Count) & " passed," &
                Natural'Image (Fail_Count) & " failed ===");

      if Fail_Count > 0 then
         raise Program_Error with "Test failures detected";
      end if;
   end Test_Signals;
   ```

2. Add `"test_signals.adb"` to the `for Main use (...)` list in `tests/tests.gpr`.

**Patterns:**
- Follow existing test pattern from `test_sockets.adb`: custom Assert, Pass/Fail counters, `Program_Error` on failure
- Follow existing naming convention: `test_<component>.adb` → `test_signals.adb`
- Note: Cannot easily test `Is_Interrupted = True` in a unit test without actually sending SIGINT, which would terminate the test process. The True-path must be tested in integration/manual testing. The False-path exercises the same code (reads the global, converts to Boolean), so the logic is covered; only the signal-triggered state change is untestable in isolation.

**Test scenarios:**
- [ ] Happy path: `Is_Interrupted` returns `False` before any signal
- [ ] Integration: `Is_Interrupted` works without creating any socket (R6)
- [ ] Happy path: `Set_Handler` accepts custom handler procedure
- [ ] Edge case: `Set_Handler (null)` disables default handling without crash
- [ ] Cleanup: `Reset_Handler` works after `Set_Handler`
- [ ] Cleanup: `Reset_Handler` works without prior `Set_Handler`

**Verification:**
- `cd tests && alr build` compiles including `test_signals.adb`
- `bin/test_signals` passes all assertions

**Planning-time unknowns:**
- Q1: `Custom_Handler'Unrestricted_Access` — needed because `Custom_Handler` is a local procedure. `Access` would require the procedure to be at library level. `Unrestricted_Access` is a GNAT extension. If this is rejected by the compiler, move `Custom_Handler` to the package spec level. **Deferred to implementation** — mechanical compiler issue.

---

## Quality Bar Checklist

- [x] Every unit has a requirements trace (R1–R6 mapped above)
- [x] Dependencies form a DAG (Unit 2 depends on Unit 1; no cycles)
- [x] Every unit has at least 3 test scenarios (4 for Unit 1, 6 for Unit 2)
- [x] No unit touches >8 files (Unit 1: 3 files, Unit 2: 2 files)
- [x] No more than 2 new abstractions introduced per unit (Unit 1: 1 new abstraction — `Handler_Type`; Unit 2: 0 new abstractions)
- [x] Every planning-time unknown is classified (2 deferred to implementation; 0 blockers)
- [x] Handoff completeness test: an engineer would not need to invent product behavior — only resolve the two mechanical compiler-acceptance questions and write the code shown

---

## Critical Design Note

### Why `zsys_interrupted` (volatile int) instead of `zsys_is_interrupted` (function)

The CZMQ C API provides both:
- `extern volatile int zsys_interrupted` — stable since CZMQ 2.x, part of the public API
- `bool zsys_is_interrupted (void)` — draft API, marked "may change without warning"

Binding the stable global variable is the right choice. The `volatile` qualifier is critical — it tells the C compiler not to cache the value, which is essential because the signal handler modifies it asynchronously. The Ada import will read the current value on each call.

The C global is zero-initialized at program start by the C runtime. This means `Is_Interrupted` returns `False` even before `zsys_init` is called — no prior CZMQ initialization is required (R6).

### Why `pragma Preelaborate` (not `pragma Pure`)

`CZMQ.Signals` uses `pragma Preelaborate` rather than `pragma Pure`. Although the package itself has no state or elaboration side effects, GNAT enforces the Ada RM rule that a Pure unit cannot depend on a non-Pure unit — and `CZMQ.Low_Level` is `pragma Preelaborate`. `Preelaborate` is equally functional for this library's use case; the only difference is slightly reduced composability in pure-functional Ada contexts, which this library doesn't use.

---

## Next Steps

1. Implement Unit 1 (Low_Level bindings + CZMQ.Signals package).
2. Implement Unit 2 (test file + gpr update).
3. Build and run: `alr build && cd tests && alr build && bin/test_signals`.
4. Open a PR referencing Issue #14.
