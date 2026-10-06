import SwiftUI

public struct BibleReaderView: View {
    @EnvironmentObject private var content: ContentStore
    @State private var showPicker: Bool = false
    @AppStorage("bible.book") private var selectedBookAbbrev: String = "GEN"
    @AppStorage("bible.chapter") private var selectedChapterNum: Int = 1

    public init() {}

    private var books: [BibleBook] { content.bible?.books ?? [] }

    private var currentBookIndex: Int? {
        books.firstIndex { $0.abbrev == selectedBookAbbrev } ?? (books.isEmpty ? nil : 0)
    }

    private var currentBook: BibleBook? {
        currentBookIndex.map { books[$0] }
    }

    private var currentChapter: BibleChapter? {
        currentBook?.chapters.first { $0.number == selectedChapterNum }
            ?? currentBook?.chapters.first
    }

    public var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Eyebrow
                        Text("WEB · \(currentBook?.name.uppercased() ?? "GENESIS")")
                            .font(ShepherdTheme.scriptureEyebrow())
                            .foregroundStyle(ShepherdTheme.accent)
                            .padding(.top, 8)
                            .id("top")

                        if let book = currentBook, let chapter = currentChapter {
                            chapterBody(book: book, chapter: chapter)
                        } else {
                            HStack {
                                Spacer()
                                ProgressView("Opening the Bible…")
                                    .padding(.top, 80)
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .onChange(of: selectedChapterNum) { _, _ in proxy.scrollTo("top", anchor: .top) }
                .onChange(of: selectedBookAbbrev) { _, _ in proxy.scrollTo("top", anchor: .top) }
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

    @ViewBuilder
    private func chapterBody(book: BibleBook, chapter: BibleChapter) -> some View {
        Text("Chapter \(chapter.number)")
            .font(ShepherdTheme.title2Serif())
            .foregroundStyle(ShepherdTheme.textPrimary)

        if let heading = chapter.heading {
            Text(heading)
                .font(.subheadline.italic())
                .foregroundStyle(ShepherdTheme.textSecondary)
        }

        LazyVStack(alignment: .leading, spacing: 18) {
            ForEach(chapter.verses) { verse in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(verse.number)")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(ShepherdTheme.accent)
                        .frame(minWidth: 24, alignment: .trailing)

                    Text(verse.text)
                        .font(ShepherdTheme.scriptureBody())
                        .foregroundStyle(ShepherdTheme.textPrimary)
                        .lineSpacing(7)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .accessibilityElement(children: .combine)
            }
        }

        chapterNavigation(book: book, chapter: chapter)
            .padding(.top, 24)

        // Quiet Footer
        Text("\(book.name) \(chapter.number) · World English Bible (public domain)")
            .font(.footnote)
            .foregroundStyle(ShepherdTheme.textTertiary)
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            .padding(.bottom, 60)
    }

    private func chapterNavigation(book: BibleBook, chapter: BibleChapter) -> some View {
        let previous = BibleNavigation.previous(book: book.abbrev, chapter: chapter.number, in: books)
        let next = BibleNavigation.next(book: book.abbrev, chapter: chapter.number, in: books)
        return HStack(spacing: 12) {
            if let previous {
                SecondaryGlassButton(previous.label, icon: "chevron.left") {
                    select(previous)
                }
                .accessibilityLabel("Previous chapter, \(previous.label)")
            }
            if let next {
                SecondaryGlassButton(next.label, icon: "chevron.right") {
                    select(next)
                }
                .accessibilityLabel("Next chapter, \(next.label)")
            }
        }
    }

    private func select(_ location: BibleNavigation.Location) {
        selectedBookAbbrev = location.book
        selectedChapterNum = location.chapter
    }
}

/// Previous / next chapter across book boundaries.
public enum BibleNavigation {
    public struct Location: Equatable {
        public let book: String
        public let chapter: Int
        public let label: String
    }

    public static func next(book: String, chapter: Int, in books: [BibleBook]) -> Location? {
        guard let bi = books.firstIndex(where: { $0.abbrev == book }) else { return nil }
        let b = books[bi]
        if let ci = b.chapters.firstIndex(where: { $0.number == chapter }), ci + 1 < b.chapters.count {
            return location(b, b.chapters[ci + 1].number)
        }
        guard bi + 1 < books.count, let first = books[bi + 1].chapters.first else { return nil }
        return location(books[bi + 1], first.number)
    }

    public static func previous(book: String, chapter: Int, in books: [BibleBook]) -> Location? {
        guard let bi = books.firstIndex(where: { $0.abbrev == book }) else { return nil }
        let b = books[bi]
        if let ci = b.chapters.firstIndex(where: { $0.number == chapter }), ci > 0 {
            return location(b, b.chapters[ci - 1].number)
        }
        guard bi > 0, let last = books[bi - 1].chapters.last else { return nil }
        return location(books[bi - 1], last.number)
    }

    private static func location(_ book: BibleBook, _ chapter: Int) -> Location {
        Location(book: book.abbrev, chapter: chapter, label: "\(book.name) \(chapter)")
    }
}

// MARK: - Book & Chapter Picker Sheet

struct BiblePickerSheet: View {
    @EnvironmentObject private var content: ContentStore
    @Binding var selectedBook: String
    @Binding var selectedChapter: Int
    @Environment(\.dismiss) private var dismiss
    @State private var testament: String = "OT"
    @State private var query: String = ""

    private var books: [BibleBook] {
        let all = content.bible?.books ?? []
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            return all.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
        }
        return all.filter { $0.testament == testament }
    }

    var body: some View {
        NavigationStack {
            List {
                if query.isEmpty {
                    Picker("Testament", selection: $testament) {
                        Text("Old Testament").tag("OT")
                        Text("New Testament").tag("NT")
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                }

                Section {
                    ForEach(books) { book in
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
                                Text(book.chapters.count == 1 ? "1 chapter" : "\(book.chapters.count) chapters")
                                    .font(.subheadline)
                                    .foregroundStyle(ShepherdTheme.textTertiary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } footer: {
                    Text("World English Bible, 66 books (public domain)")
                }
            }
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Find a book")
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
                    .accessibilityLabel("Close")
                }
            }
            .onAppear {
                testament = content.bible?.books.first { $0.abbrev == selectedBook }?.testament ?? "OT"
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct ChapterSelectionList: View {
    let book: BibleBook
    @Binding var selectedChapter: Int
    var onSelected: () -> Void

    private let columns = [GridItem(.adaptive(minimum: 56), spacing: 10)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(book.chapters) { chapter in
                    Button {
                        selectedChapter = chapter.number
                        onSelected()
                    } label: {
                        Text("\(chapter.number)")
                            .font(.headline)
                            .foregroundStyle(ShepherdTheme.textPrimary)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .background(ShepherdTheme.cardSurface)
                            .clipShape(RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD))
                            .overlay(
                                RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD)
                                    .stroke(ShepherdTheme.surfaceBorder, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Chapter \(chapter.number)")
                }
            }
            .padding(20)
        }
        .background(ShepherdTheme.canvasBg.ignoresSafeArea())
        .navigationTitle(book.name)
    }
}
