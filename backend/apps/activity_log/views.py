from rest_framework import viewsets
from rest_framework.pagination import CursorPagination
from .models import ActivityLog
from .serializers import ActivityLogSerializer
from apps.approvals.views import IsOwnerOnly


class ActivityLogPagination(CursorPagination):
    page_size = 30
    ordering = "-timestamp"


class ActivityLogViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = ActivityLogSerializer
    permission_classes = [IsOwnerOnly]
    pagination_class = ActivityLogPagination

    def get_queryset(self):
        qs = ActivityLog.objects.filter(business=self.request.user.business)
        module = self.request.query_params.get("module")
        if module:
            qs = qs.filter(module=module)
        return qs