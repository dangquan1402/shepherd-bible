import type { GoldieConfig } from "goldie";

// Pasture App Store screenshots (iPhone 6.9", 1320 x 2868), framed with goldie 0.2.1.
// Captures are not argent flows: they come from the real UI test run
// (ShepherdUITests/RealFlowUITests: testRealAppFullFlowLight/Dark, testWidgetsOnHomeScreenUpdateAfterLesson)
// on a freshly erased iPhone 17 Pro Max simulator with the status bar pinned to 9:41, and are
// copied into out/raw/iphone-6.9/<scene id>.png with a manifest.json before `goldie frame`.
// See docs/appstore/README.md. Colours are Green Pastures tokens (tools/brand/tokens.py "pasture").

const config: GoldieConfig = {
  appRoot: "../..",
  appPath: "unused-captures-come-from-xcuitest.app",
  bundleId: "com.dangvietquan.shepherd",

  devices: ["iphone-6.9"],
  locales: ["en-US"],
  appearance: "light",

  frame: { variant: "17-pro-silver" },

  theme: {
    // canvas-bg #F9F8F3 into accent-subtle #DCF5EB
    background: "linear-gradient(170deg, #F9F8F3 0%, #F9F8F3 45%, #DCF5EB 100%)",
    headlineColor: "#16231C", // text-primary
    subheadColor: "#47534C", // text-secondary
    fontFamily: '"DM Sans", -apple-system, system-ui, sans-serif',
    copyHeightRatio: 0.2,
    deviceWidthRatio: 0.84,
    layout: "classic",
  },

  store: {
    name: "Pasture: Daily Bible Path",
    subtitle: { "en-US": "Daily Bible Path" },
    developer: "Quan Dang",
    category: "Reference",
    rating: 5.0,
    ratingCount: "New",
    ageRating: "4+",
    price: "Free",
    description: {
      "en-US": "Short guided Bible lessons on a path, with a quiz that shows its verse and a lamb that grows as you go.",
    },
  },

  scenes: [
    { kind: "screenshot", id: "today", flow: "Home_DailyPath_Light",
      headline: { "en-US": "A little Bible, every day" },
      subhead: { "en-US": "Short guided lessons on a path you can follow" } },
    { kind: "screenshot", id: "lesson", flow: "Lesson_Reading_Light",
      headline: { "en-US": "Scripture, plainly explained" },
      subhead: { "en-US": "A passage, a short reflection and a prayer" } },
    { kind: "screenshot", id: "quiz", flow: "Quiz_Correct_Light",
      headline: { "en-US": "Every answer shows its verse" },
      subhead: { "en-US": "A quick quiz after each lesson" } },
    { kind: "screenshot", id: "complete", flow: "Lesson_Complete_Dark",
      headline: { "en-US": "Watch your lamb grow" },
      subhead: { "en-US": "Earn XP and keep your day streak" } },
    { kind: "screenshot", id: "lamb", flow: "Companion_Detail_Light",
      headline: { "en-US": "Name your lamb" },
      subhead: { "en-US": "Five stages, from Newborn to Grown sheep" } },
    { kind: "screenshot", id: "paths", flow: "Path_Overview_Light",
      headline: { "en-US": "Three paths, 74 lessons" },
      subhead: { "en-US": "First Steps is free. Premium paths: first 3 free" } },
    { kind: "screenshot", id: "bible", flow: "Bible_Reader_Dark",
      headline: { "en-US": "The whole Bible, offline" },
      subhead: { "en-US": "All 66 books of the World English Bible" } },
    { kind: "screenshot", id: "widgets", flow: "Widgets_HomeScreen_Clean_Light",
      headline: { "en-US": "Your verse on the Home Screen" },
      subhead: { "en-US": "Widgets for your daily verse and streak" } },
  ],
};

export default config;
