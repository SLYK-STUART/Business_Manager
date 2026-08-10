import uuid
from django.db import models
from apps.platform_app.models import Business


class GeneratedReport(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    business = models.ForeignKey(Business, on_delete=models.CASCADE, related_name="reports")
    type = models.CharField(max_length=50)
    period = models.CharField(max_length=50)
    generated_at = models.DateTimeField(auto_now_add=True)
    file_url = models.URLField()