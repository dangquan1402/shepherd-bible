import subprocess
import time
import os
import signal

UDID = "A64F9A93-E303-47E4-B0B8-A42407DE18F5"
BUNDLE_ID = "com.dangvietquan.shepherd"
OUTPUT_DIR = "/Users/quandang_1/.treehouse/shepherd-bible-c19586/2/shepherd-bible/docs/screenshots"

def record_motion(screen_name, clip_filename, frame_base):
    subprocess.run(["xcrun", "simctl", "terminate", UDID, BUNDLE_ID], capture_output=True)
    time.sleep(0.3)
    
    # Start video recording in background
    clip_path = os.path.join(OUTPUT_DIR, clip_filename)
    rec_proc = subprocess.Popen(["xcrun", "simctl", "io", UDID, "recordVideo", clip_path])
    time.sleep(0.5)
    
    # Launch app
    subprocess.run(["xcrun", "simctl", "launch", UDID, BUNDLE_ID, "-appearance", "light", "-screen", screen_name, "-skipOnboarding"], capture_output=True)
    
    # Capture sequential frames during the motion
    # The autoHop / autoCheck begins around 0.8s
    time.sleep(0.7)
    subprocess.run(["xcrun", "simctl", "io", UDID, "screenshot", os.path.join(OUTPUT_DIR, f"{frame_base}_frame1.png")], capture_output=True)
    time.sleep(0.2)
    subprocess.run(["xcrun", "simctl", "io", UDID, "screenshot", os.path.join(OUTPUT_DIR, f"{frame_base}_frame2.png")], capture_output=True)
    time.sleep(0.3)
    subprocess.run(["xcrun", "simctl", "io", UDID, "screenshot", os.path.join(OUTPUT_DIR, f"{frame_base}_frame3.png")], capture_output=True)
    
    time.sleep(1.0)
    # Stop video recording via SIGINT
    rec_proc.send_signal(signal.SIGINT)
    try:
        rec_proc.wait(timeout=5)
    except subprocess.TimeoutExpired:
        rec_proc.kill()
        
    subprocess.run(["xcrun", "simctl", "terminate", UDID, BUNDLE_ID], capture_output=True)
    print(f"Captured {clip_filename} and {frame_base} frames!")

print("Starting motion capture...")
record_motion("Motion_LambHop", "Motion_LambHop.mp4", "Motion_LambHop")
record_motion("Motion_CheckMorph", "Motion_CheckMorph.mp4", "Motion_CheckMorph")
print("Done motion capture!")
