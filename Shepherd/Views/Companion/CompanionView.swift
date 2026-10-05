import SwiftUI
import SwiftData

struct CompanionView: View {
    @Query private var companions: [Companion]
    private var companion: Companion? { companions.first }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("🐑")
                    .font(.system(size: 96))
                Text(companion?.name ?? "Lamb")
                    .font(.largeTitle.bold())
                Text("Stage \(companion?.stage ?? 1)")
                    .foregroundStyle(.secondary)
                ProgressView(value: Double((companion?.xp ?? 0) % 50), total: 50)
                    .tint(ShepherdTheme.accent)
                Text("\(companion?.xp ?? 0) XP")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Keep studying — your lamb grows with your streak.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ShepherdTheme.softBackground.ignoresSafeArea())
            .navigationTitle("Companion")
        }
    }
}
