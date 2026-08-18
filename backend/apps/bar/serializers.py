from rest_framework import serializers
from datetime import  timedelta
from django.utils import timezone
from django.db import  transaction
from django.db.models import Sum
from .models import (Item, ItemCategory, PriceChangeLog,
                     RestockRecord, Sale, SaleLineItem, Loan, Customer, LoanRepayment,
                    FreeGiveaway, NonBusinessTransaction, CollectionPeriod, CashCollection, Salary,
                    SalaryPayment,
                     )

from apps.approvals.models import  ApprovalRequest
from ..approvals.services import create_approval_or_auto_approve


class ItemCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = ItemCategory
        fields = ["id", "name"]

def _log_initial_stock(item, request):
    if item.current_stock > 0:
        RestockRecord.objects.create(
            item=item, quantity=item.current_stock,
            buying_price_at_time=item.buying_price,  # 0 for manager-created items
            restocked_by=request.user,
        )
class ItemSerializer(serializers.ModelSerializer):
    photo = serializers.ImageField(write_only=True, required=False)

    class Meta:
        model = Item
        fields = [
            "id", "name", "category", "buying_price", "selling_price",
            "current_stock", "photo_url", "photo", "low_stock_threshold", "is_active", "created_at",
        ]
        read_only_fields = ["id", "photo_url", "created_at"]



    def create(self, validated_data):
        photo = validated_data.pop("photo", None)
        validated_data["is_active"] = True
        item = Item(**validated_data)

        if photo:
            from django.core.files.storage import default_storage
            path = default_storage.save(f"items/{photo.name}", photo)
            request = self.context.get("request")
            url = default_storage.url(path)
            item.photo_url = request.build_absolute_uri(url) if request else url
        item.save()
        _log_initial_stock(item, self.context["request"])
        return item



    def update(self, instance, validated_data):
        photo = validated_data.pop("photo", None)
        new_price = validated_data.get("selling_price")
        if new_price is not None and new_price != instance.selling_price:
            PriceChangeLog.objects.create(
                item=instance, old_price=instance.selling_price,
                new_price=new_price, changed_by=self.context["request"].user,
            )
        if photo:
            from django.core.files.storage import default_storage
            path = default_storage.save(f"items/{photo.name}", photo)
            request = self.context.get("request")
            url = default_storage.url(path)
            instance.photo_url = request.build_absolute_uri(url) if request else url
        return super().update(instance, validated_data)

class ItemManagerSerializer(serializers.ModelSerializer):
    photo = serializers.ImageField(write_only=True, required=False)

    class Meta:
        model = Item
        fields = [
            "id", "name", "category", "selling_price", "photo", "photo_url",
            "current_stock", "low_stock_threshold", "is_active", "created_at",
        ]
        read_only_fields = ["id", "photo_url", "created_at", "is_active"]

    def create(self, validated_data):
        photo = validated_data.pop("photo", None)
        item = Item(**validated_data)  # buying_price stays at model default (0)
        if photo:
            from django.core.files.storage import default_storage
            path = default_storage.save(f"items/{photo.name}", photo)
            request = self.context.get("request")
            url = default_storage.url(path)
            item.photo_url = request.build_absolute_uri(url) if request else url
        item.save()
        _log_initial_stock(item, self.context["request"])
        return item

    def update(self, instance, validated_data):
        validated_data.pop("current_stock", None)
        photo = validated_data.pop("photo", None)
        new_price = validated_data.get("selling_price")
        if new_price is not None and new_price != instance.selling_price:
            PriceChangeLog.objects.create(
                item=instance, old_price=instance.selling_price,
                new_price=new_price, changed_by=self.context["request"].user,
            )
        if photo:
            from django.core.files.storage import default_storage
            path = default_storage.save(f"items/{photo.name}", photo)
            request = self.context.get("request")
            url = default_storage.url(path)
            instance.photo_url = request.build_absolute_uri(url) if request else url
        return super().update(instance, validated_data)
class RestockSerializer(serializers.Serializer):
    mode = serializers.ChoiceField(choices=["unit", "bulk"], default="unit")
    quantity = serializers.IntegerField(min_value=1)
    unit_price = serializers.DecimalField(max_digits=12, decimal_places=2, required=False)
    total_price = serializers.DecimalField(max_digits=12, decimal_places=2, required=False)


