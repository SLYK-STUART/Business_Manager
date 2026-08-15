from rest_framework import serializers
from .models import ApprovalRequest


class ApprovalRequestSerializer(serializers.ModelSerializer):
    requested_by_name = serializers.SerializerMethodField()
    resolved_by_name = serializers.SerializerMethodField()
    detail = serializers.SerializerMethodField()

    class Meta:
        model = ApprovalRequest
        fields = [
            "id", "type", "reference_id", "status", "requested_by", "requested_by_name",
            "resolved_by", "resolved_by_name", "requested_at", "resolved_at", "detail",
        ]

    def get_requested_by_name(self, obj):
        return obj.requested_by.name if obj.requested_by else None

    def get_resolved_by_name(self, obj):
        return obj.resolved_by.name if obj.resolved_by else None

    def get_detail(self, obj):
        try:
            if obj.type == "free_giveaway":
                from apps.bar.models import FreeGiveaway
                g = FreeGiveaway.objects.get(id=obj.reference_id)
                return {
                    "item_name": g.item.name,
                    "quantity": g.quantity,
                    "recipient_name": g.recipient_name,
                    "value": float(g.item.buying_price * g.quantity),
                }
            elif obj.type == "non_business_transaction":
                from apps.bar.models import NonBusinessTransaction
                n = NonBusinessTransaction.objects.get(id=obj.reference_id)
                return {
                    "direction": n.direction,
                    "amount": float(n.amount),
                    "description": n.description,
                }
            elif obj.type == "shortfall":
                from apps.bar.models import CashCollection
                c = CashCollection.objects.get(id=obj.reference_id)
                return {
                    "expected_amount": float(c.expected_amount),
                    "collected_amount": float(c.collected_amount),
                    "variance": float(c.variance),
                }
        except Exception:
            return None
        return None