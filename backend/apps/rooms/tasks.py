from django.utils import timezone
from datetime import timedelta
from .models import RoomBooking
from apps.notifications.services import notify, notify_owner
from apps.activity_log.services import log_activity


def flag_overstays():
    cutoff = timezone.now() - timedelta(hours=24)
    overdue = RoomBooking.objects.filter(status="active", checkin_time__lte=cutoff)

    for booking in overdue:
        booking.status = "overstay_flagged"
        booking.overstay_alert_sent_at = timezone.now()
        booking.save()

        business = booking.room.business
        message = f"Room {booking.room.name} has exceeded 24 hours without checkout."

        notify_owner(business, "room_overstay", message,
                     related_entity_type="RoomBooking", related_entity_id=booking.id)
        if booking.marked_by:
            notify(business, booking.marked_by, "room_overstay", message,
                   related_entity_type="RoomBooking", related_entity_id=booking.id)

        log_activity(business, None, "rooms", "overstay_flagged", "RoomBooking", booking.id)