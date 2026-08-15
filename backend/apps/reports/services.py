from datetime import datetime, time, timedelta
from django.db.models import Sum, Count, F
from django.db.models.functions import TruncDate
from apps.bar.models import SaleLineItem, Salary, NonBusinessTransaction, FreeGiveaway

def profit_report(business, start_date, end_date):
    lines = SaleLineItem.objects.filter(
        sale__business=business, sale__status="confirmed",
        sale__confirmed_at__range=(start_date, end_date),
    )

    projected = lines.aggregate(
        total=Sum((F("unit_price") - F("item__buying_price")) * F("quantity"))
    )["total"] or 0

    salaries = NonBusinessTransaction.objects.filter(
        business=business, type=NonBusinessTransaction.Type.SALARY,
        created_at__range=(start_date, end_date),
    ).aggregate(total=Sum("amount"))["total"] or 0

    projected_profit = projected - salaries

    discounts = lines.aggregate(total=Sum("discount_amount"))["total"] or 0

    nbt_out = NonBusinessTransaction.objects.filter(
        business=business, direction="out", created_at__range=(start_date, end_date)
    ).aggregate(total=Sum("amount"))["total"] or 0
    nbt_in = NonBusinessTransaction.objects.filter(
        business=business, direction="in", created_at__range=(start_date, end_date)
    ).aggregate(total=Sum("amount"))["total"] or 0

    from apps.bar.models import Loan
    written_off = Loan.objects.filter(
        origin_line_item__sale__business=business, status="written_off",
        written_off_at__range=(start_date, end_date),
    ).aggregate(total=Sum("amount_remaining"))["total"] or 0

    from apps.bar.models import CashCollection
    from apps.approvals.models import ApprovalRequest
    shortfall_approvals = ApprovalRequest.objects.filter(
        business=business, type="shortfall", status="approved",
        classification="shortfall", resolved_at__range=(start_date, end_date),
    )
    approved_shortfalls = 0
    for a in shortfall_approvals:
        try:
            c = CashCollection.objects.get(id=a.reference_id)
            approved_shortfalls += c.variance
        except CashCollection.DoesNotExist:
            pass
    # variance is negative for a shortfall, so this naturally subtracts

    actual_profit = projected_profit - discounts - nbt_out + nbt_in + approved_shortfalls

    actual_profit = projected_profit - discounts - nbt_out + nbt_in + approved_shortfalls - written_off

    return {
        "projected_profit": float(projected_profit),
        "actual_profit": float(actual_profit),
        "divergence": float(actual_profit - projected_profit),
        "breakdown": {
            "discounts": float(discounts),
            "non_business_out": float(nbt_out),
            "non_business_in": float(nbt_in),
            "salaries": float(salaries),
            "approved_shortfalls": float(approved_shortfalls),
            "written_off_loans": float(written_off),
        },
    }

def item_trends(business, start_date, end_date, limit=5):
    from apps.bar.models import SaleLineItem, Item
    from django.db.models import Sum

    lines = SaleLineItem.objects.filter(
        sale__business=business, sale__status="confirmed",
        sale__confirmed_at__range=(start_date, end_date),
    ).values("item__id", "item__name").annotate(total_qty=Sum("quantity")).order_by("-total_qty")

    sold_data = {row["item__id"]: row for row in lines}

    all_items = Item.objects.filter(business=business, is_active=True)
    full_list = []
    for item in all_items:
        row = sold_data.get(item.id)
        full_list.append({"item__id": item.id, "item__name": item.name, "total_qty": row["total_qty"] if row else 0})

    full_list.sort(key=lambda x: x["total_qty"], reverse=True)

    return {
        "most_bought": full_list[:limit],
        "least_bought": sorted(full_list, key=lambda x: x["total_qty"])[:limit],
    }

