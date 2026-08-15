from django.urls import path
from .views import ProfitReportView, CategoryRevenueView, LoansSummaryView, CashReconciliationView, GiveawaysSummaryView, SalesOverTimeView, ItemTrendsView, ExportPdfView, DashboardView, RoomReportView

urlpatterns = [
    path("profit/", ProfitReportView.as_view(), name="profit-report"),
    path("trends/", ItemTrendsView.as_view(), name="item-trends"),
    path("export/pdf/", ExportPdfView.as_view(), name="export-pdf"),
    path("rooms/", RoomReportView.as_view(), name="room-report"),
    path("dashboard/", DashboardView.as_view(), name="dashboard"),
    path("category-revenue/", CategoryRevenueView.as_view(), name="category-revenue"),
    path("sales-over-time/", SalesOverTimeView.as_view(), name="sales-over-time"),
    path("loans-summary/", LoansSummaryView.as_view(), name="loans-summary"),
    path("cash-reconciliation/", CashReconciliationView.as_view(), name="cash-reconciliation"),
    path("giveaways-summary/", GiveawaysSummaryView.as_view(), name="giveaways-summary"),
]