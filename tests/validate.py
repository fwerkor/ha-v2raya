from pathlib import Path
import hashlib
import struct

import yaml
root = Path(__file__).resolve().parent.parent
repo = yaml.safe_load((root / "repository.yaml").read_text())
addon = yaml.safe_load((root / "v2raya/config.yaml").read_text())
assert repo["url"] == "https://github.com/fwerkor/ha-v2raya"
assert addon["slug"] == "v2raya_proxy"
assert addon["version"] == "0.1.1"
assert addon["image"] == "ghcr.io/fwerkor/ha-v2raya"
assert set(addon["arch"]) == {"amd64", "aarch64"}
assert addon["init"] is False
assert addon.get("host_network", False) is False
assert addon.get("full_access", False) is False
assert addon.get("privileged", []) == []
assert addon["ports"] == {"2017/tcp": 2017, "20170/tcp": 20170, "20171/tcp": 20171, "20172/tcp": 20172}
assert set(addon["ports_description"]) == set(addon["ports"])

# Supervisor artwork follows the recommended image sizes.
for filename, expected_size in (("icon.png", (128, 128)), ("logo.png", (250, 100))):
    content = (root / "v2raya" / filename).read_bytes()
    assert content.startswith(b"\x89PNG\r\n\x1a\n")
    assert content[12:16] == b"IHDR"
    assert struct.unpack(">II", content[16:24]) == expected_size

cn = yaml.safe_load((root / "v2raya_cn/config.yaml").read_text())
assert cn["slug"] == "v2raya_proxy_cn"
assert cn["version"] == addon["version"]
assert cn["image"] == "ghcr.dockerproxy.net/fwerkor/ha-v2raya"
assert cn["ports"] == addon["ports"]
assert cn["arch"] == addon["arch"]
assert cn["init"] is False
assert not cn.get("privileged") and not cn.get("host_network")
for filename, expected_size in (("icon.png", (128, 128)), ("logo.png", (250, 100))):
    content = (root / "v2raya_cn" / filename).read_bytes()
    assert content.startswith(b"\x89PNG\r\n\x1a\n")
    assert struct.unpack(">II", content[16:24]) == expected_size

installer = (root / "scripts/install-local-cn.sh").read_text()
for filename in ("config.yaml", "DOCS.md", "CHANGELOG.md", "icon.png", "logo.png"):
    sha256 = hashlib.sha256((root / "v2raya_cn" / filename).read_bytes()).hexdigest()
    assert f"{filename}) expected={sha256}" in installer, f"Stale installer hash: {filename}"

print("Home Assistant add-on config OK")
