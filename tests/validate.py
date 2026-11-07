from pathlib import Path
import yaml
root = Path(__file__).resolve().parent.parent
repo = yaml.safe_load((root / "repository.yaml").read_text())
addon = yaml.safe_load((root / "v2raya/config.yaml").read_text())
assert repo["url"] == "https://github.com/fwerkor/ha-v2raya-addon"
assert addon["slug"] == "v2raya_proxy"
assert set(addon["arch"]) == {"amd64", "aarch64"}
assert addon["init"] is False
assert addon.get("host_network", False) is False
assert addon.get("full_access", False) is False
assert addon.get("privileged", []) == []
assert addon["ports"] == {"2017/tcp": 2017, "20170/tcp": 20170, "20171/tcp": 20171, "20172/tcp": 20172}
assert set(addon["ports_description"]) == set(addon["ports"])
print("Home Assistant add-on config OK")
