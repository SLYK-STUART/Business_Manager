from django.core.management.base import BaseCommand
from apps.accounts.models import User


class Command(BaseCommand):
    def add_arguments(self, parser):
        parser.add_argument("--phone", required=True)
        parser.add_argument("--name", required=True)
        parser.add_argument("--password", required=True)

    def handle(self, *args, **options):
        if User.objects.filter(phone=options["phone"]).exists():
            self.stdout.write(self.style.ERROR("A user with that phone already exists."))
            return

        user = User.objects.create_user(
            phone=options["phone"], name=options["name"], password=options["password"],
            roles=["superadmin"], is_staff=True, is_superuser=True,
        )
        self.stdout.write(self.style.SUCCESS(f"Superadmin created: {user.name} ({user.phone})"))