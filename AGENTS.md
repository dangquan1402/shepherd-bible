# Project agent memory

This file is the project's committed home for project-intrinsic agent knowledge: build, test, release, architecture, and sharp-edge notes that should travel with the code.

- Design lives in `design/`: `shepherd.lib.pen` (tokens + components), `screens/shepherd.pen` (imports it as alias `I`), PNG exports, and the spec in `design/README.md`. The README's token, component, frame and sample-content sections are generated: run `python3 design/tools/readme_tables.py` after changing a `.pen`.
- Edit `.pen` files only through Pencil (app, MCP, or headless `pen interactive` with a safe-save that checks `list_libraries()` is ok). Never hand-edit the JSON; a broken library link or a renamed variable silently flattens token bindings.
- Every top-level screen frame must set `theme: {"I:mode": "light"|"dark"}`, or library bindings render black.
- Release (TestFlight): `tools/archive.sh <build-number>` archives, exports and runs `tools/verify_ipa.sh` (manual signing, "Shepherd AppStore Profile", team 6KH82C884Q); bump the build number each upload. Call asc only as `asc --profile LittleRed ...` (app 6819303372); never `asc auth switch`, never another team's profile.
- Scripture, lesson and quiz text in designs must come verbatim from `Shepherd/Resources/Content/*.json` (WEB). Green/red are reserved for quiz correctness.

## Maintaining this file

Keep this file for knowledge useful to almost every future agent session in this project.
Do not repeat what the codebase already shows; point to the authoritative file or command instead.
Prefer rewriting or pruning existing entries over appending new ones.
When updating this file, preserve this bar for all agents and keep entries concise.