class SaleLineItemInputSerializer(serializers.Serializer):
    item_id = serializers.UUIDField()
    quantity = serializers.IntegerField(min_value=1)
    discount_amount = serializers.DecimalField(max_digits=12, decimal_places=2, default=0)
    payment_status = serializers.ChoiceField(choices=SaleLineItem.PaymentStatus.choices)
    customer_id = serializers.UUIDField(required=False)
    loan_due_date = serializers.DateField(required=False)


class SaleCreateSerializer(serializers.Serializer):
    line_items = SaleLineItemInputSerializer(many=True)

    def create(self, validated_data):
        request = self.context["request"]
        business = request.user.business
        lines_data = validated_data["line_items"]

        with transaction.atomic():
            sale = Sale.objects.create(
                business=business, sold_by=request.user,
                total_amount=0, discount_total=0,
                undo_deadline=timezone.now() + timedelta(minutes=10),
            )

            total = 0
            discount_total = 0

            for line in lines_data:
                item = Item.objects.select_for_update().get(id=line["item_id"], business=business)
                if item.current_stock < line["quantity"]:
                    raise serializers.ValidationError(f"Insufficient stock for {item.name}")

                line_total = (item.selling_price * line["quantity"]) - line["discount_amount"]
                line_item = SaleLineItem.objects.create(
                    sale=sale, item=item, quantity=line["quantity"],
                    unit_price=item.selling_price, discount_amount=line["discount_amount"],
                    line_total=line_total, payment_status=line["payment_status"],
                )

                item.current_stock -= line["quantity"]
                item.save()

                total += line_total
                discount_total += line["discount_amount"]

                if line["payment_status"] in (SaleLineItem.PaymentStatus.LOAN, SaleLineItem.PaymentStatus.PARTIAL):
                    Loan.objects.create(
                        customer_id=line["customer_id"],
                        origin_line_item=line_item,
                        principal_amount=line_total,
                        amount_remaining=line_total,
                        due_date=line.get("loan_due_date") or (timezone.now().date() + timedelta(days=7)),
                        created_by=request.user,
                    )

            sale.total_amount = total
            sale.discount_total = discount_total
            sale.save()

            from .models import CollectionPeriod, SaleLineItem

            period, _ = CollectionPeriod.objects.get_or_create(
                business=business, module="bar", status="open",
                defaults={"opening_expected_amount": 0},
            )

            cash_total = sum(
                li.line_total for li in sale.line_items.all()
                if li.payment_status == SaleLineItem.PaymentStatus.PAID_FULL
            )
            period.opening_expected_amount += cash_total
            period.save()

        return sale

class CustomerSerializer(serializers.ModelSerializer):
    class Meta:
        model = Customer
        fields = ["id", "name", "phone", "fingerprint_template", "created_at"]
        read_only_fields = ["id", "created_at"]

    def validate(self, data):
        if not data.get("fingerprint_template") and not data.get("phone"):
            raise serializers.ValidationError("Phone number is required if no fingerprint is provided.")
        return data

class SaleSerializer(serializers.ModelSerializer):
    class Meta:
        model = Sale
        fields = ["id", "sold_by", "total_amount", "discount_total", "status", "confirmed_at", "undo_deadline"]

class LoanSerializer(serializers.ModelSerializer):
    customer_name = serializers.CharField(source="customer.name", read_only=True)
    customer_phone = serializers.CharField(source="customer.phone", read_only=True)

    # From the related SaleLineItem
    item_name = serializers.CharField(
        source="origin_line_item.item.name", read_only=True, default=None
    )
    quantity = serializers.IntegerField(
        source="origin_line_item.quantity", read_only=True, default=None
    )

    class Meta:
        model = Loan
        fields = [
            "id",
            "customer",
            "customer_name",
            "customer_phone",
            "item_name",
            "quantity",
            "principal_amount",
            "amount_remaining",
            "due_date",
            "status",
            "created_at",
        ]

class LoanRepaymentSerializer(serializers.Serializer):
    amount = serializers.DecimalField(max_digits=12, decimal_places=2, min_value=0.01)

    def create(self, validated_data):
        loan = self.context["loan"]
        amount = validated_data["amount"]
        business = loan.customer.business

        LoanRepayment.objects.create(
            loan=loan, amount=amount, recorded_by=self.context["request"].user
        )
        loan.amount_remaining -= amount
        if loan.amount_remaining <= 0:
            loan.amount_remaining = 0
            loan.status = Loan.Status.PAID
        else:
            loan.status = Loan.Status.PARTIALLY_PAID
        loan.save()

        period = CollectionPeriod.objects.filter(business=business, module="bar", status="open").first()
        if period:
            period.opening_expected_amount += amount
            period.save()

        return loan


