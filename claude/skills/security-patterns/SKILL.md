---
name: security-patterns
description: Security checklist for frontend (React, Next.js) and backend (Django, Node APIs) covering XSS, injection, auth, sessions, CSRF, CSP, secrets, dependency CVEs, and severity calls. Use whenever the user asks about security, hardening, vulnerabilities, auth, authentication, authorization, sessions, cookies, XSS, CSRF, SQL injection, secrets, environment variables, CSP, headers, or reviews changes that touch user input, auth, or external data, even if "security" is not mentioned by name.
---

# Security patterns

Load the sections that apply to the detected stack. Skip the rest.

## Frontend: React and Next.js

### XSS and injection

- `dangerouslySetInnerHTML`: every occurrence. Must sanitize with DOMPurify or equivalent, or remove.
- URLs in `href`, `src`, `action`, `formAction`: validate scheme. No `javascript:` URLs from user input. No unchecked `data:` URIs.
- Open redirects: any `router.push(userValue)`, `window.location = userValue`, server action redirect with user input. Must validate against an allowlist.
- Template injection: variables interpolated into raw HTML strings, Markdown renderers without sanitization.

### Client / server boundary (Next.js)

- Secrets: `NEXT_PUBLIC_*` is sent to the browser. Anything sensitive must not have this prefix. Audit all `process.env.*` reads in client components.
- Server actions: check `use server` files. Validate input at the action boundary. Assume every arg is user controlled.
- `headers()`, `cookies()`: used only in server components, route handlers, or server actions. Never leaked to client.
- Route handlers: validate body and query with a schema (zod, valibot). Do not trust `Content-Type` header.

### Auth and sessions

- Session cookies: `httpOnly`, `secure`, `sameSite`. Audit Set-Cookie headers or middleware.
- CSRF: double-submit cookie, origin check, or sameSite strict for cookie-based auth. Missing on mutations.
- JWT: verify signature, check `exp`, `iss`, `aud`. Do not trust decoded claims as auth.

### Content Security Policy

- `unsafe-inline` in `script-src`: flag. Indicates a gap.
- `unsafe-eval`: flag.
- Missing CSP header entirely: flag.

## Backend: Django

### ORM and query

- Raw SQL via `raw()` or `extra()`: every use must parameterize inputs.
- N+1 and accidental data exposure: `.values()` without filtering, overly broad `select_related()`.
- `.filter(**request.GET)`: never. Arbitrary kwargs to filter is dangerous.

### Views and middleware

- CSRF: `@csrf_exempt` on mutating views is a failure unless the view is read-only or explicitly API token authenticated.
- `DEBUG = True` in committed settings: failure.
- `SECRET_KEY`, DB credentials, API keys in repo: failure. Check `.env` handling, `env.example` vs `.env`.
- `ALLOWED_HOSTS` wildcard in production settings: failure.
- Middleware order: `SecurityMiddleware` first, `SessionMiddleware` before `AuthenticationMiddleware`, `CsrfViewMiddleware` before views that mutate.

### Auth and permissions

- DRF viewsets: `permission_classes` set explicitly. Default `AllowAny` is a failure for write endpoints.
- Object-level permissions: does user own this object before edit or delete?
- Password storage: default hashers OK. Custom implementations need review.

### Templates

- `{% autoescape off %}` or `|safe`: every use. Must be on trusted content only.
- `mark_safe()` on user-derived data: failure.

### File uploads

- Validate extension, MIME type, and content. Serve from non-executable location.
- Size limits at web server and Django layer.

## Backend: Node APIs (Express, Fastify, Nest)

- Body parsing: size limits. Default is often no limit.
- Input validation at route entry: zod, joi, or fastify schema. Not inside handlers.
- SQL and ORM: parameterized queries only. Flag string concatenation into queries.
- Error responses: do not leak stack traces to clients in production.
- Rate limiting on auth endpoints, password reset, account enumeration vectors.
- Helmet or equivalent security headers.
- CORS: explicit origin list, not `*` with credentials.

## Dependencies (all stacks)

- Lockfile in repo. Dependabot or equivalent enabled or acknowledged.
- Known CVEs: if `npm audit`, `pnpm audit`, `pip-audit`, or `bundler-audit` show findings at moderate or above, flag them.
- Transitive deps: check `package.json` for unexpected scoped packages, typosquat risk.

## Secrets

- Any hardcoded token, key, or password in the codebase: failure.
- `.env` committed: failure.
- Secrets in commit history: note, do not attempt to fix without asking.

## Severity calls

- **failure**: exploitable, or direct leak of credentials, or missing CSRF on authenticated mutating endpoint.
- **warning**: mitigated but weak (e.g. CSP present but with `unsafe-inline`), or pattern that will become exploitable if misused.
- **info**: hardening opportunity, not currently exploitable.
