---
name: logging-patterns
description: >
  Python logging patterns covering stdlib logging configuration, structured
  logging with structlog, log levels, handlers, formatters, and context binding.
  Use whenever a project uses Python logging, structlog, or the user asks about
  log levels, log formatting, structured logs, or JSON logging, even if
  "logging" is not mentioned by name.
---

# Logging Patterns

## When to load this skill

- Python project with `import logging` or `import structlog`
- User asks about log levels, log formatting, structured logs, or JSON logging
- User asks why logs appear twice or why a logger is silent
- User is configuring a logging handler, formatter, or filter

## When not to load this skill

- JavaScript/Node.js logging (pino, winston, console)
- Infrastructure log aggregation configuration (Loki, Elasticsearch)

---

## stdlib logging

### Logger setup

Get a module-level logger. Never use the root logger directly in library code.

```python
import logging

logger = logging.getLogger(__name__)
```

### Log levels

| Level    | Value | When to use                           |
| -------- | ----- | ------------------------------------- |
| DEBUG    | 10    | Detailed diagnostic info, dev only    |
| INFO     | 20    | Routine operational events            |
| WARNING  | 30    | Something unexpected but recoverable  |
| ERROR    | 40    | Operation failed, execution continues |
| CRITICAL | 50    | Application cannot continue           |

### Application bootstrap (call once at startup)

```python
import logging

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%S",
)
```

`basicConfig` only takes effect if the root logger has no handlers. Call it exactly once at the entry point. Pass `force=True` to replace existing handlers (useful in tests).

### Rotating file handler

```python
from logging.handlers import RotatingFileHandler

handler = RotatingFileHandler(
    "app.log",
    maxBytes=10_000_000,  # 10 MB
    backupCount=5,
)
handler.setFormatter(logging.Formatter("%(asctime)s %(levelname)s %(name)s %(message)s"))
logging.getLogger().addHandler(handler)
```

### Logger hierarchy

Loggers are organized by dot-separated name. `foo.bar` is a child of `foo` which is a child of the root logger. Log records propagate up to parent handlers by default.

Suppress a noisy third-party logger without disabling all logging:

```python
logging.getLogger("httpx").setLevel(logging.WARNING)
logging.getLogger("sqlalchemy.engine").setLevel(logging.WARNING)
```

Set `propagate = False` on a logger only when you have deliberately attached a handler to it and do not want records reaching the root handler (prevents double logging).

---

## structlog

structlog adds structured key-value context to log records. Prefer it over stdlib alone for any application that parses logs downstream (log aggregators, alerting systems).

### Install

```bash
pip install structlog
```

### Configure once at startup

```python
import logging
import structlog

structlog.configure(
    processors=[
        structlog.contextvars.merge_contextvars,
        structlog.processors.add_log_level,
        structlog.processors.StackInfoRenderer(),
        structlog.dev.set_exc_info,
        structlog.processors.TimeStamper(fmt="iso", utc=True),
        structlog.dev.ConsoleRenderer(),  # swap for JSONRenderer in production
    ],
    wrapper_class=structlog.make_filtering_bound_logger(logging.DEBUG),
    logger_factory=structlog.PrintLoggerFactory(),
    cache_logger_on_first_use=True,
)
```

For production, replace `ConsoleRenderer()` with `structlog.processors.JSONRenderer()` to emit machine-readable JSON.

### Per-module logger

```python
import structlog

logger = structlog.get_logger(__name__)

logger.info("user.created", user_id=42, email="a@example.com")
```

### Bind context to a logger instance

```python
request_log = logger.bind(request_id=request.id, user_id=current_user.id)
request_log.info("payment.started", amount=99.99)
request_log.info("payment.completed")
```

`bind` returns a new logger; the original is unchanged. Chain calls to accumulate context.

### Bind context across async tasks (contextvars)

For request-scoped context that survives across awaits and task boundaries:

```python
import structlog

structlog.contextvars.bind_contextvars(request_id=request.id)
# All log calls in this context automatically include request_id
logger.info("processing")
structlog.contextvars.unbind_contextvars("request_id")  # or clear_contextvars()
```

`merge_contextvars` in the processor chain merges these into every log record.

### Async logging

```python
async def handle_request():
    await logger.ainfo("request.received", path="/api/orders")
```

Use `ainfo`, `adebug`, `aerror` etc. in async code to avoid blocking.

### stdlib integration

To route structlog output through Python's stdlib logging (useful when third-party libraries also log):

```python
structlog.stdlib.recreate_defaults()
```

This reconfigures structlog to use stdlib as its output and sets up compatible processors.

---

## Anti-patterns

**failure: logging.warning("msg: %s %s", a, b) with f-strings mixed in**
Using `logger.warning(f"msg: {a}")` forces string interpolation even if the record is filtered out. Use `logger.warning("msg: %s", a)` for stdlib, or `logger.warning("msg", key=a)` for structlog.

**failure: bare except with logging.exception inside a loop**
Catching all exceptions and logging them without re-raising hides bugs in long-running loops. Either re-raise or use a specific exception type.

**warning: configuring logging inside library code**
Libraries must not call `basicConfig`, `addHandler`, or `setLevel` at module level. Configure only in the application entry point. Libraries should add only a `NullHandler` to their top-level logger.

**warning: print() for diagnostic output in server code**
`print` bypasses handlers, formatters, and level filters. Replace with a logger at the appropriate level.

**warning: root logger used directly in library modules**
`logging.info(...)` logs to the root logger and cannot be scoped or silenced per-module. Always use `logging.getLogger(__name__)`.

**info: no structured context on error logs**
Plain string messages like `"payment failed"` are hard to aggregate. Add identifiers: `logger.error("payment.failed", order_id=order.id, amount=amount)`.

---

## References

- https://docs.python.org/3/library/logging.html
- https://docs.python.org/3/howto/logging.html
- https://www.structlog.org/en/stable/getting-started.html

> Verify structlog processor names and configuration shape against the structlog docs when upgrading, as the processor API evolves between minor versions.
