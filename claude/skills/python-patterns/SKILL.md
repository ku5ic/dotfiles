---
name: python-patterns
description: Python language-level patterns covering type hints, strictness, project layout, async, error handling, packaging, and review-worthy anti-patterns. Use whenever the user writes, reviews, or audits Python code, asks about type hints, mypy, pyright, async, packaging, pyproject.toml, project structure, or any work in a .py file, even if "Python" is not mentioned by name.
---

# Python patterns

Default assumption: Python 3.11 or later, type hints required on public function signatures, mypy or pyright in strict mode. 3.11 is the floor because TaskGroup, `Self`, `StrEnum`, and `ExceptionGroup` all landed there. 3.14 (current stable, released 2025-10-07) made deferred annotation evaluation the default; on older supported versions the `from __future__ import annotations` import is still useful for forward references.

## Type hints

- Built-in generics over `typing` aliases. `list[str]`, `dict[str, int]`, `tuple[int, ...]`. PEP 585, 3.9+.
- `from typing import Self` for fluent APIs and factory methods (3.11+, PEP 673). Cleaner than `TypeVar` bounded on the class.
- `from __future__ import annotations` on 3.11-3.13 to turn annotations into strings -- helps with forward references and self-referential types. On 3.14 this is unnecessary and on a deprecation path (PEP 749); deferred evaluation is the default (PEP 649).
- New generic syntax in 3.12+ (PEP 695): `type Pair[T] = tuple[T, T]` and `class Container[T]:` instead of `TypeVar("T")` + `Generic[T]`. Use it when the floor is 3.12; keep `TypeVar` when supporting 3.11.
- `TypedDict` for dict shapes at trust boundaries (config files, JSON payloads). `dataclass(frozen=True, slots=True)` for internal value objects (`slots=True` is 3.10+). `pydantic.BaseModel` (v2) when validation is part of the contract.
- `Protocol` over `abc.ABC` for structural typing. Lets callers satisfy the type without inheriting.
- `Annotated[T, metadata]` for runtime-introspectable hints. Pydantic v2 and FastAPI use this heavily (e.g. `PositiveInt = Annotated[int, Gt(0)]`).
- Generic constraints: `T = TypeVar("T", bound=BaseClass)` for the legacy syntax; `class Repo[T: BaseClass]:` for the PEP 695 form.

## Strictness

- mypy `--strict` or pyright `strict` mode is the baseline. Strict-off on a package is a `failure` for any new code path.
- mypy `--strict` is an umbrella; among other flags it enables `--disallow-untyped-defs`, `--disallow-any-generics`, `--warn-return-any`, `--warn-unused-ignores`, `--strict-equality`, `--no-implicit-reexport`.
- `# type: ignore[error-code]` over bare `# type: ignore`. The bracketed form documents the intent and lets `--warn-unused-ignores` catch stale suppressions.
- `Any` in a public function signature is a `failure`. Internal `Any` with a one-line comment is acceptable when interop demands it.
- `cast(X, value)` is a smell unless the runtime invariant is documented adjacent to the call.
- Ruff is the linter and formatter for new Python projects. It consolidates Flake8 (plus plugins), Black, isort, pydocstyle, pyupgrade, autoflake, with 800+ rules. Linter and formatter are one tool, two subcommands.

## Project layout

- `src/` layout for libraries and any project that will be packaged. PyPA documents three benefits, the load-bearing one being that it prevents accidentally importing the in-development source instead of the installed package. Flat layout is fine for scripts and small applications.
- `pyproject.toml` is the single source of truth. PEP 518 standardizes `[build-system]`; PEP 621 standardizes `[project]` metadata. No `setup.py` for new projects.
- Tool config consolidated in `pyproject.toml`: `[tool.ruff]`, `[tool.mypy]`, `[tool.pyright]`, `[tool.pytest.ini_options]`. Avoid scattering across `setup.cfg`, `mypy.ini`, `pytest.ini` unless a tool requires it.
- Dependency manager: uv (faster, single-tool replacement for pip/pip-tools/pipx/poetry/pyenv/twine/virtualenv) or Poetry (established, 2.x reads dependencies from `[project]` per PEP 621). Both ship lockfiles (`uv.lock`, `poetry.lock`) -- commit them. `requirements.txt` is acceptable as a deployment artifact, not as a development workflow.

