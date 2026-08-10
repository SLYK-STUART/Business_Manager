from apps.bar.serializers import SaleCreateSerializer, RestockSerializer
from apps.rooms.serializers import CheckinSerializer, CheckoutSerializer
from apps.bar.models import Item
from apps.rooms.models import RoomBooking

HANDLERS = {}


def handler(entity_type):
    def wrapper(fn):
        HANDLERS[entity_type] = fn
        return fn
    return wrapper


@handler("sale")
def handle_sale(payload, request):
    serializer = SaleCreateSerializer(data=payload, context={"request": request})
    serializer.is_valid(raise_exception=True)
    sale = serializer.save()
    return {"id": str(sale.id), "status": "synced"}


@handler("restock")
def handle_restock(payload, request):
    item = Item.objects.get(id=payload["item_id"], business=request.user.business)
    serializer = RestockSerializer(data=payload)
    serializer.is_valid(raise_exception=True)
    item.current_stock += serializer.validated_data["quantity"]
    item.save()
    return {"id": str(item.id), "status": "synced"}


@handler("checkin")
def handle_checkin(payload, request):
    serializer = CheckinSerializer(data=payload, context={"request": request})
    serializer.is_valid(raise_exception=True)
    booking = serializer.save()
    return {"id": str(booking.id), "status": "synced"}


@handler("checkout")
def handle_checkout(payload, request):
    booking = RoomBooking.objects.get(id=payload["booking_id"], room__business=request.user.business)
    CheckoutSerializer().save(booking)
    return {"id": str(booking.id), "status": "synced"}


def process_push_item(entity_type, payload, request):
    fn = HANDLERS.get(entity_type)
    if not fn:
        return {"status": "failed", "error": f"Unknown entity_type: {entity_type}"}
    try:
        result = fn(payload, request)
        result["status"] = "synced"
        return result
    except Exception as e:
        return {"status": "failed", "error": str(e)}