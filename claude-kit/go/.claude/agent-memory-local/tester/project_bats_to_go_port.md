---
name: bats-to-go-e2e-port
description: How claude-kit bats tests are ported to Go e2e tests (build tags, harness mapping, gotchas)
metadata:
  type: project
---

claude-kit bats tests are being ported to Go e2e tests in claude-kit/go/e2e, one file per bats file, per-agent build tag (e.g. `//go:build port_guardbash`) while agents work concurrently.

**Why:** hooks/bin moved to one Go binary `kit`; bats is being retired.

**How to apply:**
- Harness: New(t)/NewPlugin(t), k.Hook(name, Payload(...)), Result.Want/Has/Lacks/Empty. Payload's empty cwd -> hook uses process cwd (k.Dir = fake Home).
- Most guard-bash bats tests ran against the developer's real HOME (no kit_test_home); the Go sandbox is stricter and still passed.
- bats test names with `\$` display as `$`; use `$` in Go subtest names.
- k.PrependPath builds from os.Getenv("PATH"), so a second call replaces the first (last env key wins); combine dirs in one call.
- A test that must exercise a shim's own path logic against the fresh binary: copy bin/<shim>.sh + bin/kit to a temp dir (chmod 0755) and symlink kit-<GOOS>-<GOARCH> -> kitBin.
- inject-context's rules-linked prereq finds the kit rules at <real exe dir>/../rules, so kitBin (in a bare temp dir) always warns; hardlink kitBin into <tmp>/bin/kit-<os>-<arch> with <tmp>/rules -> kitRoot/rules and run that (a symlink to kitBin doesn't help, it's EvalSymlinks'd).
- Write/Edit tool input decodes `\uXXXX` in Go source into literal chars, which sanitize-output then strips; build them as string(rune(0x2014)).
- Harness env passes the go test process's PWD through; kit uses os.Getwd (honors $PWD). To mimic bats `cd` with a logical (non-physical) path, set k.Dir and k.Setenv("PWD", dir); last duplicate env key wins.
- Put fixture repos in a separate t.TempDir(), not under k.Home (bats fixtures were siblings of $HOME; matters for outside-HOME and sentinel-walk tests). Always `git init -b main`.
- Verify 1:1 port: sed the @test names, replace spaces with _, diff against `--- PASS: TestX/` lines of `go test -v`.
- Generating big simple tables from bats with a python+shlex script in scratch saves time; `$'...'` strings need hand conversion.
