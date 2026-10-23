"""Keep generated maps, downloads and diagnostics outside the game archive."""
import os
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parent
DEFAULT_GAME = ROOT.parent.parent
CACHE = Path(os.environ.get('XDG_CACHE_HOME', Path.home() / '.cache'))
WORKSPACE = Path(os.environ.get('ZK_PORTAL_WORKSPACE', CACHE / 'zero-k/portal-worlds')).expanduser().resolve()


def diagnostic_library(name):
    """Build the optional Linux SDL test helper without writing into the checkout."""
    if not sys.platform.startswith('linux'):
        raise RuntimeError('Offscreen diagnostic helpers require Linux; use --render-fps 0 for uncapped drawing')
    source = ROOT / 'diagnostic-tools' / (name + '.c')
    library = WORKSPACE / 'diagnostic-tools' / (name + '.so')
    library.parent.mkdir(parents=True, exist_ok=True)
    if not library.exists() or source.stat().st_mtime > library.stat().st_mtime:
        subprocess.run(['cc', '-O2', '-shared', '-fPIC', str(source), '-ldl', '-o', str(library)], check=True)
    return library