def room_report(business, start_date, end_date, revenue_limit=5):
    from apps.rooms.models import RoomBooking, Room
    from django.db.models import Sum, Avg, Count
    from django.utils import timezone

    bookings = RoomBooking.objects.filter(
        room__business=business, checkin_time__range=(start_date, end_date),
    )

    revenue = bookings.aggregate(total=Sum("amount_paid"))["total"] or 0
    total_discounts = bookings.aggregate(total=Sum("discount_amount"))["total"] or 0
    booking_count = bookings.count()
    avg_nights = bookings.aggregate(avg=Avg("nights"))["avg"] or 0

    completed = bookings.filter(status="completed")
    active = bookings.filter(status="active")

    by_room_qs = bookings.values("room__id", "room__name").annotate(
        bookings=Count("id"), revenue=Sum("amount_paid")
    ).order_by("-revenue")

    total_room_count = by_room_qs.count()
    by_room = list(by_room_qs[:revenue_limit])

    rooms = Room.objects.filter(business=business, is_active=True)
    room_status = []
    for room in rooms:
        entry = {"id": str(room.id), "name": room.name, "room_type": room.room_type,
                 "nightly_rate": float(room.nightly_rate), "status": room.status}
        if room.status == "occupied":
            active_booking = room.bookings.filter(status="active").order_by("-checkin_time").first()
            if active_booking:
                entry["checkin_time"] = active_booking.checkin_time
        room_status.append(entry)

    return {
        "total_revenue": float(revenue),
        "total_discounts": float(total_discounts),
        "booking_count": booking_count,
        "completed_count": completed.count(),
        "active_count": active.count(),
        "average_nights": round(float(avg_nights), 1),
        "by_room": by_room,
        "by_room_total_count": total_room_count,
        "room_status": room_status,
    }


def dashboard_summary(business):
    from apps.bar.models import Item, Sale, CollectionPeriod, SaleLineItem, Salary
    from apps.rooms.models import RoomBooking
    from apps.approvals.models import ApprovalRequest
    from apps.activity_log.models import ActivityLog
    from django.utils import timezone
    from datetime import timedelta

    today = timezone.now().date()
    today_start = timezone.make_aware(datetime.combine(today, time.min))
    today_end = timezone.make_aware(datetime.combine(today, time.max))

    period = CollectionPeriod.objects.filter(business=business, module="bar", status="open").first()
    expected_to_collect = float(period.opening_expected_amount) if period else 0

    today_sales = Sale.objects.filter(
        business=business, status="confirmed", confirmed_at__range=(today_start, today_end)
    ).aggregate(total=Sum("total_amount"))["total"] or 0

    pending_approvals_qs = ApprovalRequest.objects.filter(business=business, status="pending").order_by("-requested_at")
    pending_count = pending_approvals_qs.count()

    from apps.approvals.serializers import ApprovalRequestSerializer
    pending_preview = ApprovalRequestSerializer(pending_approvals_qs[:5], many=True).data

    low_stock_items = Item.objects.filter(business=business, is_active=True, current_stock__lte=F("low_stock_threshold"))
    low_stock_count = low_stock_items.count()

    # 7-day profit trend
    week_start = timezone.make_aware(datetime.combine(today - timedelta(days=6), time.min))
    trend = []
    for i in range(7):
        day = today - timedelta(days=6 - i)
        day_start = timezone.make_aware(datetime.combine(day, time.min))
        day_end = timezone.make_aware(datetime.combine(day, time.max))
        day_report = profit_report(business, day_start, day_end)
        trend.append({
            "date": day.isoformat(),
            "projected": day_report["projected_profit"],
            "actual": day_report["actual_profit"],
        })

    overall_report = profit_report(business, week_start, today_end)
    trends_data = item_trends(business, week_start, today_end, limit=4)

    recent_logs = ActivityLog.objects.filter(business=business).order_by("-timestamp")[:8]
    recent_activity = [
        {
            "action_type": log.action_type, "entity_type": log.entity_type,
            "actor_name": log.actor.name if log.actor else None,
            "details": log.details, "timestamp": log.timestamp,
        }
        for log in recent_logs
    ]

    return {
        "expected_to_collect": expected_to_collect,
        "today_sales": float(today_sales),
        "pending_approvals_count": pending_count,
        "pending_approvals_preview": pending_preview,
        "low_stock_count": low_stock_count,
        "profit_summary": overall_report,
        "profit_trend": trend,
        "most_bought": trends_data["most_bought"],
        "least_bought": trends_data["least_bought"],
        "recent_activity": recent_activity,
    }