class GiveawayLineInputSerializer(serializers.Serializer):
    item_id = serializers.UUIDField()
    quantity = serializers.IntegerField(min_value=1)


class GiveawayBatchCreateSerializer(serializers.Serializer):
    recipient_name = serializers.CharField()
    line_items = GiveawayLineInputSerializer(many=True)

    def create(self, validated_data):
        request = self.context["request"]
        business = request.user.business
        recipient_name = validated_data["recipient_name"]
        created = []

        with transaction.atomic():
            for line in validated_data["line_items"]:
                item = Item.objects.select_for_update().get(id=line["item_id"], business=business)
                if item.current_stock < line["quantity"]:
                    raise serializers.ValidationError(f"Insufficient stock for {item.name}")

                giveaway = FreeGiveaway.objects.create(
                    item=item, quantity=line["quantity"], recipient_name=recipient_name,
                    created_by=request.user,
                )
                item.current_stock -= line["quantity"]
                item.save()

                from apps.approvals.services import create_approval_or_auto_approve
                approval = create_approval_or_auto_approve(
                    business=business, type_=ApprovalRequest.Type.FREE_GIVEAWAY,
                    reference_id=giveaway.id, requested_by=request.user,
                )
                giveaway.approval_request = approval
                giveaway.save()
                created.append(giveaway)

        return created


class FreeGiveawaySerializer(serializers.ModelSerializer):
    class Meta:
        model = FreeGiveaway
        fields = ["id", "item", "quantity", "recipient_name", "created_at"]
        read_only_fields = ["id", "created_at"]


class NonBusinessTransactionSerializer(serializers.ModelSerializer):
    class Meta:
        model = NonBusinessTransaction
        fields = ["id", "direction", "amount", "description", "created_at"]
        read_only_fields = ["id", "created_at"]

class CollectionPeriodSerializer(serializers.ModelSerializer):
    class Meta:
        model = CollectionPeriod
        fields = ["id", "period_start", "period_end", "opening_expected_amount", "closing_expected_amount", "status"]


class CashCollectionCreateSerializer(serializers.Serializer):
    collected_amount = serializers.DecimalField(max_digits=12, decimal_places=2)

    def create(self, validated_data):
        business = self.context["request"].user.business
        module = self.context.get("module", "bar")
        period = CollectionPeriod.objects.filter(business=business, module=module, status="open").first()
        if not period:
            raise serializers.ValidationError("No open collection period.")

        if CashCollection.objects.filter(collection_period=period, status="pending").exists():
            raise serializers.ValidationError("A collection is already pending approval for this module.")

        expected = period.opening_expected_amount
        collected = validated_data["collected_amount"]
        variance = collected - expected
        remaining = expected - collected

        collection = CashCollection.objects.create(
            collection_period=period, expected_amount=expected, collected_amount=collected,
            variance=variance, previous_expected_amount=expected,
            collected_by=self.context["request"].user,
        )

        # Tentatively apply immediately — approval (or explicit classification) can revert this.
        period.opening_expected_amount = remaining
        period.save()

        approval = ApprovalRequest.objects.create(
            business=business, type=ApprovalRequest.Type.SHORTFALL,
            reference_id=collection.id, requested_by=self.context["request"].user,
        )

        if variance == 0 and "owner" in self.context["request"].user.roles:
            # Nothing to classify — exact match is safe to auto-finalize even for Owner.
            from apps.approvals.services import resolve_approval
            resolve_approval(approval, approved=True, resolved_by=self.context["request"].user)

        collection.approval_request = approval
        collection.refresh_from_db()
        return collection


class CashCollectionSerializer(serializers.ModelSerializer):
    class Meta:
        model = CashCollection
        fields = ["id", "expected_amount", "collected_amount", "variance", "status", "timestamp"]

class SalarySerializer(serializers.ModelSerializer):
    staff_name = serializers.CharField(source="staff.name", read_only=True)
    class Meta:
        model = Salary
        fields = ["id", "staff", "staff_name", "amount", "effective_date"]
        read_only_fields = ["id", "effective_date"]

