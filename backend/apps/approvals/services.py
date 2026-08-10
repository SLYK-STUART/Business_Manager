from django.utils import timezone


def resolve_approval(approval, approved, resolved_by):
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
        NonBusinessTransaction.objects.create(
            business=approval.business,
            direction=NonBusinessTransaction.Direction.OUT,
            amount=giveaway.item.buying_price,
            description=f"Approved free giveaway: {giveaway.item.name} to {giveaway.recipient_name}",
            created_by=giveaway.created_by,
            approval_request=approval,
        )
        period = CollectionPeriod.objects.filter(business=approval.business, module="bar", status="open").first()
        if period:
            period.opening_expected_amount -= giveaway.item.buying_price
            period.save()


def _resolve_shortfall(approval, approved):
    from apps.bar.models import CashCollection, CollectionPeriod

    collection = CashCollection.objects.get(id=approval.reference_id)
    is_overage = collection.variance > 0

    if approved:
        collection.status = "overage_approved" if is_overage else "shortfall_approved"
    collection.save()

    period = collection.collection_period
    period.status = "closed"
    period.period_end = timezone.now()
    period.closing_expected_amount = 0
    period.save()

    CollectionPeriod.objects.create(
        business=period.business, module=period.module, status="open", opening_expected_amount=0,
    )

def create_approval_or_auto_approve(business, type_, reference_id, requested_by):
    from .models import ApprovalRequest

    approval = ApprovalRequest.objects.create(
        business=business, type=type_, reference_id=reference_id, requested_by=requested_by,
    )

    if "owner" in requested_by.roles:
        resolve_approval(approval, approved=True, resolved_by=requested_by)

    return approval