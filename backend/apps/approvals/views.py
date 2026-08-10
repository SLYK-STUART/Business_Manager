from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import BasePermission
from .models import ApprovalRequest
from .serializers import ApprovalRequestSerializer
from .services import resolve_approval


class IsOwnerOnly(BasePermission):
    def has_permission(self, request, view):
        return request.user.is_authenticated and "owner" in request.user.roles


class ApprovalRequestViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = ApprovalRequestSerializer
    permission_classes = [IsOwnerOnly]

    def get_queryset(self):
        qs = ApprovalRequest.objects.filter(business=self.request.user.business)
        status_filter = self.request.query_params.get("status", "pending")
        if status_filter:
            qs = qs.filter(status=status_filter)
        return qs.order_by("-requested_at")

    @action(detail=True, methods=["post"])
    def approve(self, request, pk=None):
        approval = self.get_object()
        resolve_approval(approval, approved=True, resolved_by=request.user)
        return Response(ApprovalRequestSerializer(approval).data)

    @action(detail=True, methods=["post"])
    def reject(self, request, pk=None):
        approval = self.get_object()
        resolve_approval(approval, approved=False, resolved_by=request.user)
        return Response(ApprovalRequestSerializer(approval).data)