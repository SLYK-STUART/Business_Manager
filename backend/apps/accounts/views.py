from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework.views import APIView
from rest_framework import  generics, status
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .models import User
from .permissions import IsOwner
from .serializers import PhoneTokenObtainSerializer, UserSerializer, StaffCreateSerializer, SetPasscodeSerializer, VerifyPasscodeSerializer


class PhoneTokenObtainView(TokenObtainPairView):
    serializer_class = PhoneTokenObtainSerializer


class MeView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        return Response(UserSerializer(request.user).data)

class StaffListCreateView(generics.ListCreateAPIView):
    permission_classes = [IsOwner]
    serializer_class = UserSerializer

    def get_queryset(self):
        return User.objects.filter(business=self.request.user.business)

    def post(self, request, *args, **kwargs):
        serializer = StaffCreateSerializer(data=request.data, context={"request": request})
        serializer.is_valid(raise_exception=True)
        staff = serializer.save()
        return Response(UserSerializer(staff).data, status=status.HTTP_201_CREATED)

class RegisterFcmTokenView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        request.user.fcm_token = request.data.get("fcm_token")
        request.user.save()
        return Response({"status": "ok"})

class SetPasscodeView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = SetPasscodeSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save(request.user)
        return Response({"status": "passcode_set"})


class VerifyPasscodeView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = VerifyPasscodeSerializer(data=request.data, context={"request": request})
        serializer.is_valid(raise_exception=True)
        return Response({"status": "verified"})