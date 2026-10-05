import subprocess
import time
import os

UDID = "A64F9A93-E303-47E4-B0B8-A42407DE18F5"
BUNDLE_ID = "com.dangvietquan.shepherd"
OUTPUT_DIR = "/Users/quandang_1/.treehouse/shepherd-bible-c19586/2/shepherd-bible/docs/screenshots"
os.makedirs(OUTPUT_DIR, exist_ok=True)

screens = [
    # Screen fixture name, extra args, base filename
    ("Home_DailyPath", ["-skipOnboarding"], "Home_DailyPath"),
    ("Home_Scrolled", ["-skipOnboarding"], "Home_Scrolled"),
    ("Home_Day1Done", ["-day1Done"], "Home_Day1Done"),
    ("Path_Overview", ["-skipOnboarding"], "Path_Overview"),
    ("Path_Lessons", ["-skipOnboarding"], "Path_Lessons"),
    ("Lesson_Reading", ["-skipOnboarding"], "Lesson_Reading"),
    ("Quiz_Unanswered", ["-skipOnboarding"], "Quiz_Unanswered"),
    ("Quiz_Selected", ["-skipOnboarding"], "Quiz_Selected"),
    ("Quiz_Correct", ["-skipOnboarding"], "Quiz_Correct"),
    ("Quiz_Wrong", ["-skipOnboarding"], "Quiz_Wrong"),
    ("Quiz_Q2_Wrong", ["-skipOnboarding"], "Quiz_Q2_Wrong"),
    ("Lesson_Complete", ["-skipOnboarding"], "Lesson_Complete"),
    ("Companion_Detail", ["-skipOnboarding"], "Companion_Detail"),
    ("Bible_Reader", ["-skipOnboarding"], "Bible_Reader"),
    ("Bible_Picker", ["-skipOnboarding"], "Bible_Picker"),
    ("Settings", ["-skipOnboarding"], "Settings"),
    ("Settings_RestoreResult", ["-skipOnboarding"], "Settings_RestoreResult"),
    ("Onboarding_Welcome", ["-cleanStore"], "Onboarding_Welcome"),
    ("Onboarding_Goal", ["-cleanStore"], "Onboarding_Goal"),
    ("Onboarding_Experience", ["-cleanStore"], "Onboarding_Experience"),
    ("Onboarding_Pace", ["-cleanStore"], "Onboarding_Pace"),
    ("Onboarding_NameLamb", ["-cleanStore"], "Onboarding_NameLamb"),
    ("Onboarding_BuildingPlan", ["-cleanStore"], "Onboarding_BuildingPlan"),
    ("Paywall_Trial", ["-skipOnboarding"], "Paywall_Trial"),
    ("Paywall_Purchasing", ["-skipOnboarding"], "Paywall_Purchasing"),
    ("Paywall_Pending", ["-skipOnboarding"], "Paywall_Pending"),
    ("Paywall_Failed", ["-skipOnboarding"], "Paywall_Failed"),
    ("Paywall_Restored", ["-skipOnboarding"], "Paywall_Restored"),
]

for mode in ["Light", "Dark"]:
    for screen_name, extra_args, base_filename in screens:
        target_path = os.path.join(OUTPUT_DIR, f"{base_filename}_{mode}.png")
        print(f"Capturing {base_filename}_{mode}.png...")

        subprocess.run(["xcrun", "simctl", "terminate", UDID, BUNDLE_ID], capture_output=True)
        time.sleep(0.3)

        cmd = [
            "xcrun", "simctl", "launch", UDID, BUNDLE_ID,
            "-appearance", mode.lower(),
            "-screen", screen_name
        ] + extra_args
        subprocess.run(cmd, capture_output=True)
        time.sleep(1.2)

        subprocess.run(["xcrun", "simctl", "io", UDID, "screenshot", target_path], capture_output=True)
        if os.path.exists(target_path):
            size_kb = os.path.getsize(target_path) // 1024
            print(f" -> OK: {size_kb} KB")
        else:
            print(f" -> FAILED to create {target_path}")

subprocess.run(["xcrun", "simctl", "terminate", UDID, BUNDLE_ID], capture_output=True)
print("Finished capturing all screens!")
