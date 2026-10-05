import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Privacy") {
                    Text("No account. Progress stays on this device.")
                    Text("No ad trackers in v1.")
                }
                Section("About") {
                    Text("Shepherd")
                    Text("Privacy-first Bible learning")
                }
            }
            .navigationTitle("Settings")
        }
    }
}
