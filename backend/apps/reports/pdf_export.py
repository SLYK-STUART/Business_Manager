from io import BytesIO
from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas
from django.core.files.base import ContentFile
from .services import profit_report, item_trends


def generate_profit_pdf(business, start_date, end_date):
    buffer = BytesIO()
    p = canvas.Canvas(buffer, pagesize=A4)
    width, height = A4

    data = profit_report(business, start_date, end_date)
    trends = item_trends(business, start_date, end_date)

    y = height - 50
    p.setFont("Helvetica-Bold", 16)
    p.drawString(50, y, f"{business.name} — Profit Report")
    y -= 20
    p.setFont("Helvetica", 10)
    p.drawString(50, y, f"Period: {start_date} to {end_date}")
    y -= 30

    p.setFont("Helvetica-Bold", 12)
    p.drawString(50, y, "Summary")
    y -= 20
    p.setFont("Helvetica", 10)
    for label, value in [
        ("Projected profit", data["projected_profit"]),
        ("Actual profit", data["actual_profit"]),
        ("Divergence", data["divergence"]),
    ]:
        p.drawString(60, y, f"{label}: {value:.2f}")
        y -= 15

    y -= 15
    p.setFont("Helvetica-Bold", 12)
    p.drawString(50, y, "Divergence breakdown")
    y -= 20
    p.setFont("Helvetica", 10)
    for label, value in data["breakdown"].items():
        p.drawString(60, y, f"{label}: {value:.2f}")
        y -= 15

    y -= 15
    p.setFont("Helvetica-Bold", 12)
    p.drawString(50, y, "Most bought items")
    y -= 20
    p.setFont("Helvetica", 10)
    for item in trends["most_bought"]:
        p.drawString(60, y, f"{item['item__name']}: {item['total_qty']} sold")
        y -= 15

    p.showPage()
    p.save()
    buffer.seek(0)
    return ContentFile(buffer.read(), name=f"profit_report_{start_date}_{end_date}.pdf")