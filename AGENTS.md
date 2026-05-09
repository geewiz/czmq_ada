# AGENTS.md

## Build & Test Environment

All build/test commands must run inside the `ada_dev` distrobox:

```bash
distrobox enter ada_dev -- alr build
```

**Prerequisite:** CZMQ dev library must be installed (`libczmq-dev` on Debian/Ubuntu, `czmq-devel` on Fedora).

## Commands

```bash
# Build library
alr build

# Build tests (from tests/ directory)
cd tests && alr build

# Run a single test
cd tests && bin/test_sockets

# Run all tests
cd tests && for t in bin/test_*; do $t; done

# Build examples
cd examples && alr build
```

No linter, formatter, or typecheck commands — GNAT warnings are controlled via the `.gpr` files.

## Package Architecture

```
czmq.ads              Root package (pragma Pure) — defines CZMQ_Error exception
czmq-low_level.ads    Thin C bindings (pragma Preelaborate) — no body file
czmq-signals.ads/.adb High-level wrappers (pragma Preelaborate)
czmq-sockets.ads/.adb High-level wrappers (no pragma)
czmq-messages.ads/.adb   "
czmq-certificates.ads/.adb   "
czmq-pollers.ads/.adb   "
czmq-authentication.ads/.adb   "
```

- **`czmq.ads`** (`pragma Pure`) and **`czmq-low_level.ads`** (`pragma Preelaborate`) are the only packages with categorization pragmas
- High-level wrapper packages extend `Ada.Finalization.Limited_Controlled` (except `CZMQ.Signals` which is stateless)
- `czmq_ada.gpr` auto-discovers all files in `src/` — no changes needed when adding a new package there

## Adding a New High-Level Package

1. Create `src/czmq-<name>.ads` and `src/czmq-<name>.adb`
2. Use `pragma Preelaborate` if the package has no `Limited_Controlled` types; otherwise omit pragma
3. If the package depends on `CZMQ.Low_Level`, it must be `pragma Preelaborate` (not `pragma Pure`) because a Pure unit cannot depend on a non-Pure unit
4. Create `tests/test_<name>.adb` following the custom Assert pattern (see existing test files)
5. **Add the test binary to `tests/tests.gpr`** in the `for Main use (...)` list — this is not auto-discovered
6. If adding C bindings, put them in `czmq-low_level.ads` — follow the existing `with Import, Convention => C, External_Name => "..."` pattern

## Ada/GNAT Quirks

- **3-space indentation** throughout the codebase — do not use 4-space
- **`with Convention => C` aspect** on a procedure requires a separate spec + `pragma Convention` instead. Use the pragma form for test callbacks and local C-convention procedures
- **`'Access` on local procedures** fails — use `'Unrestricted_Access` (GNAT extension) or move the procedure to library level
- **`-gnatwK`** is disabled in `tests/tests.gpr` because `Limited_Controlled` test variables trigger false "could be declared constant" warnings
- **Close must null the handle**: When adding a `Close` procedure to a `Limited_Controlled` type, always set `Self.Handle := null` after calling the C destroy function. Otherwise `Finalize` will double-free when the object goes out of scope

## Error Conventions

- `raise CZMQ_Error with "..."` — runtime failures from CZMQ operations (invalid handle, C function returned error)
- `raise Program_Error with "..."` — precondition violations (calling Open on already-open object)
- All high-level operations check `Self.Handle /= null` first and raise `CZMQ_Error` if invalid

## C-String Pattern

Always allocate C strings for CZMQ calls, even empty ones — `""` in C is not `NULL`:

```ada
C_Str : CS.chars_ptr := CS.New_String (Value);
--  Use C_Str...
CS.Free (C_Str);
```

For optional endpoints: only allocate if the string is non-empty (`if Endpoint /= "" then C_Endpoint := CS.New_String (Endpoint); end if;`), because CZMQ treats `NULL` as "no endpoint". But for subscription filters: always allocate (empty string `""` means "subscribe to all", `NULL` means "no subscription").

## Implementation workflow

- Create issue branch
- Implement feature/fix
- Update changelog under `## Unreleased` heading

## Release Workflow

1. Update `version` in `alire.toml`
2. Update `CHANGELOG.md`: rename `## Unreleased` to `## vN.N.N - YYYY-MM-DD`
3. Review `README.md` for necessary updates
4. Commit, push
5. Ask user to submit the new release to Alire
