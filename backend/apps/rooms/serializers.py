from rest_framework import serializers
from django.utils import timezone
from django.db import transaction
from .models import Room, RoomBooking


class RoomSerializer(serializers.ModelSerializer):
    class Meta:
        model = Room
        fields = ["id", "name", "nightly_rate", "status", "is_active", "created_at"]
        read_only_fields = ["id", "created_at", "status"]


class RoomSerializer(serializers.ModelSerializer):
    checkin_time = serializers.SerializerMethodField()

    class Meta:
        model = Room
        fields = ["id", "name", "room_type", "nightly_rate", "status", "checkin_time", "is_active", "created_at"]
        read_only_fields = ["id", "created_at", "status", "checkin_time"]

    def get_checkin_time(self, obj):
        if obj.status == Room.Status.OCCUPIED:
            booking = obj.bookings.filter(status=RoomBooking.Status.ACTIVE).order_by("-checkin_time").first()
            return booking.checkin_time if booking else None
        return None


class RoomBookingSerializer(serializers.ModelSerializer):
    class Meta:
        model = RoomBooking
        fields = ["id", "room", "checkin_time", "checkout_time", "nights", "discount_amount", "amount_paid", "status"]


class CheckinSerializer(serializers.Serializer):
    room_id = serializers.UUIDField()
    nights = serializers.IntegerField(min_value=1, default=1)
    discount_amount = serializers.DecimalField(max_digits=12, decimal_places=2, default=0)

    def create(self, validated_data):
        with transaction.atomic():
            room = Room.objects.select_for_update().get(
                id=validated_data["room_id"], business=self.context["request"].user.business
            )
            if room.status == Room.Status.OCCUPIED:
                raise serializers.ValidationError("Room already occupied.")


            nights = validated_data["nights"]
            discount = validated_data.get("discount_amount", 0)
            amount_paid = (room.nightly_rate * nights) - discount

            from apps.bar.models import CollectionPeriod
            period, _ = CollectionPeriod.objects.get_or_create(
                business=room.business, module="rooms", status="open",
                defaults={"opening_expected_amount": 0},
            )
            period.opening_expected_amount += amount_paid
            period.save()

            booking = RoomBooking.objects.create(
                room=room, nights=nights, discount_amount=discount,
                amount_paid=amount_paid, marked_by=self.context["request"].user,
            )
            room.status = Room.Status.OCCUPIED
            room.save()
        return booking


class CheckoutSerializer(serializers.Serializer):
    def save(self, booking):
        booking.checkout_time = timezone.now()
        booking.status = RoomBooking.Status.COMPLETED
        booking.save()
        booking.room.status = Room.Status.FREE
        booking.room.save()
        return booking