def revenue_by_category(business, start_date, end_date):
    from apps.bar.models import SaleLineItem

    lines = SaleLineItem.objects.filter(
        sale__business=business, sale__status="confirmed",
        sale__confirmed_at__range=(start_date, end_date),
    ).values("item__category__id", "item__category__name").annotate(
        revenue=Sum("line_total"), quantity=Sum("quantity")
    ).order_by("-revenue")

    result = []
    for row in lines:
        result.append({
            "category": row["item__category__name"] or "Uncategorized",
            "revenue": float(row["revenue"] or 0),
            "quantity": row["quantity"] or 0,
        })
    return result


def sales_over_time(business, start_date, end_date):
    from apps.bar.models import Sale
    from django.db.models.functions import TruncDate

    daily = Sale.objects.filter(
        business=business, status="confirmed", confirmed_at__range=(start_date, end_date),
    ).annotate(day=TruncDate("confirmed_at")).values("day").annotate(
        total=Sum("total_amount"), count=Count("id")
    ).order_by("day")

    return [{"date": row["day"].isoformat(), "total": float(row["total"]), "count": row["count"]} for row in daily]

def loans_summary(business, start_date, end_date):
    from apps.bar.models import Loan
    from django.utils import timezone

    outstanding = Loan.objects.filter(
        customer__business=business, status__in=["active", "partially_paid"]
    ).aggregate(total=Sum("amount_remaining"))["total"] or 0

    overdue_count = Loan.objects.filter(
        customer__business=business, status__in=["active", "partially_paid"],
        due_date__lt=timezone.now().date(),
    ).count()

    written_off_qs = Loan.objects.filter(
        customer__business=business, status="written_off",
        written_off_at__range=(start_date, end_date),
    )
    written_off_total = written_off_qs.aggregate(total=Sum("amount_remaining"))["total"] or 0
    written_off_count = written_off_qs.count()

    return {
        "outstanding_balance": float(outstanding),
        "overdue_count": overdue_count,
        "written_off_count": written_off_count,
        "written_off_total": float(written_off_total),
    }


def cash_reconciliation_summary(business, module, start_date, end_date):
    from apps.bar.models import CashCollection
    from apps.approvals.models import ApprovalRequest

    collections = CashCollection.objects.filter(
        collection_period__business=business, collection_period__module=module,
        timestamp__range=(start_date, end_date),
    )

    pending = collections.filter(status="pending").count()
    rejected = collections.filter(status="rejected").count()

    approved_ids = collections.filter(status="approved").values_list("id", flat=True)
    approvals = ApprovalRequest.objects.filter(type="shortfall", reference_id__in=approved_ids)

    matched_count = approvals.filter(classification="matched").count()
    shortfall_count = approvals.filter(classification="shortfall").count()

    shortfall_variance = 0
    for a in approvals.filter(classification="shortfall"):
        c = CashCollection.objects.filter(id=a.reference_id).first()
        if c:
            shortfall_variance += c.variance

    return {
        "matched_count": matched_count,
        "shortfall_count": shortfall_count,
        "pending_count": pending,
        "rejected_count": rejected,
        "shortfall_variance": float(shortfall_variance),
    }



def giveaways_summary(business, start_date, end_date):
    from apps.bar.models import FreeGiveaway
    from django.db.models.functions import TruncDate

    giveaways = FreeGiveaway.objects.filter(
        item__business=business, created_at__range=(start_date, end_date)
    ).select_related("item")

    total_quantity = giveaways.aggregate(total=Sum("quantity"))["total"] or 0
    total_value = sum(g.item.buying_price * g.quantity for g in giveaways)

    daily = giveaways.annotate(day=TruncDate("created_at")).values("day").annotate(
        quantity=Sum("quantity")
    ).order_by("day")

    return {
        "total_quantity": total_quantity,
        "total_value": float(total_value),
        "daily": [{"date": row["day"].isoformat(), "quantity": row["quantity"]} for row in daily],
    }