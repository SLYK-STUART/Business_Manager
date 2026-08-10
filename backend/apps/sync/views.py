from rest_framework.views import APIView
from rest_framework.response import Response
from django.utils.dateparse import parse_datetime
from .serializers import SyncPushSerializer
from .services import process_push_item
from apps.bar.permissions import IsBusinessStaff
from apps.bar.models import Item, Sale, Loan
from apps.rooms.models import Room, RoomBooking


class SyncPushView(APIView):
    permission_classes = [IsBusinessStaff]

    def post(self, request):
        serializer = SyncPushSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        results = []
        for entry in serializer.validated_data["items"]:
            outcome = process_push_item(entry["entity_type"], entry["payload"], request)
            outcome["client_id"] = entry["client_id"]
            results.append(outcome)

        return Response({"results": results})


PULLABLE = {
    "items": (Item, lambda qs, business: qs.filter(business=business)),
    "sales": (Sale, lambda qs, business: qs.filter(business=business)),
    "loans": (Loan, lambda qs, business: qs.filter(customer__business=business)),
    "rooms": (Room, lambda qs, business: qs.filter(business=business)),
    "bookings": (RoomBooking, lambda qs, business: qs.filter(room__business=business)),
}


class SyncPullView(APIView):
    permission_classes = [IsBusinessStaff]

    def get(self, request):
        since = parse_datetime(request.query_params.get("since")) if request.query_params.get("since") else None
        entities = request.query_params.get("entities", "").split(",")

        data = {}
        for name in entities:
            name = name.strip()
            if name not in PULLABLE:
                continue
            model, scope_fn = PULLABLE[name]
            qs = scope_fn(model.objects.all(), request.user.business)
            timestamp_field = "created_at" if hasattr(model, "created_at") else "confirmed_at"
            if since and hasattr(model, timestamp_field):
                qs = qs.filter(**{f"{timestamp_field}__gt": since})
            data[name] = list(qs.values())  # raw dicts for now — swap for proper serializers as needed

        return Response({"synced_at": request._request.META.get("HTTP_DATE", ""), "data": data})