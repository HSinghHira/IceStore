"""ZimaOS, CasaOS, ReCasaOS and Homeio.

The master compose already is this platform's format, and release-store.yml
builds store.json / store.zip from Apps/ directly. Nothing to generate; the
adapter is here so the report lists every platform the same way.
"""
from .base import Adapter


class CasaOS(Adapter):
    name = "casaos"
    native = True

    def build_app(self, app, out, result):
        if not app.port:
            result.warnings.append("no x-casaos port_map")
