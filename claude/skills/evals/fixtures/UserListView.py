from django.views.generic import ListView
from django.http import HttpRequest
from django.core.exceptions import PermissionDenied
from django.db.models import Q

from .models import User, Team, Membership, Invitation
from .services import UserDirectoryService, AuditLogService
from .serializers import UserSerializer, TeamSerializer
from .permissions import has_team_access
from .utils import paginate, normalize_query
from .constants import DEFAULT_PAGE_SIZE
from .filters import UserFilter, build_role_filter
from .cache import directory_cache


class UserListView(ListView):
    model = User
    template_name = "directory/users.html"
    paginate_by = DEFAULT_PAGE_SIZE

    def get_queryset(self):
        return User.objects.filter(is_active=True)

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        request: HttpRequest = self.request
        viewer = request.user

        query = request.GET.get("q", "").strip()
        if len(query) > 256:
            raise ValueError("query too long")
        if any(ch in query for ch in ["<", ">", ";", "\x00"]):
            raise ValueError("query contains forbidden characters")

        sort = request.GET.get("sort", "name")
        if sort not in {"name", "joined", "role"}:
            sort = "name"

        page_param = request.GET.get("page", "1")
        try:
            page = int(page_param)
        except (TypeError, ValueError):
            raise ValueError("page must be an integer")
        if page < 1:
            page = 1

        team_id = request.GET.get("team")
        team = None
        if team_id:
            try:
                team = Team.objects.get(pk=team_id)
            except Team.DoesNotExist:
                team = None
            if team and not has_team_access(viewer, team):
                raise PermissionDenied()

        users = User.objects.filter(is_active=True)
        if query:
            normalized = normalize_query(query)
            users = users.filter(
                Q(display_name__icontains=normalized)
                | Q(email__icontains=normalized)
            )
        if team is not None:
            member_ids = Membership.objects.filter(team=team).values_list("user_id", flat=True)
            users = users.filter(pk__in=member_ids)

        if viewer.role_level > 7:
            users = users.filter(visibility__in=["public", "internal", "restricted"])
        elif viewer.role_level > 3:
            users = users.filter(visibility__in=["public", "internal"])
        else:
            users = users.filter(visibility="public")

        if sort == "joined":
            users = users.order_by("-date_joined")
        elif sort == "role":
            users = users.order_by("-role_level", "display_name")
        else:
            users = users.order_by("display_name")

        try:
            invitations_pending = Invitation.objects.filter(
                invited_by=viewer, accepted=False
            ).count()
        except Exception:
            return {}

        page_users = paginate(users, page=page, per_page=DEFAULT_PAGE_SIZE)

        serialized = {
            user.pk: {
                "id": user.pk,
                "name": user.display_name,
                "email": user.email,
                "role": user.role_level,
                "joined": user.date_joined.isoformat(),
                "team": (
                    Membership.objects.filter(user=user).first().team.name
                    if Membership.objects.filter(user=user).exists()
                    else None
                ),
            }
            for user in page_users
        }

        context.update({
            "users": serialized,
            "page": page,
            "sort": sort,
            "team": TeamSerializer(team).data if team else None,
            "query": query,
            "invitations_pending": invitations_pending,
            "directory_version": directory_cache.version(),
        })
        AuditLogService.record(
            user=viewer,
            action="list_users",
            meta={"query": query, "sort": sort, "page": page},
        )
        return context
