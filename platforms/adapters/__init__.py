"""Platform adapters. To add a platform:

1. Write platforms/adapters/<name>.py with a class based on Adapter.
2. Add it to ADAPTERS below.
3. Add a platforms.<name> block to platforms/config.yml.
4. Put per-app overrides in platforms/<name>/overrides/<app>.yml.
"""
from .base import Adapter, AppResult, Skip  # noqa: F401
from .casaos import CasaOS
from .mos import MOS

ADAPTERS = {a.name: a for a in (CasaOS, MOS)}
