---
name: e2e-bats-port
description: claude-kit bats -> Go e2e port conventions (build tag, per-file helper prefixes, no-jq tests run the built binary)
metadata:
  type: project
---

Bats tests in claude-kit/tests are being ported to Go e2e tests in claude-kit/go/e2e, several agents in parallel.

**Why:** hooks/bin were rewritten as one Go binary `kit`; shims source bin/kit which runs the committed kit-<os>-<arch>, not the freshly built one.

**How to apply:** new files start with `//go:build port_status`; helpers are closures or funcs prefixed with the file name; bats setup() maps to a fresh New(t) per t.Run when tests mutate state; "without jq on PATH" tests run `k.Run` with `k.Setenv("PATH", t.TempDir())` instead of the shim. Build tags differ per agent batch (port_status, port_guards, ...). A later k.Setenv of the same key overrides an earlier one (exec keeps the last), so per-subtest env overrides work; bats `yq` over kit.yml maps to go.yaml.in/yaml/v3 (already in go.mod). Verify names with a diff of bats `@test` names (spaces -> `_`) vs `go test -v` subtest names.
