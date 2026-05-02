# Errors

## Throw `Error` instances, not strings

`throw "bad input"` produces a value with no stack trace and bypasses `instanceof` checks. Always throw an `Error` (or a subclass). Future readers and runtime tooling rely on the `name`, `message`, `stack`, and `cause` properties.

## Use specific Error subclasses

The platform ships standard subclasses for common kinds of failure: `TypeError`, `RangeError`, `SyntaxError`, `URIError`, `ReferenceError`, plus `AggregateError` for batched failures. Throw the most specific one. Define your own subclass when callers will branch on the kind:

```js
class ValidationError extends Error {
  constructor(message, fields) {
    super(message);
    this.name = "ValidationError";
    this.fields = fields;
  }
}
```

## Narrow before reading custom properties

In `catch (err)`, `err` is typed `unknown` (in TypeScript) or arbitrary at runtime: `throw` accepts any value. Always check `instanceof X` before reading `.fields`, `.code`, etc.

```js
try {
  validate(input);
} catch (err) {
  if (err instanceof ValidationError) {
    return { fields: err.fields };
  }
  throw err;
}
```

## `Error.cause` (ES2022)

Wrap a lower-level error while preserving the original via the `cause` option:

```js
try {
  await connectToDatabase();
} catch (err) {
  throw new Error("Database connection failed", { cause: err });
}
```

The wrapper carries context for human readers; `err.cause` carries the original for tooling.

## Unhandled rejections terminate the process

In current Node.js, an unhandled promise rejection is raised as an uncaught exception by default and the process exits with a non-zero code. The `--unhandled-rejections` flag (default `throw`) controls this. Always either `await`, `return`, or `.catch()` every promise. Fire-and-forget needs an explicit `.catch(logAndContinue)` so the rejection does not propagate.

## Empty `catch {}`

`failure`. Swallowing an error silently hides defects. If the failure is genuinely expected and recoverable, log it (with the value) and continue, or re-throw a wrapped error explaining why it was caught.

## `using` and `await using` (TC39 Stage 3, advisory)

The explicit resource management proposal adds `using` (sync) and `await using` (async) declarations that auto-dispose at scope exit. As of writing it is at TC39 Stage 3 and is not yet part of standard ECMAScript. Verify Node and toolchain support before relying on it; until then, use `try`/`finally` for deterministic cleanup.

## References

- MDN Error: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Error
- MDN Error.cause: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Error/cause
- Node.js process unhandledRejection: https://nodejs.org/api/process.html#event-unhandledrejection
- TC39 explicit resource management: https://github.com/tc39/proposal-explicit-resource-management
