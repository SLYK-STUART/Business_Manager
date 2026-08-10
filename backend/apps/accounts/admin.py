from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.contrib.auth.forms import UserCreationForm, UserChangeForm
from .models import User, Permission, RolePermission


class UserCreationFormCustom(UserCreationForm):
    class Meta(UserCreationForm.Meta):
        model = User
        fields = ("phone", "name")


class UserChangeFormCustom(UserChangeForm):
    class Meta(UserChangeForm.Meta):
        model = User
        fields = ("phone", "name", "business", "roles", "is_active", "is_staff")


class UserAdmin(BaseUserAdmin):
    add_form = UserCreationFormCustom
    form = UserChangeFormCustom
    model = User
    list_display = ("phone", "name", "roles", "business", "is_active")
    ordering = ("phone",)
    search_fields = ("phone", "name")

    fieldsets = (
        (None, {"fields": ("phone", "password")}),
        ("Personal info", {"fields": ("name", "business", "roles")}),
        ("Permissions", {"fields": ("is_active", "is_staff", "is_superuser")}),
    )
    add_fieldsets = (
        (None, {
            "classes": ("wide",),
            "fields": ("phone", "name", "password1", "password2"),
        }),
    )


admin.site.register(User, UserAdmin)
admin.site.register(Permission)
admin.site.register(RolePermission)