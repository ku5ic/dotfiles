---
name: django-patterns
description: Django patterns, anti-patterns, ORM gotchas, view design, migrations, settings, and review checklist for Django backend work. Use whenever the project contains `manage.py`, `settings.py`, `apps.py`, OR `pyproject.toml`/`requirements.txt`/`Pipfile` with `django` (or `Django`) listed as a dependency, OR the user asks about Django, Python web backend, ORM queries, models, views, forms, templates, migrations, admin, signals, middleware, or any work touching `.py` files in a Django app structure, even if Django is not mentioned by name.
---

# Django patterns

Django 5.2 LTS (extended support through April 2028). Django 6.0 is current stable (non-LTS). Baseline for this skill is 5.2 LTS.

DRF-specific patterns load when the project includes `djangorestframework` in dependencies.

## When to load this skill

- Project contains `manage.py`, `settings.py`, `apps.py`
- `pyproject.toml`, `requirements.txt`, or `Pipfile` lists `django` or `Django`
- User asks about Django, models, ORM, views, forms, templates, migrations, admin, signals, middleware

## When not to load this skill

- Pure FastAPI, Flask, or other Python web frameworks without Django
- Django REST Framework questions only (DRF-specific patterns live in their own skill)

## Reference files

| File                                               | Topics                                                                                      |
| -------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| [models.md](reference/models.md)                   | Model definition, Meta.constraints, Meta.indexes, null vs blank, on_delete, custom managers |
| [orm.md](reference/orm.md)                         | select_related, prefetch_related, F(), Q(), .only()/.defer(), .iterator(), bulk operations  |
| [views-and-forms.md](reference/views-and-forms.md) | CBV vs FBV, thin views, get_object_or_404, ModelForm, clean(), redirect after POST          |
| [templates.md](reference/templates.md)             | Template inheritance, auto-escaping, \|safe risks, {% csrf_token %}                         |
| [settings.md](reference/settings.md)               | Split settings, DEBUG, ALLOWED*HOSTS, SECRET_KEY, SECURE*\* family, django-environ          |
| [testing.md](reference/testing.md)                 | pytest-django, @pytest.mark.django_db, Factory Boy, model_bakery, --reuse-db                |
| [migrations.md](reference/migrations.md)           | Naming, atomic behavior, RunPython, makemigrations --check, squashing                       |
| [admin.md](reference/admin.md)                     | ModelAdmin, list_display, list_filter, search_fields, permissions, production posture       |
| [anti-patterns.md](reference/anti-patterns.md)     | Severity-labeled anti-patterns to flag in review                                            |

## References

- https://docs.djangoproject.com/en/stable/
- https://www.djangoproject.com/download/ (LTS and stable versions)
- https://pytest-django.readthedocs.io/en/latest/
- https://factoryboy.readthedocs.io/en/stable/
- https://github.com/joke2k/django-environ

## Maintenance

Django releases roughly every 8 months. LTS releases every 2 years. Verify version claims against https://www.djangoproject.com/download/ before citing. pytest-django, Factory Boy, and model_bakery follow their own release cycles; check PyPI for current versions.
