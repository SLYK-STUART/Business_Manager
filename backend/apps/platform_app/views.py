from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import Business
from .serializers import BusinessSerializer, OwnerCreateSerializer
from .permissions import IsSuperadmin
from apps.accounts.serializers import UserSerializer


class BusinessViewSet(viewsets.ModelViewSet):
    queryset = Business.objects.all()
    serializer_class = BusinessSerializer
    permission_classes = [IsSuperadmin]

    @action(detail=True, methods=["post"], url_path="create-owner")
    def create_owner(self, request, pk=None):
        business = self.get_object()
        serializer = OwnerCreateSerializer(data=request.data, context={"business": business})
        serializer.is_valid(raise_exception=True)
        owner = serializer.save()
        return Response(UserSerializer(owner).data, status=status.HTTP_201_CREATED)