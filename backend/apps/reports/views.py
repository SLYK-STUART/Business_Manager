from rest_framework.views import APIView
from rest_framework.response import Response
from django.utils.dateparse import parse_date
from .services import profit_report, item_trends
from apps.approvals.views import IsOwnerOnly
from django.core.files.storage import default_storage
from .models import GeneratedReport
from .pdf_export import generate_profit_pdf
from datetime import  datetime, time
from django.utils.timezone import  make_aware
from .services import room_report, loans_summary, cash_reconciliation_summary, giveaways_summary, dashboard_summary, revenue_by_category, sales_over_time

from datetime import datetime, time
from django.utils.timezone import make_aware
from django.utils.dateparse import parse_date


class ProfitReportView(APIView):
    permission_classes = [IsOwnerOnly]

    def get(self, request):
        start = parse_date(request.query_params.get("start"))
        end = parse_date(request.query_params.get("end"))
        start_dt = make_aware(datetime.combine(start, time.min))
        end_dt = make_aware(datetime.combine(end, time.max))
        data = profit_report(request.user.business, start_dt, end_dt)
        return Response(data)


class ItemTrendsView(APIView):
    permission_classes = [IsOwnerOnly]

    def get(self, request):
        start = parse_date(request.query_params.get("start"))
        end = parse_date(request.query_params.get("end"))
        start_dt = make_aware(datetime.combine(start, time.min))
        end_dt = make_aware(datetime.combine(end, time.max))
        data = item_trends(request.user.business, start_dt, end_dt)
        return Response(data)

class DashboardView(APIView):
    permission_classes = [IsOwnerOnly]

    def get(self, request):
        return Response(dashboard_summary(request.user.business))

class RoomReportView(APIView):
    permission_classes = [IsOwnerOnly]

    def get(self, request):
        start = parse_date(request.query_params.get("start"))
        end = parse_date(request.query_params.get("end"))
        start_dt = make_aware(datetime.combine(start, time.min))
        end_dt = make_aware(datetime.combine(end, time.max))
        limit = int(request.query_params.get("revenue_limit", 5))
        data = room_report(request.user.business, start_dt, end_dt, revenue_limit=limit)
        return Response(data)

class ExportPdfView(APIView):
    permission_classes = [IsOwnerOnly]

    def get(self, request):
        start = parse_date(request.query_params.get("start"))
        end = parse_date(request.query_params.get("end"))
        start_dt = make_aware(datetime.combine(start, time.min))
        end_dt = make_aware(datetime.combine(end, time.max))
        pdf_file = generate_profit_pdf(request.user.business, start_dt, end_dt)
        path = default_storage.save(f"reports/{pdf_file.name}", pdf_file)
        file_url = request.build_absolute_uri(default_storage.url(path))

        report = GeneratedReport.objects.create(
            business=request.user.business, type="profit_pdf",
            period=f"{start} to {end}", file_url=file_url,
        )
        return Response({"file_url": file_url, "report_id": report.id})

class CategoryRevenueView(APIView):
    permission_classes = [IsOwnerOnly]

    def get(self, request):
        start = parse_date(request.query_params.get("start"))
        end = parse_date(request.query_params.get("end"))
        start_dt = make_aware(datetime.combine(start, time.min))
        end_dt = make_aware(datetime.combine(end, time.max))
        return Response(revenue_by_category(request.user.business, start_dt, end_dt))


class SalesOverTimeView(APIView):
    permission_classes = [IsOwnerOnly]

    def get(self, request):
        start = parse_date(request.query_params.get("start"))
        end = parse_date(request.query_params.get("end"))
        start_dt = make_aware(datetime.combine(start, time.min))
        end_dt = make_aware(datetime.combine(end, time.max))
        return Response(sales_over_time(request.user.business, start_dt, end_dt))


class LoansSummaryView(APIView):
    permission_classes = [IsOwnerOnly]

    def get(self, request):
        start = parse_date(request.query_params.get("start"))
        end = parse_date(request.query_params.get("end"))
        start_dt = make_aware(datetime.combine(start, time.min))
        end_dt = make_aware(datetime.combine(end, time.max))
        return Response(loans_summary(request.user.business, start_dt, end_dt))


class CashReconciliationView(APIView):
    permission_classes = [IsOwnerOnly]

    def get(self, request):
        start = parse_date(request.query_params.get("start"))
        end = parse_date(request.query_params.get("end"))
        module = request.query_params.get("module", "bar")
        start_dt = make_aware(datetime.combine(start, time.min))
        end_dt = make_aware(datetime.combine(end, time.max))
        return Response(cash_reconciliation_summary(request.user.business, module, start_dt, end_dt))


class GiveawaysSummaryView(APIView):
    permission_classes = [IsOwnerOnly]

    def get(self, request):
        start = parse_date(request.query_params.get("start"))
        end = parse_date(request.query_params.get("end"))
        start_dt = make_aware(datetime.combine(start, time.min))
        end_dt = make_aware(datetime.combine(end, time.max))
        return Response(giveaways_summary(request.user.business, start_dt, end_dt))