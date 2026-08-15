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

    collection = CashCollection.objects.get(id=approval.reference_id)
    if approved:
        collection.status = "approved"
        collection.save()
        period = collection.collection_period

        if approval.classification == "shortfall":
            # Genuine loss — the remaining gap is written off, not carried
            # forward as still-owed cash. Already reflected in actual profit
            # via the approved_shortfalls deduction in profit_report().
            period.opening_expected_amount = 0
        # classification == "matched" needs no change here — the tentative
        # "remaining" value set at submission time is already correct: it's
        # money deliberately left in the business, still genuinely expected.

        period.last_collection_at = collection.timestamp
        period.save()
    else:
        collection.status = "rejected"
        collection.save()
        period = collection.collection_period
        period.opening_expected_amount = collection.previous_expected_amount
        period.save()

def create_approval_or_auto_approve(business, type_, reference_id, requested_by, classification=None):
    from .models import ApprovalRequest

    approval = ApprovalRequest.objects.create(
        business=business, type=type_, reference_id=reference_id, requested_by=requested_by,
    )

    if "owner" in requested_by.roles:
        resolve_approval(approval, approved=True, resolved_by=requested_by, classification=classification)

    return approval