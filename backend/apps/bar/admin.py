from django.contrib import admin
from .models import (
    ItemCategory, Item, PriceChangeLog, RestockRecord, Customer,
    Sale, SaleLineItem, Loan, LoanRepayment, FreeGiveaway,
    NonBusinessTransaction, CollectionPeriod, CashCollection, Salary,
)

admin.site.register(ItemCategory)
admin.site.register(Item)
admin.site.register(PriceChangeLog)
admin.site.register(RestockRecord)
admin.site.register(Customer)
admin.site.register(Sale)
admin.site.register(SaleLineItem)
admin.site.register(Loan)
admin.site.register(LoanRepayment)
admin.site.register(FreeGiveaway)
admin.site.register(NonBusinessTransaction)
admin.site.register(CollectionPeriod)
admin.site.register(CashCollection)
admin.site.register(Salary)