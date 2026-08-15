from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.parsers import  MultiPartParser, FormParser, JSONParser
from django.utils import timezone
from django.db.models import F
from .models import Item, ItemCategory, RestockRecord, Sale, Customer, Loan, CollectionPeriod, CashCollection, Salary, FreeGiveaway, NonBusinessTransaction
from .serializers import (ItemSerializer, ItemCategorySerializer,
                          RestockSerializer, SaleSerializer, SaleCreateSerializer,
                          CustomerSerializer,
                          LoanSerializer, LoanRepaymentSerializer, FreeGiveawaySerializer,
                          CashCollectionSerializer,
                          CashCollectionCreateSerializer, CollectionPeriodSerializer,
                          SalarySerializer, GiveawayBatchCreateSerializer,
                          NonBusinessTransactionSerializer, LoanUpdateSerializer,
                            PendingPricingSerializer, SetRestockPriceSerializer,
                          CollectionSummarySerializer, ItemManagerSerializer, SalaryPaymentSerializer, SalaryPaySerializer
                          )
from .permissions import IsBusinessStaff, BasePermission
from apps.approvals.models import  ApprovalRequest
from ..approvals.services import create_approval_or_auto_approve


class ItemCategoryViewSet(viewsets.ModelViewSet):
    serializer_class = ItemCategorySerializer
    permission_classes = [IsBusinessStaff]

    def get_queryset(self):
        return ItemCategory.objects.filter(business=self.request.user.business)

    def perform_create(self, serializer):
        serializer.save(business=self.request.user.business)


class ItemViewSet(viewsets.ModelViewSet):
    serializer_class = ItemSerializer
    permission_classes = [IsBusinessStaff]
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def get_serializer_class(self):
        if "owner" in self.request.user.roles:
            return ItemSerializer
        return  ItemManagerSerializer

    def get_queryset(self):
        return Item.objects.filter(business=self.request.user.business, is_active=True)

    def perform_create(self, serializer):
        serializer.save(business=self.request.user.business, created_by=self.request.user)

    def perform_destroy(self, instance):
        instance.is_active = False
        instance.save()

    @action(detail=True, methods=["post"])
    def restock(self, request, pk=None):
        item = self.get_object()
        serializer = RestockSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data
        qty = data["quantity"]

        if data.get("total_price"):
            derived_unit_price = data["total_price"] / qty
        elif data.get("unit_price"):
            derived_unit_price = data["unit_price"]
        else:
            derived_unit_price = 0  # pending — Owner sets it later

        RestockRecord.objects.create(
            item=item, quantity=qty,
            buying_price_at_time=derived_unit_price,
            restocked_by=request.user,
        )
        item.current_stock += qty
        if derived_unit_price > 0:
            item.buying_price = derived_unit_price  # most-recent price wins, only if we actually got one
        item.save()
        return Response(ItemSerializer(item).data)

    @action(detail=False, methods=["get"])
    def low_stock(self, request):
        items = self.get_queryset().filter(current_stock__lte=F("low_stock_threshold"))
        return Response(ItemSerializer(items, many=True).data)

    @action(detail=True, methods=["get"])
    def detail_full(self, request, pk=None):
        item = self.get_object()
        history_data = {
            "restocks": [
                {"quantity": r.quantity, "buying_price_at_time": float(r.buying_price_at_time), "timestamp": r.timestamp, "restocked_by": r.restocked_by.name if r.restocked_by else None}
                for r in item.restocks.order_by("-timestamp")[:20]
            ],
            "recent_sales": [
                {"quantity": li.quantity, "line_total": float(li.line_total), "discount": float(li.discount_amount), "timestamp": li.sale.confirmed_at, "sold_by": li.sale.sold_by.name if li.sale.sold_by else None}
                for li in item.salelineitem_set.select_related("sale").order_by("-sale__confirmed_at")[:20]
            ],
        }
        if "owner" in request.user.roles:
            history_data["price_history"] = [
                {"old_price": float(p.old_price), "new_price": float(p.new_price), "changed_by": p.changed_by.name if p.changed_by else None, "timestamp": p.timestamp}
                for p in item.price_history.order_by("-timestamp")[:20]
            ]

        serializer = self.get_serializer(item)
        return Response({"item": serializer.data, "history": history_data})

class SaleViewSet(viewsets.ModelViewSet):
    serializer_class = SaleSerializer
    permission_classes = [IsBusinessStaff]
    http_method_names = ["get", "post"]

    def get_queryset(self):
        return Sale.objects.filter(business=self.request.user.business)

    def create(self, request, *args, **kwargs):
        serializer = SaleCreateSerializer(data=request.data, context={"request": request})
        serializer.is_valid(raise_exception=True)
        sale = serializer.save()
        return Response(SaleSerializer(sale).data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=["post"])
    def undo(self, request, pk=None):
        sale = self.get_object()
        if timezone.now() > sale.undo_deadline:
            return Response({"detail": "Undo window expired."}, status=400)
        sale.status = Sale.Status.UNDONE
        sale.save()
        for line in sale.line_items.all():
            line.item.current_stock += line.quantity
            line.item.save()
        return Response(SaleSerializer(sale).data)

