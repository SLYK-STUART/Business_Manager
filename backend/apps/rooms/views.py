from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import Room, RoomBooking
from .serializers import RoomSerializer, RoomBookingSerializer, CheckinSerializer, CheckoutSerializer
from apps.bar.permissions import IsBusinessStaff


class RoomViewSet(viewsets.ModelViewSet):
    serializer_class = RoomSerializer
    permission_classes = [IsBusinessStaff]

    def get_queryset(self):
        return Room.objects.filter(business=self.request.user.business, is_active=True)

    def perform_create(self, serializer):
        serializer.save(business=self.request.user.business, created_by=self.request.user)

    def perform_destroy(self, instance):
        instance.is_active = False
        instance.save()


class RoomBookingViewSet(viewsets.ModelViewSet):
    serializer_class = RoomBookingSerializer
    permission_classes = [IsBusinessStaff]
    http_method_names = ["get", "post"]

    def get_queryset(self):
        return RoomBooking.objects.filter(room__business=self.request.user.business)

    def create(self, request, *args, **kwargs):
        serializer = CheckinSerializer(data=request.data, context={"request": request})
        serializer.is_valid(raise_exception=True)
        booking = serializer.save()
        return Response(RoomBookingSerializer(booking).data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=["post"])
    def checkout(self, request, pk=None):
        booking = self.get_object()
        booking = CheckoutSerializer().save(booking)
        return Response(RoomBookingSerializer(booking).data)