class LoanUpdateSerializer(serializers.Serializer):
    action = serializers.ChoiceField(choices=["reschedule", "write_off"])
    new_due_date = serializers.DateField(required=False)

    def save(self, loan):
        if self.validated_data["action"] == "reschedule":
            loan.due_date = self.validated_data["new_due_date"]
        elif self.validated_data["action"] == "write_off":
            loan.status = Loan.Status.WRITTEN_OFF
            loan.written_off_at = timezone.now()
        loan.save()
        return loan

class CollectionSummarySerializer(serializers.Serializer):
    def to_representation(self, period):
        if period.module == "rooms":
            return self._rooms_summary(period)
        return self._bar_summary(period)

    def _bar_summary(self, period):
        since = period.last_collection_at or period.period_start

        sales = Sale.objects.filter(
            business=period.business, status="confirmed", confirmed_at__gte=since,
        ).prefetch_related("line_items__item")

        sales_data = []
        total_discount = 0
        cash_amount = 0

        for sale in sales:
            items = [
                {"name": li.item.name, "quantity": li.quantity, "line_total": float(li.line_total), "discount": float(li.discount_amount)}
                for li in sale.line_items.all()
            ]
            total_discount += sale.discount_total
            sales_data.append({
                "id": str(sale.id), "total_amount": float(sale.total_amount),
                "discount_total": float(sale.discount_total),
                "sold_by": sale.sold_by.name if sale.sold_by else None,
                "confirmed_at": sale.confirmed_at, "items": items,
            })
            for li in sale.line_items.all():
                if li.payment_status == "paid_full":
                    cash_amount += li.line_total

        # Loans are independent of the collection cycle — show all currently
        # outstanding loans for this business, not just ones tied to this period.
        loan_amount = Loan.objects.filter(
            customer__business=period.business,
            status__in=["active", "partially_paid"],
        ).aggregate(total=Sum("amount_remaining"))["total"] or 0

        giveaways = FreeGiveaway.objects.filter(
            item__business=period.business, created_at__gte=since,
        )
        giveaway_count = giveaways.count()
        giveaway_value = sum(g.item.buying_price * g.quantity for g in giveaways)

        nbts = NonBusinessTransaction.objects.filter(
            business=period.business, created_at__gte=since,
        ).exclude(type=NonBusinessTransaction.Type.SALARY)
        nbt_data = [
            {
                "id": str(n.id), "direction": n.direction, "amount": float(n.amount),
                "description": n.description, "status": n.approval_request.status if n.approval_request else "n/a",
            }
            for n in nbts
        ]

        latest_collection = period.collections.order_by("-timestamp").first()

        pending = CashCollection.objects.filter(collection_period=period, status="pending").first()
        pending_collection = None
        if pending:
            pending_collection = {
                "id": str(pending.id), "expected_amount": float(pending.expected_amount),
                "collected_amount": float(pending.collected_amount), "variance": float(pending.variance),
                "timestamp": pending.timestamp,
            }

        last_approved = CashCollection.objects.filter(collection_period=period, status="approved").order_by("-timestamp").first()
        left_behind = 0
        if last_approved:
            remaining = last_approved.expected_amount - last_approved.collected_amount
            left_behind = remaining if remaining > 0 else 0

        return {
            "period_id": str(period.id),
            "period_start": period.period_start,
            "expected_amount": float(period.opening_expected_amount),
            "module": period.module,
            "sales": sales_data,
            "total_discounts": float(total_discount),
            "non_business_transactions": nbt_data,
            "latest_collection_status": latest_collection.status if latest_collection else None,
            "cash_sales_amount": float(cash_amount),
            "loan_amount": float(loan_amount),
            "pending_collection": pending_collection,
            "left_behind_from_last_collection": float(left_behind),
            "total_sales_amount_including_loans": float(cash_amount + loan_amount),
            "giveaway_count": giveaway_count,
            "giveaway_value": float(giveaway_value),
        }

    def _rooms_summary(self, period):
        from apps.rooms.models import RoomBooking

        since = period.last_collection_at or period.period_start

        bookings = RoomBooking.objects.filter(
            room__business=period.business, checkin_time__gte=since,
        ).select_related("room")

        sales_data = []
        cash_amount = 0
        total_discount = 0

        for b in bookings:
            total_discount += b.discount_amount
            cash_amount += b.amount_paid
            sales_data.append({
                "id": str(b.id), "total_amount": float(b.amount_paid),
                "discount_total": float(b.discount_amount),
                "sold_by": b.marked_by.name if b.marked_by else None,
                "confirmed_at": b.checkin_time,
                "items": [{"name": b.room.name, "quantity": b.nights, "line_total": float(b.amount_paid), "discount": float(b.discount_amount)}],
            })

        latest_collection = period.collections.order_by("-timestamp").first()

        pending = CashCollection.objects.filter(collection_period=period, status="pending").first()
        pending_collection = None
        if pending:
            pending_collection = {
                "id": str(pending.id), "expected_amount": float(pending.expected_amount),
                "collected_amount": float(pending.collected_amount), "variance": float(pending.variance),
                "timestamp": pending.timestamp,
            }

        last_approved = CashCollection.objects.filter(collection_period=period, status="approved").order_by("-timestamp").first()
        left_behind = 0
        if last_approved:
            remaining = last_approved.expected_amount - last_approved.collected_amount
            left_behind = remaining if remaining > 0 else 0

        return {
            "period_id": str(period.id),
            "period_start": period.period_start,
            "expected_amount": float(period.opening_expected_amount),
            "module": period.module,
            "sales": sales_data,
            "pending_collection": pending_collection,
            "left_behind_from_last_collection": float(left_behind),
            "total_discounts": float(total_discount),
            "non_business_transactions": [],
            "latest_collection_status": latest_collection.status if latest_collection else None,
            "cash_sales_amount": float(cash_amount),
            "loan_amount": 0,
            "total_sales_amount_including_loans": float(cash_amount),
            "giveaway_count": 0,
            "giveaway_value": 0,
        }

