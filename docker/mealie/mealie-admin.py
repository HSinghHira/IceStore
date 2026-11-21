"""IceStore: give Mealie's seeded admin (changeme@example.com / MyPassword)
this install's own password, only while it still has the default one.
Runs as Mealie's user, inside Mealie's virtualenv, once Mealie answers."""
import os
import sys
import time
import urllib.request

new = os.environ.get("MEALIE_ADMIN_PASSWORD", "")
if not new:
    sys.exit(0)

port = os.environ.get("APP_PORT", "9000")
for _ in range(300):
    try:
        urllib.request.urlopen(f"http://127.0.0.1:{port}/api/app/about", timeout=5)
        break
    except Exception:
        time.sleep(2)
else:
    print("[icestore] Mealie did not answer; left the admin password alone", flush=True)
    sys.exit(0)

from mealie.core.security.hasher import get_hasher  # noqa: E402
from mealie.db.db_setup import session_context  # noqa: E402
from mealie.db.models.users import User  # noqa: E402

hasher = get_hasher()
with session_context() as session:
    user = session.query(User).filter(User.email == "changeme@example.com").one_or_none()
    if user is not None and hasher.verify("MyPassword", user.password):
        user.password = hasher.hash(new)
        session.commit()
        print("[icestore] set this install's password on changeme@example.com", flush=True)
