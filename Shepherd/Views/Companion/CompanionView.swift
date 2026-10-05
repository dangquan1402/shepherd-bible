import SwiftUI
import SwiftData

public struct CompanionView: View {
    @Query private var companions: [Companion]
    @Environment(\.modelContext) private var modelContext

    @State private var showRenameSheet: Bool = false
    @State private var newName: String = ""
    @State private var hopTrigger: Int = 0

    public var autoHop: Bool = false

    private var companion: Companion? { companions.first }

    public init(autoHop: Bool = false) {
        self.autoHop = autoHop
    }

    private var currentStage: Int {
        companion?.stage ?? 1
    }

    private var currentXP: Int {
        companion?.xp ?? 0
    }

    private var stageXP: Int {
        currentXP % 50
    }

    private var neededXP: Int {
        50 - stageXP
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero Mascot
                    ZStack {
                        Circle()
                            .fill(ShepherdTheme.accentSubtle.opacity(0.35))
                            .frame(width: 240, height: 240)

                        AnimatedLambView(
                            stage: currentStage,
                            expression: .idle,
                            displayHeight: 140,
                            isBreathing: true,
                            hopTrigger: hopTrigger
                        )
                        .onTapGesture {
                            hopTrigger += 1
                        }
                    }
                    .padding(.top, 16)

                    // Companion Name & Stage
                    VStack(spacing: 6) {
                        Text(companion?.name ?? "Lamb")
                            .font(ShepherdTheme.title1Serif())
                            .foregroundStyle(ShepherdTheme.textPrimary)

                        Text("Stage \(currentStage) · \(LambStage(rawValue: currentStage)?.name ?? "")")
                            .font(.headline)
                            .foregroundStyle(ShepherdTheme.accentFill)
                    }

                    // XP Progress Card
                    VStack(spacing: 10) {
                        HStack {
                            Text("\(stageXP) / 50 XP")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(ShepherdTheme.textPrimary)
                            Spacer()
                            if currentStage < 5 {
                                Text("\(neededXP) XP to Stage \(currentStage + 1)")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(ShepherdTheme.textSecondary)
                            } else {
                                Text("Flock Elder")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(ShepherdTheme.textSecondary)
                            }
                        }

                        XPProgressBar(currentXP: currentXP)

                        Text("Keep studying daily — your companion grows every 50 XP.")
                            .font(.caption)
                            .foregroundStyle(ShepherdTheme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 4)
                    }
                    .padding(18)
                    .background(ShepherdTheme.cardSurface)
                    .clipShape(RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD))
                    .overlay(
                        RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD)
                            .stroke(ShepherdTheme.surfaceBorder, lineWidth: 1)
                    )
                    .padding(.horizontal, 20)

                    // Growth Stages Thumbnails
                    VStack(alignment: .leading, spacing: 14) {
                        Text("GROWTH STAGES")
                            .font(ShepherdTheme.scriptureEyebrow())
                            .foregroundStyle(ShepherdTheme.accent)
                            .padding(.horizontal, 20)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(LambStage.allCases) { stage in
                                    let isUnlocked = stage.rawValue <= currentStage
                                    let isCurrent = stage.rawValue == currentStage

                                    VStack(spacing: 8) {
                                        ZStack {
                                            LambAvatarView(stage: stage.rawValue, expression: .idle, size: 56)
                                                .opacity(isUnlocked ? 1.0 : 0.4)

                                            if !isUnlocked {
                                                Circle()
                                                    .fill(Color.black.opacity(0.35))
                                                    .frame(width: 56, height: 56)
                                                Image(systemName: "lock.fill")
                                                    .font(.system(size: 16))
                                                    .foregroundStyle(.white)
                                            }
                                        }
                                        .overlay(
                                            Circle()
                                                .stroke(isCurrent ? ShepherdTheme.accent : Color.clear, lineWidth: 2)
                                        )

                                        Text(stage.name)
                                            .font(.caption.bold())
                                            .foregroundStyle(isUnlocked ? ShepherdTheme.textPrimary : ShepherdTheme.textTertiary)

                                        Text("\(stage.xpThreshold) XP")
                                            .font(.caption2)
                                            .foregroundStyle(ShepherdTheme.textSecondary)
                                    }
                                    .frame(width: 80)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(.bottom, 60)
            }
            .background(ShepherdTheme.canvasBg.ignoresSafeArea())
            .scrollEdgeEffectStyle(.soft, for: .top)
            .navigationTitle("Companion")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        newName = companion?.name ?? "Lamb"
                        showRenameSheet = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .accessibilityLabel("Rename Companion")
                }
            }
            .sheet(isPresented: $showRenameSheet) {
                NavigationStack {
                    VStack(spacing: 20) {
                        Text("Name your companion")
                            .font(.title2.bold())
                            .foregroundStyle(ShepherdTheme.textPrimary)

                        TextField("Companion name", text: $newName)
                            .textFieldStyle(.roundedBorder)
                            .font(.body)
                            .padding(.horizontal, 20)

                        ProminentGlassButton("Save Name") {
                            if !newName.trimmingCharacters(in: .whitespaces).isEmpty {
                                companion?.name = newName.trimmingCharacters(in: .whitespaces)
                                try? modelContext.save()
                            }
                            showRenameSheet = false
                        }
                        .padding(.horizontal, 20)

                        Spacer()
                    }
                    .padding(.top, 28)
                    .background(ShepherdTheme.canvasBg.ignoresSafeArea())
                    .navigationTitle("Rename")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showRenameSheet = false }
                        }
                    }
                }
                .presentationDetents([.fraction(0.35)])
            }
            .task {
                if autoHop {
                    try? await Task.sleep(nanoseconds: 800_000_000)
                    withAnimation {
                        hopTrigger += 1
                    }
                }
            }
        }
    }
}
