"""IceStore all-in-one: make the first admin account.

Upstream Doory has no admin until someone runs `manage.py createsuperuser`. run-svc.sh runs this
in the api chroot after the migrations, on every start. It only acts while there is no superuser:
it then creates AIO_ADMIN_EMAIL with AIO_ADMIN_PASSWORD, or makes an existing account with that
email an admin (keeping its password). Once an admin exists it changes nothing, so a password
changed in Doory is never reset.
"""

import os
import sys

sys.path.insert(0, "/app")
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "doory.settings.prod")

import django  # noqa: E402

django.setup()

from django.contrib.auth import get_user_model  # noqa: E402

email = os.environ.get("AIO_ADMIN_EMAIL", "").strip().lower()
password = os.environ.get("AIO_ADMIN_PASSWORD", "")
User = get_user_model()

if not email or not password:
    print("admin account: no AIO_ADMIN_EMAIL or AIO_ADMIN_PASSWORD, skipped", flush=True)
elif User.objects.filter(is_superuser=True).exists():
    print("admin account: an admin already exists, nothing to do", flush=True)
else:
    user = User.objects.filter(email__iexact=email).first()
    if user:
        user.is_staff = user.is_superuser = True
        user.save(update_fields=["is_staff", "is_superuser"])
        print(f"admin account: {email} already existed and is now an admin (its password is unchanged)", flush=True)
    else:
        User.objects.create_superuser(email=email, password=password)
        print(f"admin account: created {email}", flush=True)
