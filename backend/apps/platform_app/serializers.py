from rest_framework import serializers
from .models import Business, BusinessModule
from apps.accounts.models import User


class BusinessModuleSerializer(serializers.ModelSerializer):
    class Meta:
        model = BusinessModule
        fields = ["id", "module_type", "is_active"]


class BusinessSerializer(serializers.ModelSerializer):
    modules = BusinessModuleSerializer(many=True, required=False)

    class Meta:
        model = Business
        fields = ["id", "name", "address", "is_active", "created_at", "modules"]
        read_only_fields = ["id", "created_at"]

    def create(self, validated_data):
        modules_data = validated_data.pop("modules", [])
        business = Business.objects.create(
            created_by=self.context["request"].user, **validated_data
        )
        for module in modules_data:
            BusinessModule.objects.create(business=business, **module)
        return business


class OwnerCreateSerializer(serializers.Serializer):
    name = serializers.CharField()
    phone = serializers.CharField()
    password = serializers.CharField(write_only=True)

    def create(self, validated_data):
        business = self.context["business"]
        user = User.objects.create_user(
            phone=validated_data["phone"],
            name=validated_data["name"],
            password=validated_data["password"],
            business=business,
            roles=["owner"],
        )
        return user

class BusinessDetailSerializer(serializers.ModelSerializer):
    modules = BusinessModuleSerializer(many=True, read_only=True)
    staff_count = serializers.SerializerMethodField()
    owner_name = serializers.SerializerMethodField()
    owner_phone = serializers.SerializerMethodField()

    class Meta:
        model = Business
        fields = ["id", "name", "address", "is_active", "created_at", "modules", "staff_count", "owner_name", "owner_phone"]

    def get_staff_count(self, obj):
        return obj.staff.filter(is_active=True).count()

    def get_owner_name(self, obj):
        owner = obj.staff.filter(roles__contains=["owner"]).first()
        return owner.name if owner else None

    def get_owner_phone(self, obj):
        owner = obj.staff.filter(roles__contains=["owner"]).first()
        return owner.phone if owner else None