from django.contrib import admin
from django.urls import path, include
from django.conf import  settings
from django.conf.urls.static import static

urlpatterns = [
    path('admin/', admin.site.urls),
    path("api/auth/", include('apps.accounts.urls')),
    path('api/platform/', include('apps.platform_app.urls')),
    path("api/bar/", include("apps.bar.urls")),
    path("api/rooms/", include("apps.rooms.urls")),
    path("api/", include("apps.activity_log.urls")),
    path("api/", include("apps.notifications.urls")),
    path("api/", include("apps.approvals.urls")),
    path("api/reports/", include("apps.reports.urls"))
]
urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)