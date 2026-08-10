from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import Notification
from .serializers import NotificationSerializer
from apps.bar.permissions import IsBusinessStaff


class NotificationViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = NotificationSerializer
    permission_classes = [IsBusinessStaff]

    def get_queryset(self):
        return Notification.objects.filter(recipient=self.request.user).order_by("-created_at")

    @action(detail=True, methods=["post"])
    def dismiss(self, request, pk=None):
        n = self.get_object()
        n.status = "dismissed"
        n.save()
        return Response(NotificationSerializer(n).data)