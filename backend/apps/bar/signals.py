from django.db.models.signals import post_save
from django.dispatch import receiver
from apps.activity_log.services import log_activity
from apps.notifications.services import notify_owner
from .models import Sale, PriceChangeLog, FreeGiveaway, NonBusinessTransaction, Item


@receiver(post_save, sender=Sale)
def on_sale_saved(sender, instance, created, **kwargs):
    if created:
        log_activity(instance.business, instance.sold_by, "bar", "sale_created", "Sale", instance.id)
        if instance.discount_total > 0:
            notify_owner(instance.business, "discount_applied",
                         f"Sale with discount of {instance.discount_total} by {instance.sold_by.name}")


@receiver(post_save, sender=PriceChangeLog)
def on_price_change(sender, instance, created, **kwargs):
    if created:
        log_activity(instance.item.business, instance.changed_by, "bar", "price_changed",
                     "Item", instance.item.id, {"old": str(instance.old_price), "new": str(instance.new_price)})


@receiver(post_save, sender=FreeGiveaway)
def on_giveaway_created(sender, instance, created, **kwargs):
    if created:
        log_activity(instance.item.business, instance.created_by, "bar", "giveaway_created", "FreeGiveaway", instance.id)
        notify_owner(instance.item.business, "approval_pending",
                     f"{instance.created_by.name} gave away {instance.item.name} to {instance.recipient_name} — approval needed")


@receiver(post_save, sender=NonBusinessTransaction)
def on_nbt_created(sender, instance, created, **kwargs):
    if created:
        log_activity(instance.business, instance.created_by, "bar", "non_business_transaction_created",
                     "NonBusinessTransaction", instance.id)
        notify_owner(instance.business, "approval_pending",
                     f"{instance.created_by.name} logged a non-business transaction — approval needed")


@receiver(post_save, sender=Item)
def on_item_stock_changed(sender, instance, created, **kwargs):
    if not created and instance.current_stock <= instance.low_stock_threshold:
        notify_owner(instance.business, "low_stock", f"{instance.name} is low on stock ({instance.current_stock} left)")