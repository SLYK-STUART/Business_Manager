from django.core.management.base import BaseCommand
from apps.accounts.models import Permission, RolePermission, Role

PERMISSIONS = [
    "bar.sell", "bar.restock", "bar.manage_items", "bar.giveaway",
    "bar.log_non_business_transaction", "bar.create_loan", "bar.repay_loan",
    "bar.collect_cash", "rooms.checkin", "rooms.checkout", "rooms.manage_rooms",
    "approvals.resolve", "reports.view", "staff.manage", "salary.manage",
]

ROLE_MAP = {
    Role.OWNER: PERMISSIONS,  # owner gets everything
    Role.BAR_MANAGER: [
        "bar.sell", "bar.restock", "bar.manage_items", "bar.giveaway",
        "bar.log_non_business_transaction", "bar.create_loan", "bar.repay_loan",
        "bar.collect_cash",
    ],
    Role.ROOM_INCHARGE: ["rooms.checkin", "rooms.checkout"],
}


class Command(BaseCommand):
    def handle(self, *args, **options):
        for codename in PERMISSIONS:
            Permission.objects.get_or_create(codename=codename)

        for role, codenames in ROLE_MAP.items():
            for codename in codenames:
                perm = Permission.objects.get(codename=codename)
                RolePermission.objects.get_or_create(role=role, permission=perm)

        self.stdout.write(self.style.SUCCESS("Permissions seeded."))