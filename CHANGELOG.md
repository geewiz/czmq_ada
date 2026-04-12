# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

### Fixed

- `zpoller_new` binding now includes a mandatory NULL terminator parameter to
  match the variadic C signature, preventing stack corruption and crashes
  ([#2](https://github.com/geewiz/czmq_ada/issues/2)).

## v0.3.0 - 2026-03-14

[Changes since v0.2.0](https://github.com/geewiz/czmq_ada/compare/v0.2.0...v0.3.0)

### Added

- `Set_Identity` procedure on `CZMQ.Sockets` for DEALER/ROUTER socket routing identity.
- Test suite for general socket options (`test_sockets`).
- CI now builds and runs all tests.

### Changed

- `Certificate."="` operator replaced with named `Equal` function for
  portability across GNAT versions. Older GNATs reject `overriding` on the
  predefined `"="` of `Limited_Controlled`, while GNAT 15 requires it.
- Test binaries are now built to `tests/bin/` instead of `tests/`.
- CI workflow uses `alire-project/setup-alire` action instead of
  system-packaged GNAT.

## v0.2.0 - 2026-03-12

[Changes since v0.1.0](https://github.com/geewiz/czmq_ada/compare/v0.1.0...v0.2.0)

### Added

- CURVE encryption support via new `CZMQ.Certificates` package (generate,
  load, save, apply, and compare keypairs).
- `CZMQ.Authentication` package wrapping the `zauth` ZAP authenticator actor
  (CURVE and PLAIN authentication).
- Socket security options: `Set_Curve_Server`, `Set_Curve_Serverkey`,
  `Set_Zap_Domain`, `Set_Plain_Server`, `Set_Plain_Username`,
  `Set_Plain_Password`.
- Test suite with 37 tests across three test programs.

## v0.1.0 - 2025-12-27

[Initial release](https://github.com/geewiz/czmq_ada/releases/tag/v0.1.0)

### Added

- High-level `CZMQ.Sockets` package with RAII-managed sockets (PUB, SUB, REQ,
  REP, PUSH, PULL, DEALER, ROUTER, PAIR, XPUB, XSUB, STREAM).
- `CZMQ.Messages` package for multipart message handling.
- `CZMQ.Low_Level` thin binding to the CZMQ C API.
- Alire package manifest.
- PUB/SUB and PUSH/PULL example programs.
