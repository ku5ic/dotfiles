---
name: python-patterns
description: Python language-level patterns covering type hints, strictness, project layout, async, error handling, packaging, and review-worthy anti-patterns. Use whenever the project contains `.py` files, `pyproject.toml`, `requirements.txt`, `Pipfile`, `uv.lock`, `poetry.lock`, OR the user asks about Python, type hints, mypy, pyright, async, packaging, project structure, or any work in a `.py` file, even if "Python" is not mentioned by name.
---

# Python patterns

Default assumption: Python 3.11 or later, type hints required on public function signatures, mypy or pyright in strict mode. 3.11 is the floor because TaskGroup, `Self`, `StrEnum`, and `ExceptionGroup` all landed there. 3.14 (current stable, released 2025-10-07) made deferred annotation evaluation the default; on older supported versions the `from __future__ import annotations` import is still useful for forward references.

## Severity rubric

- `failure`: a concrete defect or violation that should not ship.
- `warning`: a smell or pattern that compounds with other findings.
- `info`: a hardening opportunity or note, not a defect.

## Reference files

| File                                                         | Covers                                                                                         |
| ------------------------------------------------------------ | ---------------------------------------------------------------------------------------------- |
| [reference/typing.md](reference/typing.md)                   | Type hints, strictness, mypy/pyright per-module overrides                                      |
| [reference/project-layout.md](reference/project-layout.md)   | `src/` layout, `pyproject.toml`, packaging, `py.typed` (PEP 561), namespace packages (PEP 420) |
| [reference/async.md](reference/async.md)                     | `async def` hazards, `TaskGroup`, `anyio` cancellation scopes                                  |
| [reference/errors.md](reference/errors.md)                   | Exception design, chaining, LBYL vs EAFP, `logger.exception`                                   |
| [reference/common-patterns.md](reference/common-patterns.md) | Dataclasses, enums, `pathlib`, `functools.cache`, Pydantic v2 patterns                         |
| [reference/anti-patterns.md](reference/anti-patterns.md)     | Thirteen language anti-patterns, free-threaded build implications, testing-adjacent items      |

## When to load this skill

- Any work in a `.py` file.
- Code review of Python with type hints, async, packaging.
- Edits to `pyproject.toml`, `requirements.txt`, `uv.lock`, `poetry.lock`.
- Migrations between Python versions (3.10 -> 3.11+ for TaskGroup; 3.11 -> 3.12 for PEP 695 syntax).

## When not to load this skill

- Trivial Python utility scripts under 50 lines with no public API surface.
- Non-Python code with a `.py` file in the working directory by accident (build scripts in vendored projects).

## References

- PEP index: https://peps.python.org/
- Python `What's New` (current stable): https://docs.python.org/3/whatsnew/
- mypy command line: https://mypy.readthedocs.io/en/stable/command_line.html
- mypy config (per-module overrides): https://mypy.readthedocs.io/en/stable/config_file.html
- pyright configuration: https://microsoft.github.io/pyright/
- Ruff rules: https://docs.astral.sh/ruff/rules/
- uv docs: https://docs.astral.sh/uv/
- PyPA src vs flat: https://packaging.python.org/en/latest/discussions/src-layout-vs-flat-layout/
- Pydantic v2 models: https://pydantic.dev/docs/validation/latest/concepts/models/

## Maintenance note

When Python evolves -- new minor each October -- reconcile this skill against the current `whatsnew` page and the PEP index before trusting the deltas above. The 3.14 deferred-annotation default is the largest near-term shift; once 3.13 reaches EOL, the floor here can move and the `from __future__` paragraph can be removed. Free-threaded Python graduated from experimental in 3.13 to officially supported in 3.14 per PEP 779; module-level mutable state without synchronization is more clearly a hazard now than it was on the GIL-only runtime.
