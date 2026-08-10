import uuid
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.db import models


class UserManager(BaseUserManager):
    def create_user(self, phone, name, password=None, **extra_fields):
        if not phone:
            raise ValueError("Users must have a phone number")
        user = self.model(phone=phone, name=name, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, phone, name, password=None, **extra_fields):
        extra_fields.setdefault("is_staff", True)
        extra_fields.setdefault("is_superuser", True)
        return self.create_user(phone, name, password, **extra_fields)


class Role(models.TextChoices):
    SUPERADMIN = "superadmin", "Superadmin"
    OWNER = "owner", "Owner"
    BAR_MANAGER = "bar_manager", "Bar Manager"
    ROOM_INCHARGE = "room_incharge", "Room In-charge"


class User(AbstractBaseUser, PermissionsMixin):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    business = models.ForeignKey(
        "platform_app.Business",
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name="staff",
    )
    passcode_hash = models.CharField(max_length=128, blank=True, null=True)
    name = models.CharField(max_length=255)
    phone = models.CharField(max_length=20, unique=True)
    roles = models.JSONField(default=list)  # e.g. ["owner", "bar_manager"]
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)  # Django admin access, not business "staff"
    created_at = models.DateTimeField(auto_now_add=True)
    fcm_token = models.CharField(max_length=255, blank=True, null=True)

    objects = UserManager()

    USERNAME_FIELD = "phone"
    REQUIRED_FIELDS = ["name"]

    def has_role(self, role):
        return role in self.roles

    def __str__(self):
        return f"{self.name} ({self.phone})"


class Permission(models.Model):
    codename = models.CharField(max_length=100, unique=True)  # e.g. "bar.sell"
    description = models.CharField(max_length=255, blank=True)

    def __str__(self):
        return self.codename


class RolePermission(models.Model):
    role = models.CharField(max_length=30, choices=Role.choices)
    permission = models.ForeignKey(Permission, on_delete=models.CASCADE)

    class Meta:
        unique_together = ("role", "permission")

    def __str__(self):
        return f"{self.role} -> {self.permission.codename}"