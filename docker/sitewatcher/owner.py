"""Create (or reset) SiteWatcher's owner account without a terminal.

Upstream's `sitewatcher setup` and `sitewatcher password` read the user name
with input() and the password with getpass(), which need a terminal. This
runs the same functions (setup_owner, reset_password) with those two
answered from SW_USER and SW_PASS.

    SW_USER=admin SW_PASS=... python owner.py [--reset]

Exit 0: owner made, reset, or already there (and no --reset).
"""
import builtins
import getpass
import os
import sys

from sitewatcher.config import load_config, validate_config
from sitewatcher.webapp.bootstrap import configure_web, migrate_web_database

cfg = load_config(None)
validate_config(cfg)
configure_web(cfg)
migrate_web_database()

from sitewatcher.webapp import accounts  # noqa: E402  (needs Django set up)

user, password = os.environ["SW_USER"], os.environ["SW_PASS"]
builtins.input = lambda prompt="": user
getpass.getpass = lambda prompt="", stream=None: password

if not accounts.Workspace.objects.exists():
    accounts.setup_owner()
    print("[icestore] made the SiteWatcher owner account " + user, flush=True)
elif "--reset" in sys.argv:
    accounts.reset_password()
    print("[icestore] set the owner password from SITEWATCHER_ADMIN_PASSWORD", flush=True)
