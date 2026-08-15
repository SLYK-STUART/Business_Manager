from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from .models import User
from django.contrib.auth.hashers import make_password, check_password



class PhoneTokenObtainSerializer(TokenObtainPairSerializer):
    username_field = "phone"

    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        token["name"] = user.name
        token["roles"] = user.roles
        token["business_id"] = str(user.business_id) if user.business_id else None
        return token


class UserSerializer(serializers.ModelSerializer):
    has_passcode = serializers.SerializerMethodField()
    business_name = serializers.CharField(source="business.name", read_only=True, default=None)

    class Meta:
        model = User
        fields = ["id", "name", "phone", "roles", "business", "business_name", "is_active", "created_at", "has_passcode"]
        read_only_fields = ["id", "created_at"]

    def get_has_passcode(self, obj):
        return bool(obj.passcode_hash)

class StaffCreateSerializer(serializers.Serializer):
    name = serializers.CharField()
    phone = serializers.CharField()
    password = serializers.CharField(write_only=True)
    roles = serializers.ListField(child=serializers.CharField())

    def create(self, validated_data):
        requester = self.context["request"].user
        return User.objects.create_user(
            phone=validated_data["phone"],
            name=validated_data["name"],
            password=validated_data["password"],
            business=requester.business,
            roles=validated_data["roles"],
        )

class SetPasscodeSerializer(serializers.Serializer):
    passcode = serializers.CharField(min_length=4, max_length=6)

    def save(self, user):
        user.passcode_hash = make_password(self.validated_data["passcode"])
        user.save()
        return user


class VerifyPasscodeSerializer(serializers.Serializer):
    passcode = serializers.CharField()

    def validate(self, data):
        user = self.context["request"].user
        if not user.passcode_hash:
            raise serializers.ValidationError("No passcode set for this account.")
        if not check_password(data["passcode"], user.passcode_hash):
            raise serializers.ValidationError("Incorrect passcode.")
        return data