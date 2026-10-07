import SwiftUI
import SwiftData

// MARK: - Journal Entry Detail & Edit View

public struct JournalEntryDetailView: View {
    @Bindable public var entry: JournalEntry
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var editedText: String = ""
    @State private var showDeleteAlert: Bool = false

    public init(entry: JournalEntry) {
        self.entry = entry
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Card
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(entry.createdAt.formatted(date: .complete, time: .shortened))
                                .font(.footnote.weight(.medium))
                                .foregroundStyle(ShepherdTheme.textSecondary)

                            Spacer()

                            if let lessonTitle = entry.lessonTitle, !lessonTitle.isEmpty {
                                Text(lessonTitle)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(ShepherdTheme.accentFill)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(ShepherdTheme.accentSubtle)
                                    .clipShape(Capsule())
                            }
                        }

                        if let prompt = entry.prompt, !prompt.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Prompt")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(ShepherdTheme.accent)

                                Text(prompt)
                                    .font(.subheadline.italic())
                                    .foregroundStyle(ShepherdTheme.textPrimary)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(ShepherdTheme.surfaceSunken)
                            .clipShape(RoundedRectangle(cornerRadius: ShepherdTheme.radiusSM))
                            .padding(.top, 4)
                        }
                    }

                    // Editable Reflection Text
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Reflection")
                            .font(.headline)
                            .foregroundStyle(ShepherdTheme.textPrimary)

                        TextEditor(text: $editedText)
                            .font(.body)
                            .foregroundStyle(ShepherdTheme.textPrimary)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 200)
                            .padding(12)
                            .shepherdSurfaceCard()
                    }

                    if let updated = entry.updatedAt {
                        Text("Last edited \(updated.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(ShepherdTheme.textTertiary)
                    }

                    // Action Buttons
                    VStack(spacing: 12) {
                        ProminentGlassButton("Save Changes", icon: "checkmark") {
                            saveChanges()
                        }

                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Reflection")
                            }
                            .font(.body.weight(.medium))
                            .foregroundStyle(ShepherdTheme.error)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }
            .background(ShepherdTheme.canvasBg.ignoresSafeArea())
            .navigationTitle("Reflection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                editedText = entry.text
            }
            .alert("Delete Reflection?", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    modelContext.delete(entry)
                    try? modelContext.save()
                    dismiss()
                }
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }

    private func saveChanges() {
        let trimmed = editedText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            entry.text = trimmed
            entry.updatedAt = .now
            try? modelContext.save()
        }
        dismiss()
    }
}

// MARK: - New Journal Entry Sheet

public struct NewJournalEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var text: String = ""
    @State private var title: String = ""

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    TextField("Title or passage (optional)", text: $title)
                        .font(.body)
                        .padding(12)
                        .shepherdSurfaceCard(cornerRadius: ShepherdTheme.radiusSM)

                    ZStack(alignment: .topLeading) {
                        if text.isEmpty {
                            Text("Write your reflection or prayer…")
                                .font(.body)
                                .foregroundStyle(ShepherdTheme.textTertiary)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 8)
                        }

                        TextEditor(text: $text)
                            .font(.body)
                            .foregroundStyle(ShepherdTheme.textPrimary)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 180)
                    }
                    .padding(12)
                    .shepherdSurfaceCard()

                    ProminentGlassButton("Save to Journal", icon: "square.and.pencil") {
                        save()
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .padding(.top, 8)
                }
                .padding(20)
            }
            .background(ShepherdTheme.canvasBg.ignoresSafeArea())
            .navigationTitle("New Reflection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func save() {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let entry = JournalEntry(
            lessonTitle: trimmedTitle.isEmpty ? nil : trimmedTitle,
            text: trimmedText
        )
        modelContext.insert(entry)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - New Prayer Sheet

