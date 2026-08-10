import uuid
from django.db import models
from apps.platform_app.models import Business
from apps.accounts.models import User


class ApprovalRequest(models.Model):
    class Type(models.TextChoices):
        SHORTFALL = "shortfall", "Shortfall"
        FREE_GIVEAWAY = "free_giveaway", "Free giveaway"
        NON_BUSINESS_TRANSACTION = "non_business_transaction", "Non-business transaction"

    class Status(models.TextChoices):
        PENDING = "pending", "Pending"
        APPROVED = "approved", "Approved"
        REJECTED = "rejected", "Rejected"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    business = models.ForeignKey(Business, on_delete=models.CASCADE)
    type = models.CharField(max_length=30, choices=Type.choices)
    reference_id = models.UUIDField()
    status = models.CharField(max_length=10, choices=Status.choices, default=Status.PENDING)
    requested_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name="approvals_requested")
    resolved_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name="approvals_resolved")
    requested_at = models.DateTimeField(auto_now_add=True)
    resolved_at = models.DateTimeField(null=True, blank=True)