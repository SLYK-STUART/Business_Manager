def log_activity(business, actor, module, action_type, entity_type, entity_id, details=None):
    from .models import ActivityLog
    ActivityLog.objects.create(
        business=business, actor=actor, module=module, action_type=action_type,
        entity_type=entity_type, entity_id=entity_id, details=details or {},
    )