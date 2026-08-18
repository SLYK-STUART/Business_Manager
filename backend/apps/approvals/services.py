from django.utils import timezone


def resolve_approval(approval, approved, resolved_by, classification=None):
    if approval.type == "shortfall" and approved:
        approval.classification = classification or "shortfall"  # default to the safer assumption if not specified
        approval.status = "approved"
    else:
        approval.status = "approved" if approved else "rejected"

    approval.resolved_by = resolved_by
    approval.resolved_at = timezone.now()
    approval.save()

    if approval.type == "free_giveaway":
        _resolve_giveaway(approval, approved)
    elif approval.type == "non_business_transaction":
        _resolve_non_business_transaction(approval, approved)
    elif approval.type == "shortfall":
        _resolve_shortfall(approval, approved)
    elif approval.type == "salary_payment":
        _resolve_salary_payment(approval, approved)


def _resolve_salary_payment(approval, approved):
    # Salary is a profit/expense concern for owner reporting only.
    # It must NOT touch CollectionPeriod.opening_expected_amount —
    # the manager's till reconciliation is unaffected by salary payments.
    if not approved:
        return
    # No-op for till purposes. The NonBusinessTransaction row created by
    # SalaryPaySerializer already exists and is enough for profit reports
    # to query against (type=SALARY, direction=OUT).
    pass

def _resolve_non_business_transaction(approval, approved):
    if not approved:
        return
    from apps.bar.models import NonBusinessTransaction, CollectionPeriod

    txn = NonBusinessTransaction.objects.get(id=approval.reference_id)
    period = CollectionPeriod.objects.filter(business=txn.business, module="bar", status="open").first()
    if not period:
        return

    if txn.direction == "out":
        period.opening_expected_amount -= txn.amount
    else:
        period.opening_expected_amount += txn.amount
    period.save()

def _resolve_giveaway(approval, approved):
    from apps.bar.models import FreeGiveaway
    giveaway = FreeGiveaway.objects.get(id=approval.reference_id)

    if approved:
        from apps.bar.models import NonBusinessTransaction, CollectionPeriod
        total_value = giveaway.item.buying_price * giveaway.quantity
        NonBusinessTransaction.objects.create(
            business=approval.business,
            direction=NonBusinessTransaction.Direction.OUT,
            amount=total_value,
            description=f"Approved free giveaway: {giveaway.quantity}x {giveaway.item.name} to {giveaway.recipient_name}",
            created_by=giveaway.created_by,
            approval_request=approval,
        )
        period = CollectionPeriod.objects.filter(business=approval.business, module="bar", status="open").first()
        if period:
            period.opening_expected_amount -= total_value
            period.save()
    else:
        # Rejected — the item never should have left; restore stock.
        item = giveaway.item
        item.current_stock += giveaway.quantity
        item.save()
def _resolve_shortfall(approval, approved):
    from apps.bar.models import CashCollection
    from django.db.models import Sum
    from decimal import Decimal

    collection = CashCollection.objects.get(id=approval.reference_id)
    period = collection.collection_period

    # Calculate revenue that accrued AFTER this collection was submitted
    # i.e. sales that happened between collection.timestamp and now
    # that haven't been "collected" yet and must be preserved regardless
    # of whether we approve or reject
    from apps.bar.models import Sale
    post_collection_revenue = Sale.objects.filter(
        business=period.business,
        created_at__gt=collection.timestamp,
        # only sales within this period
        created_at__gte=period.period_start,
    ).aggregate(
        total=Sum('total_price')
    )['total'] or Decimal('0')

    if approved:
        collection.status = "approved"
        collection.save()

        if approval.classification == "shortfall":
            # Write off only what was owed at collection time.
            # Post-collection revenue is still genuinely expected.
            period.opening_expected_amount = post_collection_revenue
        # classification == "matched": tentative remaining value is correct,
        # nothing to change beyond preserving post-collection revenue
        # (already tracked via normal sale signals)

        period.last_collection_at = collection.timestamp
        period.save()
    else:
        # Rejected: restore to pre-submission snapshot + add back
        # all revenue that accrued between submission and now
        collection.status = "rejected"
        collection.save()

        period.opening_expected_amount = (
                collection.previous_expected_amount + post_collection_revenue
        )
        period.save()

def create_approval_or_auto_approve(business, type_, reference_id, requested_by, classification=None):
    from .models import ApprovalRequest

    approval = ApprovalRequest.objects.create(
        business=business, type=type_, reference_id=reference_id, requested_by=requested_by,
    )

    if "owner" in requested_by.roles:
        resolve_approval(approval, approved=True, resolved_by=requested_by, classification=classification)

    return approval