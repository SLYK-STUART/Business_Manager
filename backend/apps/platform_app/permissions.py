from rest_framework.permissions import BasePermission


class IsSuperadmin(BasePermission):
    def has_permission(self, request, view):
        return request.user.is_authenticated and "superadmin" in request.user.roles