## Async

- `async def` is contagious. Sync I/O in an async function blocks the event loop. `time.sleep` in async is `failure`; use `await asyncio.sleep`. Synchronous `requests` in async is `warning`; use `httpx` (sync + async API) or `aiohttp`.
- `asyncio.gather(*aws)` for parallel I/O without structured cancellation. `asyncio.TaskGroup` (3.11+, motivated by PEP 654) for structured concurrency: cancellations propagate, and child failures are collected as an `ExceptionGroup`.
- `asyncio.to_thread(func, *args)` (3.9+) wraps a sync blocking call so it runs in a thread without blocking the loop.
- `async with` for async context managers, `async for` for async iterators. Do not call sync `open(...)` on a hot path inside async; use `aiofiles` or hand off via `to_thread`.
- Never call `asyncio.run(...)` inside a running event loop. From a coroutine, `await` directly; from sync code already inside a loop, schedule via `loop.create_task` or `asyncio.ensure_future`.
- `anyio` (v4) when the code must run under both asyncio and trio. Useful for libraries; over-engineering for application code that owns its loop.

## Errors

- Specific exception types. Bare `except:` is `failure` (it catches `KeyboardInterrupt` and `SystemExit`). `except Exception:` only at the top of a request / job boundary.
- Custom hierarchy: a base `AppError` with named subclasses (`ValidationError`, `NotFoundError`, etc.). Lets callers handle categories without string-matching messages.
- `raise NewError(...) from original` to chain. Preserves the cause; tracebacks show both.
- `try/finally` for cleanup; `with` for context-managed resources. A `with` block is almost always cleaner than the matching `try/finally`.
- Exceptions for control flow on hot paths: PEP 657 (3.11) made the success path effectively zero-cost, but raised exceptions still allocate frames. `LBYL` (look-before-you-leap) when the check is cheap; `EAFP` (try/except) when it isn't.
- `logger.exception("message")` inside an `except` block. It includes the traceback; `logger.error(str(e))` does not.

## Packaging and imports

- Absolute imports inside packages. Relative imports (`from .util import x`) acceptable only for tight intra-package coupling.
- `__init__.py` empty unless re-exporting is intentional. A package that re-exports from submodules is making an API promise; document it.
- `__all__` only when publishing a public API. It controls `from package import *` and signals intent to type-checkers and IDEs.
- Circular imports: detect with Ruff (rules in the `TID`/`F` series), `pylint`, or `pydeps` for visualizing the import graph. Fix by moving the shared symbol to a third module, not by deferring imports inside functions.

## Common patterns

- `@dataclass(frozen=True, slots=True)` is the default for value objects (`slots=True` is 3.10+). Mutable dataclasses only when mutation is the point.
- `enum.Enum` for closed sets. `enum.StrEnum` (3.11+) when the enum value must serialize as its own string (JSON, query params, log fields).
- `pathlib.Path` over `os.path`. `Path("dir") / "file.txt"`, `path.read_text()`, `path.glob("*.py")` -- all clearer than the string-juggling equivalents.
- Context managers: `@contextlib.contextmanager` for one-off setup/teardown; full `__enter__` / `__exit__` class for reusable infrastructure.
- `functools.cache` (3.9+) for unbounded memoization, `functools.lru_cache(maxsize=N)` when the cache must be bounded.
- `itertools.pairwise(it)` (3.10+) for adjacent pairs, `itertools.batched(it, n)` (3.12+) for fixed-size chunks. Both replace common hand-rolled loops.

