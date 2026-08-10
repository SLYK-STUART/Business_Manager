from rest_framework.permissions import BasePermission
from .models import  RolePermission

class IsOwner(BasePermission):
    def has_permission(self, request, view):
        return request.user.is_authenticated and "owner" in request.user.roles

class HasPermission(BasePermission):
    """Usage: permission_classes = [HasPermission]; required_permission = 'bar.sell' on the view."""

    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        required = getattr(view, "required_permission", None)
        if not required:
            return True
        user_roles = request.user.roles
        return RolePermission.objects.filter(role__in=user_roles, permission__codename=required).exists()