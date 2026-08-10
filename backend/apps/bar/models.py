import uuid
from django.db import models
from apps.platform_app.models import Business
from apps.accounts.models import User


class ItemCategory(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    business = models.ForeignKey(Business, on_delete=models.CASCADE, related_name="item_categories")
    name = models.CharField(max_length=100)

    def __str__(self):
        return self.name


class Item(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    business = models.ForeignKey(Business, on_delete=models.CASCADE, related_name="items")
    category = models.ForeignKey(ItemCategory, on_delete=models.SET_NULL, null=True, blank=True)
    name = models.CharField(max_length=255)
    buying_price = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    selling_price = models.DecimalField(max_digits=12, decimal_places=2)
    current_stock = models.IntegerField(default=0)
    photo_url = models.URLField(blank=True)
    low_stock_threshold = models.IntegerField(default=5)
    is_active = models.BooleanField(default=True)
    created_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name="items_created")
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name


class PriceChangeLog(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    item = models.ForeignKey(Item, on_delete=models.CASCADE, related_name="price_history")
    old_price = models.DecimalField(max_digits=12, decimal_places=2)
    new_price = models.DecimalField(max_digits=12, decimal_places=2)
    changed_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    timestamp = models.DateTimeField(auto_now_add=True)


class RestockRecord(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    item = models.ForeignKey(Item, on_delete=models.CASCADE, related_name="restocks")
    quantity = models.IntegerField()
    buying_price_at_time = models.DecimalField(max_digits=12, decimal_places=2)
    restocked_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    timestamp = models.DateTimeField(auto_now_add=True)


class Customer(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    business = models.ForeignKey(Business, on_delete=models.CASCADE, related_name="customers")
    name = models.CharField(max_length=255)
    phone = models.CharField(max_length=20, blank=True)
    fingerprint_template = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name


class Sale(models.Model):
    class Status(models.TextChoices):
        CONFIRMED = "confirmed", "Confirmed"
        UNDONE = "undone", "Undone"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    business = models.ForeignKey(Business, on_delete=models.CASCADE, related_name="sales")
    sold_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    total_amount = models.DecimalField(max_digits=12, decimal_places=2)
    discount_total = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.CONFIRMED)
    confirmed_at = models.DateTimeField(auto_now_add=True)
    undo_deadline = models.DateTimeField()


class SaleLineItem(models.Model):
    class PaymentStatus(models.TextChoices):
        PAID_FULL = "paid_full", "Paid full"
        LOAN = "loan", "Loan"
        PARTIAL = "partial", "Partial"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    sale = models.ForeignKey(Sale, on_delete=models.CASCADE, related_name="line_items")
    item = models.ForeignKey(Item, on_delete=models.PROTECT)
    quantity = models.IntegerField()
    unit_price = models.DecimalField(max_digits=12, decimal_places=2)
    discount_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    line_total = models.DecimalField(max_digits=12, decimal_places=2)
    payment_status = models.CharField(max_length=20, choices=PaymentStatus.choices)


class Loan(models.Model):
    class Status(models.TextChoices):
        ACTIVE = "active", "Active"
        PARTIALLY_PAID = "partially_paid", "Partially paid"
        PAID = "paid", "Paid"
        WRITTEN_OFF = "written_off", "Written off"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    customer = models.ForeignKey(Customer, on_delete=models.PROTECT, related_name="loans")
    origin_line_item = models.OneToOneField(SaleLineItem, on_delete=models.SET_NULL, null=True, blank=True)
    principal_amount = models.DecimalField(max_digits=12, decimal_places=2)
    amount_remaining = models.DecimalField(max_digits=12, decimal_places=2)
    due_date = models.DateField()
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.ACTIVE)
    created_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    created_at = models.DateTimeField(auto_now_add=True)


class LoanRepayment(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    loan = models.ForeignKey(Loan, on_delete=models.CASCADE, related_name="repayments")
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    recorded_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    timestamp = models.DateTimeField(auto_now_add=True)


class FreeGiveaway(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    item = models.ForeignKey(Item, on_delete=models.PROTECT)
    recipient_name = models.CharField(max_length=255)
    created_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    approval_request = models.ForeignKey("approvals.ApprovalRequest", on_delete=models.SET_NULL, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)


class NonBusinessTransaction(models.Model):
    class Direction(models.TextChoices):
        IN = "in", "In"
        OUT = "out", "Out"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    business = models.ForeignKey(Business, on_delete=models.CASCADE)
    direction = models.CharField(max_length=10, choices=Direction.choices)
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    description = models.CharField(max_length=255, blank=True)
    created_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    approval_request = models.ForeignKey("approvals.ApprovalRequest", on_delete=models.SET_NULL, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)


class CollectionPeriod(models.Model):
    class Status(models.TextChoices):
        OPEN = "open", "Open"
        CLOSED = "closed", "Closed"

    module = models.CharField(max_length=10, default="bar")  # "bar" or "rooms"
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    business = models.ForeignKey(Business, on_delete=models.CASCADE)
    period_start = models.DateTimeField(auto_now_add=True)
    period_end = models.DateTimeField(null=True, blank=True)
    opening_expected_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    closing_expected_amount = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    status = models.CharField(max_length=10, choices=Status.choices, default=Status.OPEN)


class CashCollection(models.Model):
    class Status(models.TextChoices):
        MATCHED = "matched", "Matched"
        PARTIAL_LEFT_IN_BUSINESS = "partial_left_in_business", "Partial — left in business"
        SHORTFALL_PENDING = "shortfall_pending", "Shortfall pending"
        SHORTFALL_APPROVED = "shortfall_approved", "Shortfall approved"
        OVERAGE_PENDING = "overage_pending", "Overage pending"
        OVERAGE_APPROVED = "overage_approved", "Overage approved"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    collection_period = models.ForeignKey(CollectionPeriod, on_delete=models.CASCADE, related_name="collections")
    expected_amount = models.DecimalField(max_digits=12, decimal_places=2)
    collected_amount = models.DecimalField(max_digits=12, decimal_places=2)
    variance = models.DecimalField(max_digits=12, decimal_places=2)
    status = models.CharField(max_length=25, choices=Status.choices, default=Status.MATCHED)
    collected_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    approval_request = models.ForeignKey("approvals.ApprovalRequest", on_delete=models.SET_NULL, null=True, blank=True)
    timestamp = models.DateTimeField(auto_now_add=True)


class Salary(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    staff = models.ForeignKey(User, on_delete=models.CASCADE, related_name="salaries")
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    effective_date = models.DateField()
    set_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name="salaries_set")

class SalaryPayment(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    salary = models.ForeignKey(Salary, on_delete=models.CASCADE, related_name="payments")
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    paid_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    non_business_transaction = models.OneToOneField(
        "NonBusinessTransaction", on_delete=models.SET_NULL, null=True, blank=True
    )
    paid_at = models.DateTimeField(auto_now_add=True)