# CZMQ.Signals Package — Requirements

**Version:** 1.0
**Status:** Draft
**Date:** 2026-05-09

## Problem Frame

CZMQ's `zsys_init` (called during socket creation) installs its own SIGINT/SIGTERM handler via `sigaction`, silently overwriting any handler installed via `GNAT.Ctrl_C.Install_Handler`. This makes the Ada-native signal handling approach a dead end for CZMQ-based applications. The only working approach is to check the C global variable `zsys_interrupted` directly, but that requires users to know this CZMQ implementation detail and manually import a C global — contradicting the library's goal of providing a clean, high-level Ada API.

## Requirements

| ID | Requirement | Priority | Notes |
|----|-------------|----------|-------|
| R1 | Provide `Is_Interrupted` function returning Boolean, reflecting the state of C's `volatile int zsys_interrupted` | Must Have | Core API — the single function most users need |
| R2 | Bind `zsys_interrupted` in `CZMQ.Low_Level` as an imported C variable | Must Have | Required implementation detail for R1 |
| R3 | Provide `Set_Handler` procedure to register a custom interrupt handler (wraps `zsys_handler_set`) | Should Have | Advanced use: users who want custom signal behavior |
| R4 | Provide `Reset_Handler` procedure to restore default handlers (wraps `zsys_handler_reset`) | Should Have | Cleanup counterpart to Set_Handler |
| R5 | Package name must not collide with Ada's predefined `System` package | Must Have | Rules out `CZMQ.System`; chosen name is `CZMQ.Signals` |
| R6 | Package must be usable without prior CZMQ socket creation | Must Have | `zsys_interrupted` is a global — checking it should not require a socket |

## Success Criteria

- `CZMQ.Signals.Is_Interrupted` returns `False` before any signal, `True` after SIGINT/SIGTERM
- No direct C imports needed in user code for interrupt detection
- `GNAT.Ctrl_C.Install_Handler` documentation is unnecessary — the CZMQ-sanctioned approach is the obvious one
- Existing test suite passes without modification

## Scope Boundaries

**In scope:**
- New `CZMQ.Signals` package with `Is_Interrupted` function
- Low-level binding of `zsys_interrupted` global variable
- `Set_Handler` / `Reset_Handler` wrapping `zsys_handler_set` / `zsys_handler_reset`
- Test file `test_signals.adb`

**Out of scope:**
- Binding `zsys_catch_interrupts` (marked "CZMQ internal use only" in C docs)
- Binding `zsys_is_interrupted` (draft API, may change without warning)
- Binding `zsys_set_interrupted` (draft API)
- Any other `zsys_*` functions (logging, file utils, etc.)
- Replacing or wrapping `GNAT.Ctrl_C` — CZMQ owns signal handling in this context

## Key Decisions

| Decision | Chosen | Rationale | Alternatives Considered |
|----------|--------|-----------|------------------------|
| Package name | `CZMQ.Signals` | Avoids collision with Ada's `System` package; describes the domain clearly | `CZMQ.System` (collision), `CZMQ.OS` (too broad), `CZMQ.Interrupts` (too narrow) |
| Interrupt source | Bind `volatile int zsys_interrupted` directly | Stable API since CZMQ 2.x; `zsys_is_interrupted()` is draft-only | `zsys_is_interrupted()` function (draft, may change) |
| Handler callback type | Access-to-procedure with C convention | Matches CZMQ's `zsys_handler_fn` signature; Ada convention => C convention mapping is well-defined | Skip handler API entirely (too limiting for advanced users) |
| Package categorization | `pragma Pure` | Package is stateless — only wraps reads of a C global and calls to C functions. No `Limited_Controlled` state. | `pragma Preelaborate` (unnecessary — no elaboration-time side effects needed) |

## Outstanding Questions

| # | Question | Impact if Wrong | Owner |
|---|----------|-----------------|-------|
| Q1 | Does `pragma Pure` work for a package that reads a volatile C global? | If not, must use `pragma Preelaborate`; Pure is preferred for composability | Jochen |
| Q2 | Should `Set_Handler` accept `null` to disable default CZMQ signal handling? | CZMQ's `zsys_handler_set(NULL)` disables default handling — useful but footgun-prone | Jochen |
