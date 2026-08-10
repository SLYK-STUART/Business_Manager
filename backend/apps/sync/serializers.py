from rest_framework import serializers


class SyncPushItemSerializer(serializers.Serializer):
    entity_type = serializers.CharField()  # e.g. "sale", "restock", "checkin"
    client_id = serializers.CharField()    # locally-generated UUID, for the client to match responses back
    payload = serializers.JSONField()


class SyncPushSerializer(serializers.Serializer):
    items = SyncPushItemSerializer(many=True)


class SyncPullQuerySerializer(serializers.Serializer):
    since = serializers.DateTimeField(required=False)
    entities = serializers.CharField(required=False)  # comma-separated, e.g. "items,sales,loans"