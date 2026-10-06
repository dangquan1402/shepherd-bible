import SwiftUI
import WidgetKit

@main
struct ShepherdWidgetBundle: WidgetBundle {
    var body: some Widget {
        VerseWidget()
        StreakWidget()
        LockScreenStreakWidget()
    }
}
