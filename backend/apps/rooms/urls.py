from rest_framework.routers import DefaultRouter
from .views import RoomViewSet, RoomBookingViewSet

router = DefaultRouter()
router.register("rooms", RoomViewSet, basename="room")
router.register("bookings", RoomBookingViewSet, basename="booking")

urlpatterns = router.urls