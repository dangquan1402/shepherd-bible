import SwiftUI
import SwiftData

struct BibleNoteEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let bookName: String
    let bookAbbrev: String
    let chapter: Int
    let startVerse: Int
    let endVerse: Int
    let verseText: String
    let existingNote: BibleNote?

    @State private var noteContent: String
    @FocusState private var isFocused: Bool

    init(
        bookName: String,
        bookAbbrev: String,
        chapter: Int,
        startVerse: Int,
        endVerse: Int,
        verseText: String,
        existingNote: BibleNote?
    ) {
        self.bookName = bookName
        self.bookAbbrev = bookAbbrev
        self.chapter = chapter
        self.startVerse = startVerse
        self.endVerse = endVerse
        self.verseText = verseText
        self.existingNote = existingNote
        _noteContent = State(initialValue: existingNote?.noteText ?? "")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Scripture quote card
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(BibleFormatter.referenceString(bookName: bookName, chapter: chapter, startVerse: startVerse, endVerse: endVerse))
                                .font(.headline)
                                .foregroundStyle(ShepherdTheme.brand)
                            Spacer()
                            Text("WEB")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(ShepherdTheme.textTertiary)
                        }

                        Text(verseText)
                            .font(ShepherdTheme.scriptureBody())
                            .foregroundStyle(ShepherdTheme.textPrimary)
                            .lineSpacing(5)
                    }
                    .padding(16)
                    .background(ShepherdTheme.surfaceSunken)
                    .clipShape(RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD))
                    .overlay(
                        RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD)
                            .stroke(ShepherdTheme.surfaceBorder, lineWidth: 1)
                    )

                    // Private note input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Private Note")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(ShepherdTheme.textSecondary)

                        ZStack(alignment: .topLeading) {
                            if noteContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isFocused {
                                Text("Write your personal reflection or study notes…")
                                    .font(.body)
                                    .foregroundStyle(ShepherdTheme.textTertiary)
                                    .padding(.top, 8)
                                    .padding(.leading, 5)
                            }

                            TextEditor(text: $noteContent)
                                .font(.body)
                                .foregroundStyle(ShepherdTheme.textPrimary)
                                .frame(minHeight: 140)
                                .focused($isFocused)
                                .scrollContentBackground(.hidden)
                                .accessibilityIdentifier("NoteTextEditor")
                        }
                        .padding(12)
                        .background(ShepherdTheme.cardSurface)
                        .clipShape(RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD))
                        .overlay(
                            RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD)
                                .stroke(isFocused ? ShepherdTheme.brand : ShepherdTheme.surfaceBorder, lineWidth: 1)
                        )

                        Text("Stored only on this device · Never shared")
                            .font(.caption)
                            .foregroundStyle(ShepherdTheme.textTertiary)
                    }

                    if let existingNote {
                        Button(role: .destructive) {
                            modelContext.delete(existingNote)
                            try? modelContext.save()
                            dismiss()
                        } label: {
                            HStack {
                                Spacer()
                                Image(systemName: "trash")
                                Text("Delete Note")
                                Spacer()
                            }
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(ShepherdTheme.destructive)
                            .padding(.vertical, 12)
                            .background(ShepherdTheme.surfaceSunken)
                            .clipShape(RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD))
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(20)
            }
            .background(ShepherdTheme.canvasBg.ignoresSafeArea())
            .navigationTitle(existingNote != nil ? "Edit Note" : "Add Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityIdentifier("NoteCancelButton")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveNote()
                    }
                    .accessibilityIdentifier("NoteSaveButton")
                    .disabled(noteContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func saveNote() {
        let trimmed = noteContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let existing = existingNote {
            existing.noteText = trimmed
            existing.updatedAt = .now
        } else {
            let newNote = BibleNote(
                book: bookAbbrev,
                chapter: chapter,
                startVerse: startVerse,
                endVerse: endVerse,
                noteText: trimmed,
                verseText: verseText
            )
            modelContext.insert(newNote)
        }
        try? modelContext.save()
        dismiss()
    }
}