class CustomerViewSet(viewsets.ModelViewSet):
    serializer_class = CustomerSerializer
    permission_classes = [IsBusinessStaff]

    def get_queryset(self):
        return Customer.objects.filter(business=self.request.user.business)

    def perform_create(self, serializer):
        serializer.save(business=self.request.user.business)

    @action(detail=False, methods=["get"], url_path="check-phone")
    def check_phone(self, request):
        phone = request.query_params.get("phone")
        exists = Customer.objects.filter(business=request.user.business, phone=phone).exists()
        return Response({"duplicate": exists})

class LoanViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = LoanSerializer
    permission_classes = [IsBusinessStaff]

    def get_queryset(self):
        return Loan.objects.filter(customer__business=self.request.user.business)

    @action(detail=True, methods=["post"])
    def repay(self, request, pk=None):
        loan = self.get_object()
        serializer = LoanRepaymentSerializer(data=request.data, context={"loan": loan, "request": request})
        serializer.is_valid(raise_exception=True)
        loan = serializer.save()
        return Response(LoanSerializer(loan).data)
    @action(detail=True, methods=["post"])
    def manage(self, request, pk=None):
        loan = self.get_object()
        serializer = LoanUpdateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        loan = serializer.save(loan)
        return Response(LoanSerializer(loan).data)

class FreeGiveawayViewSet(viewsets.ModelViewSet):
    serializer_class = FreeGiveawaySerializer
    permission_classes = [IsBusinessStaff]
    http_method_names = ["get", "post"]

    def get_queryset(self):
        return FreeGiveaway.objects.filter(item__business=self.request.user.business)

    def create(self, request, *args, **kwargs):
        serializer = GiveawayBatchCreateSerializer(data=request.data, context={"request": request})
        serializer.is_valid(raise_exception=True)
        giveaways = serializer.save()
        return Response(FreeGiveawaySerializer(giveaways, many=True).data, status=status.HTTP_201_CREATED)


class NonBusinessTransactionViewSet(viewsets.ModelViewSet):
    serializer_class = NonBusinessTransactionSerializer
    permission_classes = [IsBusinessStaff]
    http_method_names = ["get", "post"]

    def get_queryset(self):
        return NonBusinessTransaction.objects.filter(business=self.request.user.business)

    def perform_create(self, serializer):
        txn = serializer.save(business=self.request.user.business, created_by=self.request.user)
        approval = create_approval_or_auto_approve(
            business=self.request.user.business,
            type_=ApprovalRequest.Type.NON_BUSINESS_TRANSACTION,
            reference_id=txn.id,
            requested_by=self.request.user,
        )
        txn.approval_request = approval
        txn.save()

class IsOwnerOnly(BasePermission):
    def has_permission(self, request, view):
        return request.user.is_authenticated and "owner" in request.user.roles


class CashCollectionViewSet(viewsets.ViewSet):
    permission_classes = [IsBusinessStaff]

    def list(self, request):
        business = request.user.business
        module = request.query_params.get("module", "bar")
        period = CollectionPeriod.objects.filter(business=business, module=module, status="open").first()
        if not period:
            period = CollectionPeriod.objects.create(business=business, module=module, opening_expected_amount=0)
        return Response(CollectionPeriodSerializer(period).data)

    @action(detail=False, methods=["get"])
    def summary(self, request):
        business = request.user.business
        module = request.query_params.get("module", "bar")
        period = CollectionPeriod.objects.filter(business=business, module=module, status="open").first()
        if not period:
            period = CollectionPeriod.objects.create(business=business, module=module,  opening_expected_amount=0)
        return Response(CollectionSummarySerializer(period).data)

    def create(self, request):
        module = request.data.get("module", "bar")
        serializer = CashCollectionCreateSerializer(data=request.data, context={"request": request, "module": module})
        serializer.is_valid(raise_exception=True)
        collection = serializer.save()
        return Response(CashCollectionSerializer(collection).data, status=status.HTTP_201_CREATED)

class PendingPricingViewSet(viewsets.ViewSet):
    permission_classes = [IsOwnerOnly]

    def list(self, request):
        pending = RestockRecord.objects.filter(
            item__business=request.user.business, buying_price_at_time=0
        ).select_related("item", "restocked_by").order_by("-timestamp")
        return Response(PendingPricingSerializer(pending, many=True).data)

    @action(detail=True, methods=["post"])
    def set_price(self, request, pk=None):
        restock = RestockRecord.objects.get(id=pk, item__business=request.user.business)
        serializer = SetRestockPriceSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        restock = serializer.save(restock)
        return Response(PendingPricingSerializer(restock).data)
class SalaryViewSet(viewsets.ModelViewSet):
    serializer_class = SalarySerializer
    permission_classes = [IsOwnerOnly]

    def get_queryset(self):
        return Salary.objects.filter(staff__business=self.request.user.business)

    def perform_create(self, serializer):
        serializer.save(set_by=self.request.user)

    @action(detail=True, methods=["post"])
    def pay(self, request, pk=None):
        salary = self.get_object()
        serializer = SalaryPaySerializer(data=request.data, context={"salary": salary, "request": request})
        serializer.is_valid(raise_exception=True)
        payment = serializer.save()
        return Response(SalaryPaymentSerializer(payment).data, status=status.HTTP_201_CREATED)