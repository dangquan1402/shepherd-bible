import SwiftUI
import SwiftData

public struct LessonReflectionView: View {
    public let lesson: Lesson
    public var onSave: (String) -> Void
    public var onSkip: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var reflectionText: String = ""
    @FocusState private var isFocused: Bool

    public init(
        lesson: Lesson,
        onSave: @escaping (String) -> Void,
        onSkip: @escaping () -> Void
    ) {
        self.lesson = lesson
        self.onSave = onSave
        self.onSkip = onSkip
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Eyebrow & Title
                    VStack(alignment: .leading, spacing: 6) {
                        Text("DAY \(lesson.dayIndex) REFLECTION")
                            .font(ShepherdTheme.scriptureEyebrow())
                            .foregroundStyle(ShepherdTheme.brand)

                        Text("Reflect & Pray")
                            .font(ShepherdTheme.largeTitleSerif())
                            .foregroundStyle(ShepherdTheme.textPrimary)

                        Text("Take a quiet moment to write your thoughts or prayer. Your reflections stay on this device.")
                            .font(.subheadline)
                            .foregroundStyle(ShepherdTheme.textSecondary)
                    }
                    .padding(.top, 8)

                    // Lesson Prayer Prompt Card
                    if let prompt = lesson.prayerPrompt, !prompt.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "hands.and.sparkles.fill")
                                    .font(.headline)
                                    .foregroundStyle(ShepherdTheme.brand)

                                Text("Today’s Prayer Prompt")
                                    .font(.headline)
                                    .foregroundStyle(ShepherdTheme.brand)
                            }

                            Text(prompt)
                                .font(ShepherdTheme.scriptureBody())
                                .foregroundStyle(ShepherdTheme.textPrimary)
                                .lineSpacing(6)
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(ShepherdTheme.surfaceSunken)
                        .clipShape(RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD))
                    }

                    // Text Editor Card
                    VStack(alignment: .leading, spacing: 8) {
                        ZStack(alignment: .topLeading) {
                            if reflectionText.isEmpty {
                                Text("Write your reflection or prayer here…\n(Tap the microphone on your keyboard to speak)")
                                    .font(.body)
                                    .foregroundStyle(ShepherdTheme.textTertiary)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 8)
                            }

                            TextEditor(text: $reflectionText)
                                .font(.body)
                                .foregroundStyle(ShepherdTheme.textPrimary)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 160)
                                .focused($isFocused)
                                .accessibilityIdentifier("ReflectionTextEditor")
                        }
                        .padding(12)
                        .background(ShepherdTheme.cardSurface)
                        .clipShape(RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD))
                        .overlay(
                            RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD)
                                .stroke(isFocused ? ShepherdTheme.brandFill : ShepherdTheme.surfaceBorder, lineWidth: isFocused ? 2 : 1)
                        )

                        // Privacy footnote
                        HStack(spacing: 6) {
                            Image(systemName: "lock.shield")
                                .font(.footnote)
                                .foregroundStyle(ShepherdTheme.brand)

                            Text("Saved only on this device. You can use the keyboard mic to dictate.")
                                .font(.footnote)
                                .foregroundStyle(ShepherdTheme.textSecondary)
                        }
                        .padding(.horizontal, 4)
                    }

                    // Action Buttons
                    VStack(spacing: 12) {
                        ProminentGlassButton(
                            "Save Reflection",
                            icon: "square.and.pencil",
                            isEnabled: !reflectionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ) {
                            saveReflection()
                        }
                        .accessibilityIdentifier("SaveReflectionButton")

                        Button("Skip for now") {
                            onSkip()
                        }
                        .font(.body.weight(.medium))
                        .foregroundStyle(ShepherdTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .accessibilityIdentifier("SkipReflectionButton")
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, 20)
            }
            .background(ShepherdTheme.canvasBg.ignoresSafeArea())
            .scrollEdgeEffectStyle(.soft, for: .top)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Skip") {
                        onSkip()
                    }
                    .font(.body.weight(.medium))
                    .foregroundStyle(ShepherdTheme.textSecondary)
                }
            }
        }
    }

    private func saveReflection() {
        guard let entry = JournalEntry.reflection(on: lesson, text: reflectionText) else { return }
        modelContext.insert(entry)
        try? modelContext.save()
        onSave(entry.text)
    }
}
