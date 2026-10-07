#!/usr/bin/env python3
import os
import sys
import time
import subprocess
import signal

UDID = os.environ["SIM_UDID"]  # your own simulator (e.g. an `xcrun simctl clone`)
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

def app_end_time(video_path, duration):
    """When the app left the screen: the last moment a frame still differs from the final frame
    (which shows the home screen after the test finished). Falls back to the clip duration."""
    try:
        from PIL import Image, ImageChops, ImageStat
    except ImportError:
        return duration
    tmp = video_path + ".probe.png"

    def frame(t):
        subprocess.run(f"/opt/homebrew/bin/ffmpeg -loglevel error -y -ss {t:.2f} -i {video_path} "
                       f"-frames:v 1 -vf scale=160:-1 {tmp}", shell=True, check=True)
        return Image.open(tmp).convert("L")

    last = frame(max(0.0, duration - 0.1))
    t = duration - 0.1
    def differs(t):
        return ImageStat.Stat(ImageChops.difference(frame(t), last)).mean[0] > 12

    while t > 1.0 and not differs(t - 0.25):
        t -= 0.25
    t -= 0.25
    while t + 0.05 < duration and differs(t + 0.05):  # refine to 0.05 s
        t += 0.05
    os.remove(tmp)
    return t


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
    if os.environ.get("DERIVED_DATA"):  # the build-for-testing products to run (default: Xcode's DerivedData)
        cmd += f" -derivedDataPath {os.environ['DERIVED_DATA']}"
    res = run(cmd, env=test_env, check=True)
    print(f"PASSED: {test_name}")

def main():
    os.makedirs(DOCS_DIR, exist_ok=True)
    
    # 1. Light Full Flow
    run_test("testRealAppFullFlowLight", "light", "large", uninstall_first=True)
    
    # 2. Dark Full Flow
    run_test("testRealAppFullFlowDark", "dark", "large", uninstall_first=True)
    
    # 2b. End of path (light, dark)
    run_test("testPathCompleteLight", "light", "large", uninstall_first=True)
    run_test("testPathCompleteDark", "dark", "large", uninstall_first=True)

    # 2c. Reflection step and Journal (light, dark)
    run_test("testJournalAndReflectionLight", "light", "large", uninstall_first=True)
    run_test("testJournalAndReflectionDark", "dark", "large", uninstall_first=True)

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
    end_hop = app_end_time(mp4_hop, dur_hop)
    print(f"Motion_LambHop app on screen until {end_hop:.2f}s")
    hop_timestamps = [max(0.5, end_hop - 2.1), max(1.0, end_hop - 1.5), max(1.5, end_hop - 1.0)]  # idle, apex, land
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
    end_morph = app_end_time(mp4_morph, dur_morph)
    print(f"Motion_CheckMorph app on screen until {end_morph:.2f}s")
    morph_timestamps = [max(0.5, end_morph - 0.6), max(1.0, end_morph - 0.3), max(1.5, end_morph)]  # selected, mid, sheet
    for i, ss in enumerate(morph_timestamps, start=1):
        out_png = os.path.join(DOCS_DIR, f"Motion_CheckMorph_frame{i}.png")
        run(f"/opt/homebrew/bin/ffmpeg -y -ss {ss:.2f} -i {mp4_morph} -frames:v 1 {out_png}")
    
    # 7. Side by side comparison generator
    print("\n--- Generating Side-by-Side Comparisons ---")
    run("python3 tools/generate_side_by_side.py")
    print("ALL DONE SUCCESSFULLY!")

if __name__ == "__main__":
    main()
