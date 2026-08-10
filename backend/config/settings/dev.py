import os
from .base import *

DEBUG = True

ALLOWED_HOSTS = ["*"]

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": "business_manager_dev",
        "USER": "postgres",
        "PASSWORD": os.getenv("DB_PASSWORD", ""),
        "HOST": "localhost",
        "PORT": "5432",
    }
}