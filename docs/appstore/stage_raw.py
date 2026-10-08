"""Copy XCUITest captures into goldie's raw capture layout, then run `goldie frame`.

Usage: python3 -I docs/appstore/stage_raw.py <shots dir> <goldie work dir>
Each scene's `flow` in goldie.config.ts names the capture (e.g. Home_DailyPath_Light).
"""
import json
import re
import shutil
import sys
from pathlib import Path

shots, work = Path(sys.argv[1]), Path(sys.argv[2])
config = Path(__file__).with_name("goldie.config.ts")
raw = work / "out" / "raw" / "iphone-6.9"
raw.mkdir(parents=True, exist_ok=True)
shutil.copy(config, work / config.name)
manifest = {"device": "iphone-6.9", "udid": "xcuitest", "capturedAt": "", "screenshots": [], "preview": None}
for scene, capture in re.findall(r'id: "([^"]+)", flow: "([^"]+)"', config.read_text()):
    dest = raw / f"{scene}.png"
    shutil.copy(shots / f"{capture}.png", dest)
    manifest["screenshots"].append({"sceneId": scene, "file": str(dest)})
(raw / "manifest.json").write_text(json.dumps(manifest, indent=2))
print(f"staged {len(manifest['screenshots'])} captures; now: cd {work} && goldie frame --config goldie.config.ts")
