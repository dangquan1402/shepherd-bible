#!/usr/bin/env python3
import os
import sys
import time
import subprocess
import signal

UDID = "674D368F-D51A-4CB9-A861-790F9BAEB18E"
BUNDLE_ID = "com.dangvietquan.shepherd"
PROJECT_DIR = "/Users/quandang_1/.treehouse/shepherd-bible-c19586/2/shepherd-bible"
DOCS_DIR = os.path.join(PROJECT_DIR, "docs/screenshots")

def run(cmd, env=None, check=True):
    print(f"==> {cmd}")
    res = subprocess.run(cmd, shell=True, env=env, cwd=PROJECT_DIR, capture_output=True, text=True)
    if check and res.returncode != 0:
        print(f"ERROR (code {res.returncode}):")
        print(res.stdout[-1500:] if len(res.stdout) > 1500 else res.stdout)
        print(res.stderr[-1500:] if len(res.stderr) > 1500 else res.stderr)
        sys.exit(res.returncode)
    return res

def get_duration(video_path):
    cmd = f"/opt/homebrew/bin/ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 {video_path}"
    res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    return float(res.stdout.strip())

def run_test(test_name, appearance, content_size="large", uninstall_first=True):
    print(f"\n--- Running {test_name} ({appearance}, {content_size}) ---")
    if uninstall_first:
        run(f"xcrun simctl uninstall {UDID} {BUNDLE_ID}", check=False)
    run(f"xcrun simctl ui {UDID} appearance {appearance}")
    run(f"xcrun simctl ui {UDID} content_size {content_size}")
    
    test_env = os.environ.copy()
    test_env["SHOT_DIR"] = DOCS_DIR
    
    cmd = (
        f"set -o pipefail && xcodebuild test-without-building "
        f"-project Shepherd.xcodeproj -scheme Shepherd "
        f"-destination 'platform=iOS Simulator,id={UDID}' "
        f"-only-testing:ShepherdUITests/RealFlowUITests/{test_name}"
    )
    res = run(cmd, env=test_env, check=True)
    print(f"PASSED: {test_name}")

def main():
    os.makedirs(DOCS_DIR, exist_ok=True)
    
    # 1. Light Full Flow
    run_test("testRealAppFullFlowLight", "light", "large", uninstall_first=True)
    
    # 2. Dark Full Flow
    run_test("testRealAppFullFlowDark", "dark", "large", uninstall_first=True)
    
    # 3. AX3 Light
    run_test("testAccessibilityAX3Light", "light", "accessibility-extra-large", uninstall_first=True)
    
    # 4. AX3 Dark
    run_test("testAccessibilityAX3Dark", "dark", "accessibility-extra-large", uninstall_first=True)
    
    # Reset content size
    run(f"xcrun simctl ui {UDID} content_size large")
    run(f"xcrun simctl ui {UDID} appearance light")
    
    # 5. Motion: LambHop
    print("\n--- Recording Motion_LambHop ---")
    mp4_hop = os.path.join(DOCS_DIR, "Motion_LambHop.mp4")
    if os.path.exists(mp4_hop):
        os.remove(mp4_hop)
    rec_hop = subprocess.Popen(
        f"xcrun simctl io {UDID} recordVideo --codec h264 {mp4_hop}",
        shell=True,
        preexec_fn=os.setsid
    )
    time.sleep(1.0)
    try:
        run_test("testRecordLambHop", "light", "large", uninstall_first=False)
    finally:
        time.sleep(1.5)
        os.killpg(os.getpgid(rec_hop.pid), signal.SIGINT)
        rec_hop.wait()
    
    dur_hop = get_duration(mp4_hop)
    print(f"Motion_LambHop duration: {dur_hop:.2f}s")
    hop_timestamps = [max(0.5, dur_hop - 2.5), max(1.0, dur_hop - 1.5), max(1.5, dur_hop - 0.5)]
    for i, ss in enumerate(hop_timestamps, start=1):
        out_png = os.path.join(DOCS_DIR, f"Motion_LambHop_frame{i}.png")
        run(f"/opt/homebrew/bin/ffmpeg -y -ss {ss:.2f} -i {mp4_hop} -frames:v 1 {out_png}")
    
    # 6. Motion: CheckMorph
    print("\n--- Recording Motion_CheckMorph ---")
    mp4_morph = os.path.join(DOCS_DIR, "Motion_CheckMorph.mp4")
    if os.path.exists(mp4_morph):
        os.remove(mp4_morph)
    rec_morph = subprocess.Popen(
        f"xcrun simctl io {UDID} recordVideo --codec h264 {mp4_morph}",
        shell=True,
        preexec_fn=os.setsid
    )
    time.sleep(1.0)
    try:
        run_test("testRecordCheckMorph", "light", "large", uninstall_first=False)
    finally:
        time.sleep(1.5)
        os.killpg(os.getpgid(rec_morph.pid), signal.SIGINT)
        rec_morph.wait()
    
    dur_morph = get_duration(mp4_morph)
    print(f"Motion_CheckMorph duration: {dur_morph:.2f}s")
    morph_timestamps = [max(0.5, dur_morph - 3.5), max(1.0, dur_morph - 2.2), max(1.5, dur_morph - 1.0)]
    for i, ss in enumerate(morph_timestamps, start=1):
        out_png = os.path.join(DOCS_DIR, f"Motion_CheckMorph_frame{i}.png")
        run(f"/opt/homebrew/bin/ffmpeg -y -ss {ss:.2f} -i {mp4_morph} -frames:v 1 {out_png}")
    
    # 7. Side by side comparison generator
    print("\n--- Generating Side-by-Side Comparisons ---")
    run("python3 tools/generate_side_by_side.py")
    print("ALL DONE SUCCESSFULLY!")

if __name__ == "__main__":
    main()
