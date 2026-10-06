# Create the Xcode project (on your Mac)

1. Xcode → File → New → Project → **App**
2. Product Name: `Shepherd`
3. Team: your Apple Developer team
4. Organization Identifier: e.g. `com.dangvietquan`
5. Interface: **SwiftUI**, Language: **Swift**, storage: None
6. Save the project **inside this repo** as `Shepherd.xcodeproj` (alongside the `Shepherd/` folder), or create the app folder then replace sources
7. Delete the template `ContentView.swift` / `*App.swift` if they conflict
8. Add all files under `Shepherd/` to the app target
9. Select `web.json` and `paths.json` → Target Membership → **Copy Bundle Resources**
10. Set iOS Deployment Target to **17.0+**
11. Later: In-App Purchase capability; create products matching `StoreKitManager` IDs

Suggested product IDs:
- `com.dangvietquan.shepherd.premium.monthly`
- `com.dangvietquan.shepherd.premium.yearly`
