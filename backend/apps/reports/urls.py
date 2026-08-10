from django.urls import path
from .views import ProfitReportView, ItemTrendsView, ExportPdfView, DashboardView, RoomReportView

urlpatterns = [
    path("profit/", ProfitReportView.as_view(), name="profit-report"),
    path("trends/", ItemTrendsView.as_view(), name="item-trends"),
    path("export/pdf/", ExportPdfView.as_view(), name="export-pdf"),
    path("rooms/", RoomReportView.as_view(), name="room-report"),
    path("dashboard/", DashboardView.as_view(), name="dashboard"),
]