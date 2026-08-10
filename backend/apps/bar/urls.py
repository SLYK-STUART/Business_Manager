from rest_framework.routers import DefaultRouter
from .views import (ItemViewSet, ItemCategoryViewSet, SaleViewSet,
                    LoanViewSet, FreeGiveawayViewSet,
                    NonBusinessTransactionViewSet, SalaryViewSet, CashCollectionViewSet,
                    CustomerViewSet, PendingPricingViewSet)

router = DefaultRouter()
router.register("sales", SaleViewSet, basename="sale")
router.register("items", ItemViewSet, basename="item")
router.register("customers", CustomerViewSet, basename="customer")
router.register("categories", ItemCategoryViewSet, basename="category")
router.register("loans", LoanViewSet, basename="loan")
router.register("giveaways", FreeGiveawayViewSet, basename="giveaway")
router.register("non-business-transactions", NonBusinessTransactionViewSet, basename="nbt")
router.register("cash-collections", CashCollectionViewSet, basename="cash-collection")
router.register("salaries", SalaryViewSet, basename="salary")
router.register("pending-pricing", PendingPricingViewSet, basename="pending-pricing")

urlpatterns = router.urls