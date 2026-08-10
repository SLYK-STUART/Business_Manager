def notify(business, recipient, type_, message, related_entity_type=None, related_entity_id=None, expires_at=None, repeat_interval_seconds=None):
    from .models import Notification
    n = Notification.objects.create(
        business=business, recipient=recipient, type=type_, message=message,
        related_entity_type=related_entity_type or "", related_entity_id=related_entity_id,
        expires_at=expires_at, repeat_interval_seconds=repeat_interval_seconds,
    )
    _send_push(recipient, message)
    return n


def _send_push(recipient, message):
    if not recipient.fcm_token:
        return
    from firebase_admin import messaging
    try:
        messaging.send(messaging.Message(
            notification=messaging.Notification(title="Business Manager", body=message),
            token=recipient.fcm_token,
        ))
    except Exception:
        pass  # don't let a push failure break the request; consider logging this


def notify_owner(business, type_, message, **kwargs):
    from apps.accounts.models import User
    owner = User.objects.filter(business=business, roles__contains=["owner"]).first()
    if owner:
        return notify(business, owner, type_, message, **kwargs)