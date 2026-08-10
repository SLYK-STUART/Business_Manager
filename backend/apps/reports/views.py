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
from .services import room_report, dashboard_summary

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
        data = item_trends(request.user.business, start, end)
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
        pdf_file = generate_profit_pdf(request.user.business, start, end)
        path = default_storage.save(f"reports/{pdf_file.name}", pdf_file)
        file_url = default_storage.url(path)

        report = GeneratedReport.objects.create(
            business=request.user.business, type="profit_pdf",
            period=f"{start} to {end}", file_url=file_url,
        )
        return Response({"file_url": file_url, "report_id": report.id})