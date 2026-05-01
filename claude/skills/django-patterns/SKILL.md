---
name: django-patterns
description: Django patterns, anti-patterns, ORM gotchas, view design, migrations, settings, and review checklist for Django backend work. Use whenever the project contains `manage.py`, `settings.py`, `apps.py`, OR `pyproject.toml`/`requirements.txt`/`Pipfile` with `django` (or `Django`) listed as a dependency, OR the user asks about Django, Python web backend, ORM queries, models, views, forms, templates, migrations, admin, signals, middleware, or any work touching `.py` files in a Django app structure, even if Django is not mentioned by name.
---

# Django patterns

## Models

- Prefer explicit `related_name` on `ForeignKey` and `ManyToManyField`. The default `_set` breaks when you rename.
- Use `on_delete` explicitly and deliberately. `CASCADE` is not automatic best practice.
- Model methods for row-level computation. Manager methods for table-level queries. Do not mix.
- Migrations: every model change ships a migration. Squash only when you own the downstream projects.
- `help_text` on fields intended for admin or forms. It doubles as documentation.
- `Meta.constraints` for cross-field rules. Database level is stronger than model `clean()`.
- Indexes: add on fields used in `filter()`, `order_by()`, `unique_together` replacement via `UniqueConstraint`.

## Views

- Class based views for CRUD, function based views for one-offs. Not dogma, but pick one per area.
- Thin views, fat models and services. View handles request and response shape only.
- Business logic in services, not in views or model methods that know about HTTP.
- Redirect after POST. Never render a template in response to a POST (except explicit preview patterns).
- `get_object_or_404` for single object lookups. Do not catch `DoesNotExist` manually.

## Forms

- ModelForm over Form when mapping to a model. Less duplication.
- Validation: `clean_<field>()` for per-field, `clean()` for cross-field, constraints for DB-level.
- Never trust `form.data` directly. Use `form.cleaned_data` after `is_valid()`.
- CSRF: enabled by default. If you disabled it for an endpoint, document why and prove it is safe.

## Templates

- Keep logic in views and template tags, not templates. `{% if %}` trees longer than 5 branches are a smell.
- `|safe` and `{% autoescape off %}`: every use. Must be on trusted content.
- Template inheritance: base for shell, blocks for variation. Do not use `{% include %}` for structural pieces.
- Context processors for truly global data. Everything else should be explicit view context.

## ORM

- N+1 detection: `prefetch_related` for reverse FK and M2M, `select_related` for forward FK.
- `.values()` and `.values_list()` for read-only pulls. Smaller query, smaller memory.
- `.only()` and `.defer()` when you fetch many rows but read few columns. Measure first.
- Avoid `.count()` inside loops. Pull once or use aggregation.
- `F()` expressions for atomic updates. Do not `obj.field += 1; obj.save()` on concurrent writes.
- `Q()` objects for complex OR logic. Readable, composable.
- `QuerySet.update()` and `.delete()` at the queryset level bypass signals. Know what you are skipping.

## Django REST Framework

- Serializers: explicit `fields` list. `fields = "__all__"` is a liability, leaks columns you later wish were hidden.
- Validation lives in serializers, not views. `validate()` and `validate_<field>()`.
- Pagination: set a default in settings, override per view only with reason.
- Permissions: `permission_classes` on every viewset. No implicit `AllowAny`.
- Throttling on write and auth endpoints.
- Filtering: `django-filter` or explicit queryset override. Never `queryset.filter(**request.query_params)`.

## Settings

- Split settings: `base.py`, `dev.py`, `prod.py`, `test.py`. Read env var to choose.
- `DEBUG = False` in production. `ALLOWED_HOSTS` explicit. `CSRF_TRUSTED_ORIGINS` set for non-same-origin forms.
- `SECURE_*` settings: `SSL_REDIRECT`, `HSTS_SECONDS`, `PROXY_SSL_HEADER` if behind a proxy.
- Secrets via env, not code. `django-environ` is a common choice.

## Testing

- `pytest-django` over `TestCase` in a pytest codebase.
- `@pytest.mark.django_db` only when needed. Unit tests on pure logic do not need DB.
- `client` fixture for view tests. `api_client` from DRF for API tests.
- Factory Boy or model_bakery for model instances. Stop writing `Model.objects.create(...)` in every test.
- Do not test Django itself. Do not test that `filter(x=1)` returns rows where x=1.

## Migrations

- Name migrations: `XXXX_add_user_email_index`, not `XXXX_auto_20260101_0101`.
- Data migrations in `RunPython` with reverse where feasible.
- Never edit applied migrations. Add a new one.
- `makemigrations --check` in CI so drifted models are caught before merge.

## Admin

- Register every user-facing model with an explicit `ModelAdmin`. Default admin for dev models only.
- `list_display`, `list_filter`, `search_fields` thoughtfully. Admin is used in incidents; it needs to be usable.
- Permissions in admin mirror permissions in the app. Do not rely on admin to enforce what the app does not.

## Anti-patterns to flag

- Business logic in `save()` override (hard to test, skipped by `update()`)
- Signals for business logic (hidden control flow)
- `get_queryset()` doing auth checks (put in permissions or filter explicitly)
- `request.user` access inside models (models should not know about requests)
- Query inside a template (`{% for obj in model.objects.all %}` via tags)
- Fat views with 200+ lines (extract to service)
