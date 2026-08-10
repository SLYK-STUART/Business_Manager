from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from .views import PhoneTokenObtainView, MeView, StaffListCreateView, RegisterFcmTokenView, SetPasscodeView, VerifyPasscodeView

urlpatterns = [
    path("login/", PhoneTokenObtainView.as_view(), name="login"),
    path("refresh/", TokenRefreshView.as_view(), name="token_refresh"),
    path("me/", MeView.as_view(), name="me"),
    path("staff/", StaffListCreateView.as_view(), name="staff-list-create"),
    path("fcm-token/", RegisterFcmTokenView.as_view(), name="fcm-token"),
    path("passcode/set/", SetPasscodeView.as_view(), name="set-passcode"),
    path("passcode/verify/", VerifyPasscodeView.as_view(), name="verify-passcode"),
]