"""Run UI checks in Quickshell's engine (its plugins are statically linked)."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

repo = Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory(prefix='velum-dashboard-test-') as temporary:
    config = Path(temporary) / 'shell'
    shutil.copytree(repo / 'quickshell', config)
    source = (repo / 'tests/dashboard/smoke.qml').read_text()
    (config / 'smoke.qml').write_text(source.replace('../../quickshell/components', 'components'))
    result = subprocess.run(['qs', '-p', str(config / 'smoke.qml')],
                            env={**os.environ, 'QT_QPA_PLATFORM': 'offscreen', 'QT_QUICK_BACKEND': 'software'},
                            text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=20)
    print(result.stdout)
    assert result.returncode == 0 and 'DASHBOARD_SMOKE_PASS' in result.stdout
    assert 'WARN scene:' not in result.stdout and 'DASHBOARD_SMOKE_FAIL' not in result.stdout
