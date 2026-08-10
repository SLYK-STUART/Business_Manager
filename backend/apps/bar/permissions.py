from rest_framework.permissions import BasePermission


class IsBusinessStaff(BasePermission):
    """Any authenticated user tied to a business (owner or staff)."""
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.business_id is not None