class SalaryPaySerializer(serializers.Serializer):
    amount = serializers.DecimalField(max_digits=12, decimal_places=2, required=False)

    def create(self, validated_data):
        salary = self.context["salary"]
        request = self.context["request"]
        amount = validated_data.get("amount") or salary.amount

        nbt = NonBusinessTransaction.objects.create(
            business=salary.staff.business, direction=NonBusinessTransaction.Direction.OUT,
            amount=amount, description=f"Salary payment to {salary.staff.name}",
            type=NonBusinessTransaction.Type.SALARY,
            created_by=request.user,
        )
        from apps.approvals.services import create_approval_or_auto_approve
        from apps.approvals.models import ApprovalRequest
        approval = create_approval_or_auto_approve(
            business=salary.staff.business,
            type_=ApprovalRequest.Type.SALARY_PAYMENT,
            reference_id=nbt.id, requested_by=request.user,
        )
        nbt.approval_request = approval
        nbt.save()

        payment = SalaryPayment.objects.create(
            salary=salary, amount=amount, paid_by=request.user, non_business_transaction=nbt,
        )
        return payment


class SalaryPaymentSerializer(serializers.ModelSerializer):
    class Meta:
        model = SalaryPayment
        fields = ["id", "amount", "paid_at"]

class PendingPricingSerializer(serializers.Serializer):
    def to_representation(self, restock):
        return {
            "restock_id": str(restock.id),
            "item_id": str(restock.item.id),
            "item_name": restock.item.name,
            "quantity": restock.quantity,
            "current_buying_price": float(restock.buying_price_at_time),
            "restocked_by": restock.restocked_by.name if restock.restocked_by else None,
            "timestamp": restock.timestamp,
        }


class SetRestockPriceSerializer(serializers.Serializer):
    mode = serializers.ChoiceField(choices=["unit", "bulk"])
    unit_price = serializers.DecimalField(max_digits=12, decimal_places=2, required=False)
    total_price = serializers.DecimalField(max_digits=12, decimal_places=2, required=False)

    def validate(self, data):
        if data["mode"] == "unit" and not data.get("unit_price"):
            raise serializers.ValidationError("unit_price is required for unit mode.")
        if data["mode"] == "bulk" and not data.get("total_price"):
            raise serializers.ValidationError("total_price is required for bulk mode.")
        return data

    def save(self, restock):
        if self.validated_data["mode"] == "bulk":
            derived = self.validated_data["total_price"] / restock.quantity
        else:
            derived = self.validated_data["unit_price"]

        restock.buying_price_at_time = derived
        restock.save()

        restock.item.buying_price = derived
        restock.item.save()
        return restock