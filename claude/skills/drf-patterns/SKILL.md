---
name: drf-patterns
description: Django REST Framework patterns, serializers, viewsets, permissions, throttling, filtering, pagination, and review checklist. Use whenever the project contains `djangorestframework` in dependencies, `rest_framework` in INSTALLED_APPS, files following DRF naming patterns (`serializers.py`, `viewsets.py`, `permissions.py`), OR the user asks about DRF, Django REST, serializers, viewsets, ModelViewSet, permission_classes, throttle_classes, even if DRF is not mentioned by name.
---

# Django REST Framework patterns

DRF approximately v3.16. Supports Django 4.2, 5.0, 5.1, 5.2, 6.0 and Python 3.10-3.14. Verify current version at https://pypi.org/project/djangorestframework/. Adapt advice to the version in the project's `requirements.txt`, `pyproject.toml`, or lockfile.

## Reference files

| File                                                                   | Covers                                                                                     |
| ---------------------------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| [serializers.md](reference/serializers.md)                             | Explicit fields, validate(), nested serializers, SerializerMethodField, ModelSerializer    |
| [viewsets-and-routers.md](reference/viewsets-and-routers.md)           | ModelViewSet vs GenericViewSet + mixins, @action, DefaultRouter                            |
| [permissions.md](reference/permissions.md)                             | permission_classes, IsAuthenticated vs IsAuthenticatedOrReadOnly, object-level permissions |
| [throttling-and-pagination.md](reference/throttling-and-pagination.md) | UserRateThrottle, AnonRateThrottle, pagination styles, page size config                    |
| [filtering.md](reference/filtering.md)                                 | django-filter, SearchFilter, OrderingFilter, get_queryset override                         |
| [auth.md](reference/auth.md)                                           | TokenAuthentication, SessionAuthentication, JWT via simplejwt                              |
| [versioning.md](reference/versioning.md)                               | Versioning schemes, request.version, ALLOWED_VERSIONS                                      |
| [anti-patterns.md](reference/anti-patterns.md)                         | Severity-labeled anti-patterns to flag in review                                           |

## References

- https://www.django-rest-framework.org/
- https://www.django-rest-framework.org/api-guide/serializers/
- https://www.django-rest-framework.org/api-guide/permissions/
- https://django-rest-framework-simplejwt.readthedocs.io/en/latest/
