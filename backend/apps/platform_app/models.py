import uuid
from django.db import models


class Business(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=255)
    address = models.CharField(max_length=255, blank=True)
    is_active = models.BooleanField(default=True)
    created_by = models.ForeignKey(
        "accounts.User",
        on_delete=models.SET_NULL,
        null=True,
        related_name="businesses_created",
    )
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name


class BusinessModule(models.Model):
    class ModuleType(models.TextChoices):
        BAR = "bar", "Bar"
        ROOMS = "rooms", "Rooms"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    business = models.ForeignKey(
        Business, on_delete=models.CASCADE, related_name="modules"
    )
    module_type = models.CharField(max_length=20, choices=ModuleType.choices)
    is_active = models.BooleanField(default=True)
    activated_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ("business", "module_type")

    def __str__(self):
        return f"{self.business.name} — {self.module_type}"