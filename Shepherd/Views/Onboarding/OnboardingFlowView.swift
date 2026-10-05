import SwiftUI
import SwiftData

struct OnboardingFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var step = 0
    @State private var goal = "grow_daily"
    @State private var level = "beginner"
    @State private var minutes = 5
    @State private var lambName = "Lamb"
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                progress
                Group {
                    switch step {
                    case 0: welcome
                    case 1: goalStep
                    case 2: levelStep
                    case 3: timeStep
                    case 4: nameLamb
                    default: buildingPlan
                    }
                }
                Spacer()
                Button(action: advance) {
                    Text(step >= 5 ? "See my plan" : "Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(ShepherdTheme.accent)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding()
            .background(ShepherdTheme.softBackground.ignoresSafeArea())
            .sheet(isPresented: $showPaywall) {
                PaywallView(onContinueFree: finishOnboarding, onPurchased: finishOnboarding)
            }
        }
    }

    private var progress: some View {
        ProgressView(value: Double(step + 1), total: 6)
            .tint(ShepherdTheme.accent)
    }

    private var welcome: some View {
        VStack(spacing: 16) {
            Text("🐑")
                .font(.system(size: 72))
            Text("Welcome to Shepherd")
                .font(.largeTitle.bold())
            Text("A few minutes a day. Scripture that sticks. Everything stays on your phone.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
    }

    private var goalStep: some View {
        optionList(
            title: "What’s your goal?",
            options: [
                ("grow_daily", "Grow a daily habit"),
                ("understand", "Understand the Bible better"),
                ("peace", "Find peace & prayer"),
                ("new", "I’m new to faith")
            ],
            selection: $goal
        )
    }

    private var levelStep: some View {
        optionList(
            title: "How familiar are you?",
            options: [
                ("beginner", "Beginner"),
                ("some", "Some experience"),
                ("regular", "I read regularly")
            ],
            selection: $level
        )
    }

    private var timeStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How many minutes a day?")
                .font(.title2.bold())
            Picker("Minutes", selection: $minutes) {
                Text("5 min").tag(5)
                Text("10 min").tag(10)
                Text("15 min").tag(15)
            }
            .pickerStyle(.segmented)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var nameLamb: some View {
        VStack(spacing: 16) {
            Text("🐑").font(.system(size: 64))
            Text("Name your companion")
                .font(.title2.bold())
            TextField("Lamb’s name", text: $lambName)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var buildingPlan: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Building your personal path…")
                .font(.title3.bold())
            Text("Goal: \(goal.replacingOccurrences(of: "_", with: " ")) · \(minutes) min/day")
                .foregroundStyle(.secondary)
        }
    }

    private func optionList(title: String, options: [(String, String)], selection: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.title2.bold())
            ForEach(options, id: \.0) { id, label in
                Button {
                    selection.wrappedValue = id
                } label: {
                    HStack {
                        Text(label)
                        Spacer()
                        if selection.wrappedValue == id {
                            Image(systemName: "checkmark.circle.fill")
                        }
                    }
                    .padding()
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func advance() {
        if step < 5 {
            withAnimation { step += 1 }
            return
        }
        showPaywall = true
    }

    private func finishOnboarding() {
        let profile = UserProfile(goal: goal, experienceLevel: level, dailyMinutes: minutes)
        modelContext.insert(profile)
        if let existing = try? modelContext.fetch(FetchDescriptor<Companion>()).first {
            existing.name = lambName.isEmpty ? "Lamb" : lambName
        } else {
            modelContext.insert(Companion(name: lambName.isEmpty ? "Lamb" : lambName))
        }
        try? modelContext.save()
        showPaywall = false
    }
}