## Anti-patterns to flag

- Mutable default arguments: `def f(x=[]):`, `def f(x={}):`. The default is shared across calls. `failure`. Use `None` and reassign inside the body.
- Bare `except:` or `except Exception: pass`. Errors disappear silently. `failure`.
- `from x import *` outside test fixtures or REPL. Pollutes the namespace; defeats lints. `warning`.
- `== None`, `!= None`. Use `is None` / `is not None`. `warning`. (Ruff `E711`.)
- Truthiness check where empty-vs-missing matters. `if value:` is False for `0`, `""`, `[]`, `{}`, AND `None`. Be explicit: `if value is None`, `if not value`, etc. `warning`.
- `dict.get(key)` followed by a `None` check when `KeyError` would be the correct signal. The exception is louder than a missed branch. `info`.
- `Optional[X] = None` parameter that callers must always provide. The type is lying. `info`. Use `X` and let mypy enforce.
- `time.sleep(...)` in `async def`. Blocks the event loop. `failure`. Use `await asyncio.sleep(...)`.
- Synchronous `requests.get/post` in `async def`. Blocks the event loop. `warning`. Use `httpx.AsyncClient` or `aiohttp.ClientSession`.
- Calling a sync blocking function (DB query, slow file I/O, third-party SDK) directly inside `async def`. `warning`. Wrap with `await asyncio.to_thread(func, ...)` or use the library's async API.
- Class with only `__init__` and one method. Should be a function. `info`.
- Module-level mutable state (`_cache = {}`) without synchronization. Concurrency hazard, doubly so under free-threaded 3.13+. `warning`.
- Tall inheritance hierarchies (3+ levels of `class A(B(C)):`) for code reuse. Prefer composition. `info`.

## Testing-adjacent

For test code review; depth lives in `test-patterns`.

- `pytest` over `unittest.TestCase`. Fewer ceremonies; better fixtures; better parametrize.
- Fixture scope: `function` (default) unless setup is genuinely expensive. `module` / `session` scopes share state and create order coupling.
- `monkeypatch` for clean test-local mutations of env vars, attributes, and module-level singletons. Auto-reverts.
- `@pytest.mark.parametrize("input,expected", [...], ids=[...])`. The `ids` argument keeps test names readable when the inputs are objects.
- Factory Boy (`factory.django.DjangoModelFactory`) or model_bakery for Django model fixtures. Stop hand-writing `Model.objects.create(...)` in every test.

## When to load this skill

- Any work in a `.py` file.
- Code review of Python with type hints, async, packaging.
- Edits to `pyproject.toml`, `requirements.txt`, `uv.lock`, `poetry.lock`.
- Migrations between Python versions (3.10 -> 3.11+ for TaskGroup; 3.11 -> 3.12 for PEP 695 syntax).

## When not to load this skill

- Pure Django ORM / view / template work where `django-patterns` is the primary. (Still load both for type-hint review.)
- Trivial Python utility scripts under 50 lines with no public API surface.
- Non-Python code with a `.py` file in the working directory by accident (build scripts in vendored projects).

## References

- PEP index: https://peps.python.org/
- Python `What's New` (current stable): https://docs.python.org/3/whatsnew/
- mypy command line: https://mypy.readthedocs.io/en/stable/command_line.html
- pyright configuration: https://microsoft.github.io/pyright/
- Ruff rules: https://docs.astral.sh/ruff/rules/
- uv docs: https://docs.astral.sh/uv/
- PyPA src vs flat: https://packaging.python.org/en/latest/discussions/src-layout-vs-flat-layout/

When Python evolves -- new minor each October -- reconcile this skill against the current `whatsnew` page and the PEP index before trusting the deltas above. The 3.14 deferred-annotation default is the largest near-term shift; once 3.13 reaches EOL, the floor here can move and the `from __future__` paragraph can be removed.
