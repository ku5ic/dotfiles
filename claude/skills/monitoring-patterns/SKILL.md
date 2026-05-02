---
name: monitoring-patterns
description: >
  Application monitoring patterns covering Prometheus metrics (Counter, Gauge,
  Histogram, Summary), the prometheus-client Python library, metric naming
  conventions, labels, and health check endpoints. Use whenever a Python project
  instruments metrics, uses prometheus-client, or the user asks about Prometheus,
  metrics, monitoring, health checks, or observability, even if "Prometheus" is
  not mentioned by name.
---

# Monitoring Patterns

## When to load this skill

- Python project with `from prometheus_client import` or `import prometheus_client`
- User asks about Prometheus, metrics, counters, histograms, or observability
- User is implementing health check endpoints
- User asks about monitoring, alerting, or instrumenting code

## When not to load this skill

- Infrastructure Prometheus configuration (scrape configs, alert rules, recording rules)
- Grafana dashboard design
- OpenTelemetry tracing (separate domain)

---

## Prometheus metric types

| Type      | When to use                                                   | Goes down? |
| --------- | ------------------------------------------------------------- | ---------- |
| Counter   | Requests, errors, bytes processed - totals that only increase | No         |
| Gauge     | Queue depth, active connections, memory usage - current state | Yes        |
| Histogram | Request duration, response size - distribution matters        | No         |
| Summary   | Like Histogram but computes quantiles client-side             | No         |

Use **Histogram** over Summary by default. Summary quantiles are computed in the client and cannot be aggregated across instances. Histogram buckets are server-side and aggregatable.

---

## prometheus-client

```bash
pip install prometheus-client
```

### Counter

Tracks cumulative values that only increase.

```python
from prometheus_client import Counter

REQUESTS = Counter(
    "http_requests_total",
    "Total HTTP requests received",
    labelnames=["method", "status"],
    namespace="myapp",
)

REQUESTS.labels(method="GET", status="200").inc()
REQUESTS.labels(method="POST", status="500").inc()
```

Count exceptions automatically:

```python
ERRORS = Counter("errors_total", "Unhandled exceptions", labelnames=["handler"], namespace="myapp")

with ERRORS.labels(handler="checkout").count_exceptions():
    process_checkout()
```

### Gauge

Tracks a current value that can go up or down.

```python
from prometheus_client import Gauge

ACTIVE_CONNECTIONS = Gauge(
    "active_connections",
    "Number of active WebSocket connections",
    namespace="myapp",
)

ACTIVE_CONNECTIONS.inc()    # +1
ACTIVE_CONNECTIONS.dec()    # -1
ACTIVE_CONNECTIONS.set(42)  # exact value
```

### Histogram

Records observations in configurable buckets. Use for latency and payload sizes.

```python
from prometheus_client import Histogram

REQUEST_DURATION = Histogram(
    "http_request_duration_seconds",
    "HTTP request latency",
    labelnames=["method", "endpoint"],
    namespace="myapp",
    buckets=[0.01, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0],
)

# Context manager (records duration automatically)
with REQUEST_DURATION.labels(method="GET", endpoint="/api/orders").time():
    result = process_request()

# Decorator
@REQUEST_DURATION.labels(method="GET", endpoint="/api/health").time()
def health_check():
    return {"status": "ok"}

# Manual observation
REQUEST_DURATION.labels(method="GET", endpoint="/api/orders").observe(0.43)
```

### Summary

Like Histogram but computes quantiles locally. Avoid unless you cannot control bucket configuration.

```python
from prometheus_client import Summary

TASK_DURATION = Summary(
    "task_duration_seconds",
    "Background task processing time",
    labelnames=["task_type"],
    namespace="myapp",
)

with TASK_DURATION.labels(task_type="email_send").time():
    send_email()
```

---

## Metric naming

Follow Prometheus naming conventions:

- Snake_case only
- `namespace_subsystem_name_unit` shape: `myapp_http_request_duration_seconds`
- Counters end in `_total`: `myapp_errors_total`
- Use base units: `_seconds` not `_milliseconds`, `_bytes` not `_megabytes`
- Name the thing being measured, not the unit of measurement: `http_request_duration_seconds` not `http_request_time`

```python
# Correct
Counter("http_requests_total", ..., namespace="myapp")
Histogram("http_request_duration_seconds", ...)
Gauge("process_open_fds", ...)

# Wrong - wrong unit, missing _total, camelCase
Counter("httpRequestCount", ...)
Histogram("request_latency_ms", ...)
```

---

## Labels

Labels differentiate instances of the same metric. Keep cardinality low.

```python
# Good: bounded cardinality
REQUESTS.labels(method="GET", status="200").inc()

# Bad: unbounded cardinality - creates a new time series per user
REQUESTS.labels(user_id=user.id).inc()  # failure
```

Never use user IDs, email addresses, IP addresses, or other high-cardinality values as label values. Each unique label combination creates a separate time series.

---

## Exposing metrics

### Standalone HTTP server

```python
from prometheus_client import start_http_server

start_http_server(8000)  # serves /metrics on port 8000
```

Use this for background workers or CLIs that have no existing HTTP server.

### ASGI (FastAPI, Starlette)

Mount the metrics endpoint as a sub-application:

```python
from fastapi import FastAPI
from prometheus_client import make_asgi_app

app = FastAPI()

metrics_app = make_asgi_app()
app.mount("/metrics", metrics_app)
```

### WSGI (Django, Flask)

```python
from prometheus_client import make_wsgi_app

metrics_app = make_wsgi_app()
# Mount at /metrics in your WSGI router
```

---

## Health check endpoints

Expose two separate endpoints:

| Endpoint        | Returns 200 when                       | Used by                    |
| --------------- | -------------------------------------- | -------------------------- |
| `/health/live`  | Process is running                     | Kubernetes liveness probe  |
| `/health/ready` | Dependencies (DB, cache) are reachable | Kubernetes readiness probe |

```python
@app.get("/health/live")
def liveness():
    return {"status": "ok"}

@app.get("/health/ready")
async def readiness(db: AsyncSession = Depends(get_db)):
    await db.execute(text("SELECT 1"))
    return {"status": "ok"}
```

Return 503 (not 500) when a dependency is down. The readiness probe should only fail if the instance cannot serve traffic.

---

## Anti-patterns

**failure: high-cardinality label values**
Using user IDs, request IDs, or email addresses as label values creates millions of time series, crashes Prometheus, and makes dashboards useless. Labels must have bounded, low cardinality.

**failure: Counter used for values that decrease**
Use a Gauge for queue depth, active sessions, or any value that can drop. A Counter that decreases corrupts rate() calculations in PromQL.

**warning: metric names in milliseconds**
Prometheus convention is seconds. `_milliseconds` metrics are incompatible with standard recording rules and dashboards. Convert to seconds and use `_seconds`.

**warning: no namespace on metrics**
Without a namespace prefix, metric names from different apps collide in shared Prometheus instances. Always set `namespace="yourapp"`.

**warning: single health endpoint used for both liveness and readiness**
Combining liveness and readiness means a slow database causes the container to be killed and restarted rather than just pulled from load balancing. Keep them separate.

**info: no default buckets review for Histograms**
The default Histogram buckets (.005, .01, .025, .05, .1, .25, .5, 1, 2.5, 5, 10) suit general HTTP latency. For faster or slower operations, define custom buckets that match the expected distribution.

---

## References

- https://prometheus.io/docs/concepts/metric_types/
- https://prometheus.github.io/client_python/
- https://prometheus.io/docs/practices/naming/

> prometheus-client's API surface is stable but check the GitHub release notes before upgrading across minor versions.
