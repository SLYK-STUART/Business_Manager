from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import Business, BusinessModule
from .serializers import BusinessSerializer, OwnerCreateSerializer, BusinessDetailSerializer
from .permissions import IsSuperadmin
from apps.accounts.serializers import UserSerializer


class BusinessViewSet(viewsets.ModelViewSet):
    queryset = Business.objects.all().order_by("-created_at")
    permission_classes = [IsSuperadmin]

    def get_serializer_class(self):
        if self.action in ("list", "retrieve"):
            return BusinessDetailSerializer
        return BusinessSerializer

    @action(detail=True, methods=["post"], url_path="toggle-active")
    def toggle_active(self, request, pk=None):
        business = self.get_object()
        business.is_active = not business.is_active
        business.save()
        return Response(BusinessDetailSerializer(business).data)

    @action(detail=True, methods=["post"], url_path="toggle-module")
    def toggle_module(self, request, pk=None):
        business = self.get_object()
        module_type = request.data.get("module_type")
        module, _ = BusinessModule.objects.get_or_create(business=business, module_type=module_type)
        module.is_active = not module.is_active
        module.save()
        return Response(BusinessDetailSerializer(business).data)

    @action(detail=True, methods=["post"], url_path="create-owner")
    def create_owner(self, request, pk=None):
        business = self.get_object()
        serializer = OwnerCreateSerializer(data=request.data, context={"business": business})
        serializer.is_valid(raise_exception=True)
        owner = serializer.save()
        from apps.accounts.serializers import UserSerializer
        return Response(UserSerializer(owner).data, status=status.HTTP_201_CREATED)