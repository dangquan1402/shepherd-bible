import SwiftUI

public struct BibleReaderView: View {
    @EnvironmentObject private var content: ContentStore
    @State private var showPicker: Bool = false
    @State private var selectedBookAbbrev: String = "GEN"
    @State private var selectedChapterNum: Int = 1

    public init() {}

    private var currentBook: BibleBook? {
        content.bible?.books.first { $0.abbrev == selectedBookAbbrev }
            ?? content.bible?.books.first
    }

    private var currentChapter: BibleChapter? {
        currentBook?.chapters.first { $0.number == selectedChapterNum }
            ?? currentBook?.chapters.first
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Eyebrow
                    Text("WEB · \(currentBook?.name.uppercased() ?? "GENESIS")")
                        .font(ShepherdTheme.scriptureEyebrow())
                        .foregroundStyle(ShepherdTheme.accent)
                        .padding(.top, 8)

                    if let chapter = currentChapter {
                        VStack(alignment: .leading, spacing: 18) {
                            ForEach(Array(chapter.verses.enumerated()), id: \.element.id) { index, verse in
                                VStack(alignment: .leading, spacing: 18) {
                                    HStack(alignment: .top, spacing: 10) {
                                        Text("\(verse.number)")
                                            .font(.subheadline.weight(.bold))
                                            .foregroundStyle(ShepherdTheme.accent)
                                            .frame(width: 24, alignment: .trailing)

                                        Text(verse.text)
                                            .font(ShepherdTheme.scriptureBody())
                                            .foregroundStyle(ShepherdTheme.textPrimary)
                                            .lineSpacing(7)
                                    }

                                    // Generic gap marker between consecutive verses in sample
                                    if index < chapter.verses.count - 1 {
                                        let nextVerse = chapter.verses[index + 1]
                                        if nextVerse.number > verse.number + 1 {
                                            let gapText = (nextVerse.number == verse.number + 2)
                                                ? "Verse \(verse.number + 1) isn't in this sample"
                                                : "Verses \(verse.number + 1)–\(nextVerse.number - 1) aren't in this sample"
                                            HStack {
                                                Spacer()
                                                Text(gapText)
                                                    .font(.footnote)
                                                    .foregroundStyle(ShepherdTheme.textTertiary)
                                                    .padding(.vertical, 10)
                                                    .padding(.horizontal, 16)
                                                    .background(ShepherdTheme.surfaceSunken)
                                                    .clipShape(Capsule())
                                                Spacer()
                                            }
                                            .padding(.vertical, 8)
                                        }
                                    }
                                }
                            }
                        }

                        // Quiet Footer
                        HStack {
                            Spacer()
                            Text("\(currentBook?.name ?? "Genesis") \(chapter.number) · \(chapter.verses.count) verses in sample")
                                .font(.footnote)
                                .foregroundStyle(ShepherdTheme.textTertiary)
                                .padding(.top, 32)
                                .padding(.bottom, 60)
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .background(ShepherdTheme.canvasBg.ignoresSafeArea())
            .scrollEdgeEffectStyle(.soft, for: .top)
            .navigationTitle(currentBook?.name ?? "Genesis")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showPicker = true
                    } label: {
                        Image(systemName: "book")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .accessibilityLabel("Select Book and Chapter")
                }
            }
            .sheet(isPresented: $showPicker) {
                BiblePickerSheet(
                    selectedBook: $selectedBookAbbrev,
                    selectedChapter: $selectedChapterNum
                )
            }
        }
    }
}

// MARK: - Book & Chapter Picker Sheet

struct BiblePickerSheet: View {
    @EnvironmentObject private var content: ContentStore
    @Binding var selectedBook: String
    @Binding var selectedChapter: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Sample Books") {
                    ForEach(content.bible?.books ?? []) { book in
                        NavigationLink {
                            ChapterSelectionList(book: book, selectedChapter: $selectedChapter, onSelected: {
                                selectedBook = book.abbrev
                                dismiss()
                            })
                        } label: {
                            HStack {
                                Text(book.name)
                                    .font(.headline)
                                    .foregroundStyle(ShepherdTheme.textPrimary)
                                Spacer()
                                Text(book.testament == "OT" ? "Old Testament" : "New Testament")
                                    .font(.subheadline)
                                    .foregroundStyle(ShepherdTheme.textTertiary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Select Scripture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(ShepherdTheme.textSecondary)
                            .frame(width: 32, height: 32)
                            .background(ShepherdTheme.surfaceSunken)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct ChapterSelectionList: View {
    let book: BibleBook
    @Binding var selectedChapter: Int
    var onSelected: () -> Void

    var body: some View {
        List(book.chapters) { chapter in
            Button {
                selectedChapter = chapter.number
                onSelected()
            } label: {
                HStack {
                    Text("Chapter \(chapter.number)")
                        .font(.headline)
                        .foregroundStyle(ShepherdTheme.textPrimary)
                    Spacer()
                    Text("\(chapter.verses.count) verses")
                        .font(.subheadline)
                        .foregroundStyle(ShepherdTheme.textTertiary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle(book.name)
    }
}
