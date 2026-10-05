import SwiftUI
import SwiftData

public struct CompanionView: View {
    @Query private var companions: [Companion]
    @Environment(\.modelContext) private var modelContext

    @State private var showRenameSheet: Bool = false
    @State private var newName: String = ""
    @State private var hopTrigger: Int = 0

    private var companion: Companion? { companions.first }

    public init() {}

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
                    // Hero Mascot with Hill Vignette
                    ZStack {
                        HillVignetteView(width: 320, height: 70)
                            .offset(y: 45)

                        AnimatedLambView(
                            stage: currentStage,
                            expression: .idle,
                            displayHeight: 150,
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
                            Text("Stage \(currentStage) · \(LambStage(rawValue: currentStage)?.name ?? ""), \(stageXP) / 50 XP")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(ShepherdTheme.textPrimary)
                            Spacer()
                            if currentStage < 5 {
                                Text("\(neededXP) XP to Stage \(currentStage + 1)")
                                    .font(.subheadline)
                                    .foregroundStyle(ShepherdTheme.textSecondary)
                            } else {
                                Text("Flock Elder")
                                    .font(.subheadline)
                                    .foregroundStyle(ShepherdTheme.textSecondary)
                            }
                        }

                        XPProgressBar(currentXP: currentXP)

                        Text("Keep studying daily — your companion grows every 50 XP.")
                            .font(.footnote)
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

                    // Growth List Rows
                    VStack(alignment: .leading, spacing: 14) {
                        Text("GROWTH")
                            .font(ShepherdTheme.scriptureEyebrow())
                            .foregroundStyle(ShepherdTheme.accentFill)
                            .padding(.horizontal, 20)

                        VStack(spacing: 12) {
                            ForEach(LambStage.allCases) { stage in
                                let isUnlocked = stage.rawValue <= currentStage
                                let isCurrent = stage.rawValue == currentStage

                                HStack(spacing: 16) {
                                    ZStack {
                                        LambAvatarView(stage: stage.rawValue, expression: .idle, size: 52)
                                            .opacity(isUnlocked ? 1.0 : 0.4)

                                        if !isUnlocked {
                                            Circle()
                                                .fill(Color.black.opacity(0.35))
                                                .frame(width: 52, height: 52)
                                            Image(systemName: "lock.fill")
                                                .font(.system(size: 16))
                                                .foregroundStyle(.white)
                                        }
                                    }
                                    .overlay(
                                        Circle()
                                            .stroke(isCurrent ? ShepherdTheme.accentFill : Color.clear, lineWidth: 2)
                                    )

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Stage \(stage.rawValue) · \(stage.name)")
                                            .font(.body.weight(.semibold))
                                            .foregroundStyle(isUnlocked ? ShepherdTheme.textPrimary : ShepherdTheme.textTertiary)

                                        Text(stage.rawValue == 1 ? "Unlocked at the start" : "Unlocks at \(stage.xpThreshold) XP")
                                            .font(.subheadline)
                                            .foregroundStyle(ShepherdTheme.textSecondary)
                                    }

                                    Spacer()

                                    if isUnlocked {
                                        Image(systemName: "checkmark")
                                            .font(.body.weight(.bold))
                                            .foregroundStyle(ShepherdTheme.accentFill)
                                    }
                                }
                                .padding(14)
                                .background(ShepherdTheme.cardSurface)
                                .clipShape(RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD))
                                .overlay(
                                    RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD)
                                        .stroke(ShepherdTheme.surfaceBorder, lineWidth: 1)
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 8)
                }
                .padding(.bottom, 60)
            }
            .background(ShepherdTheme.canvasBg.ignoresSafeArea())
            .scrollEdgeEffectStyle(.soft, for: .top)
            .navigationTitle(companion?.name ?? "Lamb")
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
        }
    }
}