public struct NewPrayerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var prayerText: String = ""
    @State private var notesText: String = ""

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Prayer Request")
                            .font(.headline)
                            .foregroundStyle(ShepherdTheme.textPrimary)

                        TextField("What are you praying for?", text: $prayerText, axis: .vertical)
                            .lineLimit(3...6)
                            .font(.body)
                            .padding(12)
                            .shepherdSurfaceCard(cornerRadius: ShepherdTheme.radiusSM)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notes (optional)")
                            .font(.subheadline)
                            .foregroundStyle(ShepherdTheme.textSecondary)

                        TextField("Scripture references, people, or details…", text: $notesText, axis: .vertical)
                            .lineLimit(2...4)
                            .font(.body)
                            .padding(12)
                            .shepherdSurfaceCard(cornerRadius: ShepherdTheme.radiusSM)
                    }

                    ProminentGlassButton("Add Prayer", icon: "plus") {
                        save()
                    }
                    .disabled(prayerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .padding(.top, 8)
                }
                .padding(20)
            }
            .background(ShepherdTheme.canvasBg.ignoresSafeArea())
            .navigationTitle("New Prayer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func save() {
        let trimmedPrayer = prayerText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrayer.isEmpty else { return }

        let trimmedNotes = notesText.trimmingCharacters(in: .whitespacesAndNewlines)
        let newPrayer = PrayerRequest(
            text: trimmedPrayer,
            notes: trimmedNotes.isEmpty ? nil : trimmedNotes
        )
        modelContext.insert(newPrayer)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Edit Prayer Sheet

public struct EditPrayerSheet: View {
    @Bindable public var prayer: PrayerRequest
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var editedText: String = ""
    @State private var editedNotes: String = ""
    @State private var isAnswered: Bool = false
    @State private var showDeleteAlert: Bool = false

    public init(prayer: PrayerRequest) {
        self.prayer = prayer
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Answered Toggle
                    Toggle(isOn: $isAnswered) {
                        HStack(spacing: 8) {
                            Image(systemName: isAnswered ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(isAnswered ? ShepherdTheme.accentFill : ShepherdTheme.textTertiary)
                            Text("Mark as Answered")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(ShepherdTheme.textPrimary)
                        }
                    }
                    .tint(ShepherdTheme.accentFill)
                    .padding(14)
                    .shepherdSurfaceCard(cornerRadius: ShepherdTheme.radiusSM)

                    // Prayer Text
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Prayer Request")
                            .font(.headline)
                            .foregroundStyle(ShepherdTheme.textPrimary)

                        TextField("Prayer request", text: $editedText, axis: .vertical)
                            .lineLimit(3...6)
                            .font(.body)
                            .padding(12)
                            .shepherdSurfaceCard(cornerRadius: ShepherdTheme.radiusSM)
                    }

                    // Notes
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notes")
                            .font(.subheadline)
                            .foregroundStyle(ShepherdTheme.textSecondary)

                        TextField("Notes or updates", text: $editedNotes, axis: .vertical)
                            .lineLimit(2...4)
                            .font(.body)
                            .padding(12)
                            .shepherdSurfaceCard(cornerRadius: ShepherdTheme.radiusSM)
                    }

                    // Save & Delete
                    VStack(spacing: 12) {
                        ProminentGlassButton("Save Changes", icon: "checkmark") {
                            save()
                        }

                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Prayer")
                            }
                            .font(.body.weight(.medium))
                            .foregroundStyle(ShepherdTheme.error)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                    }
                    .padding(.top, 12)
                }
                .padding(20)
            }
            .background(ShepherdTheme.canvasBg.ignoresSafeArea())
            .navigationTitle("Edit Prayer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                editedText = prayer.text
                editedNotes = prayer.notes ?? ""
                isAnswered = prayer.isAnswered
            }
            .alert("Delete Prayer?", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    modelContext.delete(prayer)
                    try? modelContext.save()
                    dismiss()
                }
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }

    private func save() {
        let trimmed = editedText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            prayer.text = trimmed
            let trimmedNotes = editedNotes.trimmingCharacters(in: .whitespacesAndNewlines)
            prayer.notes = trimmedNotes.isEmpty ? nil : trimmedNotes

            if isAnswered != prayer.isAnswered {
                if isAnswered {
                    prayer.markAnswered()
                } else {
                    prayer.markUnanswered()
                }
            }
            try? modelContext.save()
        }
        dismiss()
    }
}

// MARK: - Journal Lock Settings Sheet

public struct JournalLockSettingsSheet: View {
    @ObservedObject private var auth = JournalAuthService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var isEnabled: Bool = false
    @State private var isUpdating: Bool = false

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle(isOn: $isEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Lock Journal")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(ShepherdTheme.textPrimary)

                            Text("Require \(auth.biometricName) to view reflections and prayers.")
                                .font(.footnote)
                                .foregroundStyle(ShepherdTheme.textSecondary)
                        }
                    }
                    .tint(ShepherdTheme.accentFill)
                    .disabled(isUpdating)
                    .onChange(of: isEnabled) { _, newValue in
                        guard newValue != auth.isLockEnabled else { return }
                        isUpdating = true
                        Task {
                            let success = await auth.toggleLock(enabled: newValue)
                            if !success {
                                isEnabled = auth.isLockEnabled
                            }
                            isUpdating = false
                        }
                    }
                } footer: {
                    Text("Your reflections and prayers remain stored purely on this device. When enabled, Pasture verifies your identity before revealing journal entries.")
                        .font(.footnote)
                        .foregroundStyle(ShepherdTheme.textTertiary)
                }

                if auth.isLockEnabled {
                    Section {
                        Button {
                            auth.lock()
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "lock.fill")
                                Text("Lock Journal Now")
                            }
                            .foregroundStyle(ShepherdTheme.accentFill)
                        }
                    }
                }
            }
            .navigationTitle("Journal Privacy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                isEnabled = auth.isLockEnabled
            }
        }
    }
}
