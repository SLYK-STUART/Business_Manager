from rest_framework import serializers
from .models import ActivityLog


class ActivityLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = ActivityLog
        fields = ["id", "actor", "module", "action_type", "entity_type", "entity_id", "details", "timestamp"]