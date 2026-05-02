---
name: fastapi-patterns
description: FastAPI patterns, Pydantic schemas, dependency injection, async correctness, response models, error handling, OpenAPI, and auth. Use whenever the project contains `fastapi` in dependencies, files importing from `fastapi`, `@app.get`/`@router.get` decorators, Pydantic BaseModel subclasses used as request/response types, OR the user asks about FastAPI, Pydantic v2, Depends(), HTTPException, OAuth2PasswordBearer, APIKeyHeader, response_model, even if FastAPI is not mentioned by name.
---

# FastAPI patterns

FastAPI 0.136.1, Pydantic 2.13.3. Verify current versions at https://pypi.org/project/fastapi/ and https://pypi.org/project/pydantic/.

Install: `pip install "fastapi[standard]"`

## When to load this skill

- Project has `fastapi` in `requirements.txt`, `pyproject.toml`, or `Pipfile`
- Files contain `from fastapi import`, `@app.get`, `@router.get`
- Pydantic `BaseModel` used as route input/output type
- User asks about FastAPI, Pydantic v2, dependency injection, Depends(), response_model, HTTPException, OAuth2, APIKey

## When not to load this skill

- Django or Flask without FastAPI
- Pydantic used outside a web framework (standalone validation)
- GraphQL with strawberry or ariadne

## Reference files

| File                                                         | Topics                                                                                                        |
| ------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------- |
| [pydantic-schemas.md](reference/pydantic-schemas.md)         | BaseModel, Field(), field_validator, model_validator, model_config, ConfigDict, separate input/output schemas |
| [dependency-injection.md](reference/dependency-injection.md) | Depends(), Annotated pattern, yield dependencies, testing overrides                                           |
| [async-correctness.md](reference/async-correctness.md)       | async def vs def, threadpool behavior, blocking I/O rules                                                     |
| [response-models.md](reference/response-models.md)           | response_model, response_model_exclude_unset, separate schemas                                                |
| [error-handling.md](reference/error-handling.md)             | HTTPException, custom exception handlers, status codes                                                        |
| [openapi.md](reference/openapi.md)                           | Metadata, tags, disabling docs in production, route decorator params                                          |
| [auth.md](reference/auth.md)                                 | OAuth2PasswordBearer, JWT, APIKeyHeader, HTTPBasic, timing attacks                                            |
| [anti-patterns.md](reference/anti-patterns.md)               | Severity-labeled anti-patterns to flag in review                                                              |

## References

- https://fastapi.tiangolo.com/
- https://pydantic.dev/docs/validation/latest/
- https://fastapi.tiangolo.com/tutorial/security/
- https://fastapi.tiangolo.com/async/

## Maintenance

FastAPI and Pydantic release independently. Pydantic v2 introduced breaking changes from v1; verify the project's Pydantic version before applying patterns. Check PyPI for current versions.
