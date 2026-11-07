from pathlib import Path
import os
import subprocess
import tempfile

root = Path(__file__).resolve().parent.parent
script = root / "scripts/check-host-proxy.sh"

with tempfile.TemporaryDirectory() as tmpdir:
    tmp = Path(tmpdir)
    curl = tmp / "curl"
    curl.write_text("""#!/bin/sh
for arg in "$@"; do
  case "$arg" in
    https://github.com/) printf 200; exit 0 ;;
    https://ghcr.io/v2/|https://registry-1.docker.io/v2/) printf 401; exit 0 ;;
  esac
done
exit 1
""")
    curl.chmod(0o755)
    env = {**os.environ, "PATH": f"{tmp}{os.pathsep}{os.environ['PATH']}"}
    result = subprocess.run(
        ["sh", str(script), "192.168.1.10", "20171"],
        env=env, text=True, capture_output=True, check=False,
    )
    assert result.returncode == 0, result.stderr
    assert "PASS GitHub" in result.stdout
    assert "PASS GHCR" in result.stdout
    assert "PASS Docker-Hub" in result.stdout
    assert "does NOT mean Supervisor/Docker are configured" in result.stdout
    for bad_host in ("bad/host", "bad:123", "a b", "$(touch injected)"):
        result = subprocess.run(
            ["sh", str(script), bad_host],
            env=env, text=True, capture_output=True, check=False,
        )
        assert result.returncode == 2
print("Host proxy diagnostic tests OK")
