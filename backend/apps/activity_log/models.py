import uuid
from django.db import models
from apps.platform_app.models import Business
from apps.accounts.models import User


class ActivityLog(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    business = models.ForeignKey(Business, on_delete=models.CASCADE, related_name="activity_logs")
    actor = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    module = models.CharField(max_length=20)  # bar / rooms / shared
    action_type = models.CharField(max_length=100)
    entity_type = models.CharField(max_length=100)
    entity_id = models.UUIDField()
    details = models.JSONField(default=dict, blank=True)
    timestamp = models.DateTimeField(auto_now_add=True)

    class Meta:
        indexes = [
            models.Index(fields=["business", "module", "timestamp"]),
            models.Index(fields=["entity_type", "entity_id"]),
        ]