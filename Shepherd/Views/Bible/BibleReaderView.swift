import SwiftUI
import SwiftData

public struct BibleReaderView: View {
    @EnvironmentObject private var content: ContentStore
    @Environment(\.modelContext) private var modelContext

    @Query private var allHighlights: [BibleHighlight]
    @Query private var allBookmarks: [BibleBookmark]
    @Query private var allNotes: [BibleNote]

    @State private var showPickerSheet: Bool = false
    @State private var editingNoteConfig: NoteEditorConfig? = nil
    @State private var showSavedScreen: Bool = false
    @State private var selectedVerses: Set<Int> = []
    @State private var targetScrollVerse: Int? = nil
    @State private var flashedVerse: Int? = nil
    @State private var showCopiedToast: Bool = false

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

    // MARK: - Fast In-Memory Lookups for Current Chapter (O(1) per verse, 0 DB queries in loop)

    private var chapterHighlightsMap: [Int: BibleHighlight] {
        var map: [Int: BibleHighlight] = [:]
        let chapterHighlights = allHighlights.filter {
            $0.book == selectedBookAbbrev && $0.chapter == selectedChapterNum
        }
        for h in chapterHighlights {
            for v in h.startVerse...h.endVerse {
                map[v] = h
            }
        }
        return map
    }

    private var chapterBookmarksMap: [Int: BibleBookmark] {
        var map: [Int: BibleBookmark] = [:]
        let chapterBookmarks = allBookmarks.filter {
            $0.book == selectedBookAbbrev && $0.chapter == selectedChapterNum
        }
        for b in chapterBookmarks {
            for v in b.startVerse...b.endVerse {
                map[v] = b
            }
        }
        return map
    }

    private var chapterNotesMap: [Int: [BibleNote]] {
        var map: [Int: [BibleNote]] = [:]
        let chapterNotes = allNotes.filter {
            $0.book == selectedBookAbbrev && $0.chapter == selectedChapterNum
        }
        for n in chapterNotes {
            for v in n.startVerse...n.endVerse {
                map[v, default: []].append(n)
            }
        }
        return map
    }

    // MARK: - Selection Helpers

    private var sortedSelectedVerses: [Int] {
        selectedVerses.sorted()
    }

    private var selectionStartVerse: Int {
        sortedSelectedVerses.first ?? 1
    }

    private var selectionEndVerse: Int {
        sortedSelectedVerses.last ?? selectionStartVerse
    }

    private var selectionReferenceText: String {
        BibleFormatter.referenceString(
            bookName: currentBook?.name ?? selectedBookAbbrev,
            chapter: selectedChapterNum,
            startVerse: selectionStartVerse,
            endVerse: selectionEndVerse
        )
    }

    private var selectionFormattedText: String {
        guard let chapter = currentChapter else { return "" }
        let texts = sortedSelectedVerses.compactMap { v in
            chapter.verses.first { $0.number == v }?.text
        }
        return BibleFormatter.formattedText(
            bookName: currentBook?.name ?? selectedBookAbbrev,
            chapter: selectedChapterNum,
            startVerse: selectionStartVerse,
            endVerse: selectionEndVerse,
            verseTexts: texts
        )
    }

    private var selectionHasHighlight: Bool {
        let hMap = chapterHighlightsMap
        return selectedVerses.contains { hMap[$0] != nil }
    }

    private var selectionIsBookmarked: Bool {
        let bMap = chapterBookmarksMap
        return selectedVerses.contains { bMap[$0] != nil }
    }

    private var selectionExistingNote: BibleNote? {
        let nMap = chapterNotesMap
        for v in sortedSelectedVerses {
            if let note = nMap[v]?.first {
                return note
            }
        }
        return nil
    }

    // MARK: - Body

    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
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
                        .padding(.bottom, selectedVerses.isEmpty ? 60 : 180)
                    }
                    .onChange(of: selectedChapterNum) { _, _ in
                        selectedVerses.removeAll()
                        proxy.scrollTo("top", anchor: .top)
                    }
                    .onChange(of: selectedBookAbbrev) { _, _ in
                        selectedVerses.removeAll()
                        proxy.scrollTo("top", anchor: .top)
                    }
                    .onChange(of: targetScrollVerse) { _, newTarget in
                        if let target = newTarget {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.spring(duration: 0.4)) {
                                    proxy.scrollTo("verse-\(target)", anchor: .center)
                                }
                                flashVerse(target)
                            }
                        }
                    }
                }

                // Toast Pill
                if showCopiedToast {
                    VStack {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(ShepherdTheme.success)
                            Text("Copied to clipboard")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(ShepherdTheme.textPrimary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .shepherdGlassCard(cornerRadius: ShepherdTheme.radiusPill)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 12)
                        Spacer()
                    }
                    .allowsHitTesting(false)
                }

                // Floating Action Menu
                if !selectedVerses.isEmpty {
                    actionMenuView
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(ShepherdTheme.morphSpring, value: selectedVerses)
            .animation(ShepherdTheme.morphSpring, value: showCopiedToast)
            .background(ShepherdTheme.canvasBg.ignoresSafeArea())
            .scrollEdgeEffectStyle(.soft, for: .top)
            .navigationTitle(currentBook?.name ?? "Genesis")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSavedScreen = true
                    } label: {
                        Image(systemName: "bookmark")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .accessibilityLabel("Saved Scripture")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showPickerSheet = true
                    } label: {
                        Image(systemName: "book")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .accessibilityLabel("Select Book and Chapter")
                }
            }
            .navigationDestination(isPresented: $showSavedScreen) {
                SavedScriptureView { book, chapter, verse in
                    selectedBookAbbrev = book
                    selectedChapterNum = chapter
                    targetScrollVerse = verse
                }
            }
            .sheet(isPresented: $showPickerSheet) {
                BiblePickerSheet(
                    selectedBook: $selectedBookAbbrev,
                    selectedChapter: $selectedChapterNum
                )
            }
            .sheet(item: $editingNoteConfig, onDismiss: {
                withAnimation(ShepherdTheme.morphSpring) {
                    selectedVerses.removeAll()
                }
            }) { config in
                BibleNoteEditorSheet(
                    bookName: config.bookName,
                    bookAbbrev: config.bookAbbrev,
                    chapter: config.chapter,
                    startVerse: config.startVerse,
                    endVerse: config.endVerse,
                    verseText: config.verseText,
                    existingNote: config.existingNote
                )
            }
        }
    }

    // MARK: - Chapter Body

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

        let hMap = chapterHighlightsMap
        let bMap = chapterBookmarksMap
        let nMap = chapterNotesMap

        LazyVStack(alignment: .leading, spacing: 14) {
            ForEach(chapter.verses) { verse in
                let isSelected = selectedVerses.contains(verse.number)
                let highlight = hMap[verse.number]
                let isBookmarked = bMap[verse.number] != nil
                let hasNote = !(nMap[verse.number]?.isEmpty ?? true)
                let isFlashed = (flashedVerse == verse.number)

                VerseRowView(
                    verse: verse,
                    highlightColor: highlight?.highlightColor.color,
                    isBookmarked: isBookmarked,
                    hasNote: hasNote,
                    isSelected: isSelected,
                    isFlashed: isFlashed,
                    onTap: {
                        toggleVerseSelection(verse.number)
                    }
                )
                .id("verse-\(verse.number)")
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

    // MARK: - Action Menu View

    private var actionMenuView: some View {
        VStack(spacing: 14) {
            // Header Row: Reference + Close Button
            HStack {
                Text(selectionReferenceText)
                    .font(.headline)
                    .foregroundStyle(ShepherdTheme.textPrimary)

                Spacer()

                Button {
                    withAnimation(ShepherdTheme.morphSpring) {
                        selectedVerses.removeAll()
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(ShepherdTheme.textSecondary)
                }
                .accessibilityLabel("Dismiss selection")
            }

            // Highlight Colors Row
            HStack(spacing: 16) {
                ForEach(BibleHighlightColor.allCases) { hColor in
                    Button {
                        applyHighlight(hColor)
                    } label: {
                        Circle()
                            .fill(hColor.color)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Circle()
                                    .stroke(ShepherdTheme.surfaceBorder, lineWidth: 1)
                            )
                            .overlay(
                                Circle()
                                    .fill(hColor.swatchColor)
                                    .frame(width: 12, height: 12)
                            )
                    }
                    .accessibilityLabel("Highlight in \(hColor.displayName)")
                }

                if selectionHasHighlight {
                    Button {
                        removeHighlight()
                    } label: {
                        Image(systemName: "slash.circle")
                            .font(.system(size: 24))
                            .foregroundStyle(ShepherdTheme.textTertiary)
                            .frame(width: 32, height: 32)
                    }
                    .accessibilityLabel("Remove highlight")
                }
            }
            .padding(.vertical, 2)

            Divider()
                .background(ShepherdTheme.surfaceBorder)

            // Actions Row: Bookmark, Note, Copy, Share
            HStack(spacing: 18) {
                // Bookmark Action
                Button {
                    toggleBookmark()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: selectionIsBookmarked ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(selectionIsBookmarked ? ShepherdTheme.accent : ShepherdTheme.textPrimary)
                        Text(selectionIsBookmarked ? "Bookmarked" : "Bookmark")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(ShepherdTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("BookmarkActionButton")
                .accessibilityLabel(selectionIsBookmarked ? "Remove Bookmark" : "Add Bookmark")

                // Note Action
                Button {
                    openNoteEditor()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: selectionExistingNote != nil ? "note.text.badge.plus" : "square.and.pencil")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(selectionExistingNote != nil ? Color("Note") : ShepherdTheme.textPrimary)
                        Text(selectionExistingNote != nil ? "Edit Note" : "Note")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(ShepherdTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("NoteActionButton")
                .accessibilityLabel(selectionExistingNote != nil ? "Edit Note" : "Add Note")

                // Copy Action
                Button {
                    copySelection()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(ShepherdTheme.textPrimary)
                        Text("Copy")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(ShepherdTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("CopyActionButton")
                .accessibilityLabel("Copy Scripture with attribution")

                // Share Action
                ShareLink(item: selectionFormattedText) {
                    VStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(ShepherdTheme.textPrimary)
                        Text("Share")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(ShepherdTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("ShareActionButton")
                .accessibilityLabel("Share Scripture with attribution")
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .shepherdGlassCard(cornerRadius: ShepherdTheme.radiusXL)
        .padding(.horizontal, 16)
        .padding(.bottom, 68)
    }

    // MARK: - Actions Logic

    private func toggleVerseSelection(_ number: Int) {
        withAnimation(ShepherdTheme.morphSpring) {
            if selectedVerses.contains(number) {
                selectedVerses.remove(number)
            } else {
                selectedVerses.insert(number)
            }
        }
    }

    private func applyHighlight(_ color: BibleHighlightColor) {
        guard let chapter = currentChapter, !selectedVerses.isEmpty else { return }
        let start = selectionStartVerse
        let end = selectionEndVerse

        // Remove overlapping existing highlights
        let existing = allHighlights.filter {
            $0.book == selectedBookAbbrev && $0.chapter == selectedChapterNum && $0.overlaps(start: start, end: end)
        }
        for old in existing {
            modelContext.delete(old)
        }

        let texts = (start...end).compactMap { v in
            chapter.verses.first { $0.number == v }?.text
        }
        let highlight = BibleHighlight(
            book: selectedBookAbbrev,
            chapter: selectedChapterNum,
            startVerse: start,
            endVerse: end,
            colorName: color.rawValue,
            verseText: texts.joined(separator: " ")
        )
        modelContext.insert(highlight)
        try? modelContext.save()

        withAnimation(ShepherdTheme.morphSpring) {
            selectedVerses.removeAll()
        }
    }

    private func removeHighlight() {
        let start = selectionStartVerse
        let end = selectionEndVerse
        let existing = allHighlights.filter {
            $0.book == selectedBookAbbrev && $0.chapter == selectedChapterNum && $0.overlaps(start: start, end: end)
        }
        for old in existing {
            modelContext.delete(old)
        }
        try? modelContext.save()

        withAnimation(ShepherdTheme.morphSpring) {
            selectedVerses.removeAll()
        }
    }

    private func toggleBookmark() {
        guard let chapter = currentChapter, !selectedVerses.isEmpty else { return }
        let start = selectionStartVerse
        let end = selectionEndVerse

        let existing = allBookmarks.filter {
            $0.book == selectedBookAbbrev && $0.chapter == selectedChapterNum && $0.overlaps(start: start, end: end)
        }

        if !existing.isEmpty {
            for old in existing {
                modelContext.delete(old)
            }
        } else {
            let texts = (start...end).compactMap { v in
                chapter.verses.first { $0.number == v }?.text
            }
            let bookmark = BibleBookmark(
                book: selectedBookAbbrev,
                chapter: selectedChapterNum,
                startVerse: start,
                endVerse: end,
                verseText: texts.joined(separator: " ")
            )
            modelContext.insert(bookmark)
        }
        try? modelContext.save()

        withAnimation(ShepherdTheme.morphSpring) {
            selectedVerses.removeAll()
        }
    }

    private func openNoteEditor() {
        guard let chapter = currentChapter, !selectedVerses.isEmpty else { return }
        let start = selectionStartVerse
        let end = selectionEndVerse
        let texts = (start...end).compactMap { v in
            chapter.verses.first { $0.number == v }?.text
        }
        let config = NoteEditorConfig(
            bookName: currentBook?.name ?? selectedBookAbbrev,
            bookAbbrev: selectedBookAbbrev,
            chapter: selectedChapterNum,
            startVerse: start,
            endVerse: end,
            verseText: texts.joined(separator: " "),
            existingNote: selectionExistingNote
        )
        editingNoteConfig = config
    }

    private func copySelection() {
        UIPasteboard.general.string = selectionFormattedText
        showCopiedToast = true
        withAnimation(ShepherdTheme.morphSpring) {
            selectedVerses.removeAll()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(ShepherdTheme.morphSpring) {
                showCopiedToast = false
            }
        }
    }

    private func flashVerse(_ number: Int) {
        flashedVerse = number
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.5)) {
                if flashedVerse == number {
                    flashedVerse = nil
                }
            }
        }
    }
}

// MARK: - Note Editor Configuration

private struct NoteEditorConfig: Identifiable {
    var id: String { "\(bookAbbrev).\(chapter).\(startVerse)-\(endVerse)" }
    let bookName: String
    let bookAbbrev: String
    let chapter: Int
    let startVerse: Int
    let endVerse: Int
    let verseText: String
    let existingNote: BibleNote?
}

// MARK: - Verse Row View

private struct VerseRowView: View {
    let verse: BibleVerse
    let highlightColor: Color?
    let isBookmarked: Bool
    let hasNote: Bool
    let isSelected: Bool
    let isFlashed: Bool
    let onTap: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Verse number + badges
            VStack(alignment: .trailing, spacing: 3) {
                Text("\(verse.number)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(isSelected ? ShepherdTheme.accent : ShepherdTheme.accent.opacity(0.85))

                if isBookmarked {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(ShepherdTheme.accent)
                }

                if hasNote {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color("Note"))
                }
            }
            .frame(minWidth: 28, alignment: .trailing)
            .padding(.top, 2)

            Text(verse.text)
                .font(ShepherdTheme.scriptureBody())
                .foregroundStyle(ShepherdTheme.textPrimary)
                .lineSpacing(7)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: ShepherdTheme.radiusSM)
                .fill(rowBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ShepherdTheme.radiusSM)
                .fill(isSelected ? ShepherdTheme.tabSelection : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ShepherdTheme.radiusSM)
                .stroke(rowBorder, lineWidth: isSelected || isFlashed ? 1.5 : 0)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5).onEnded { _ in
                onTap()
            }
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Verse \(verse.number), \(verse.text)\(isBookmarked ? ", Bookmarked" : "")\(hasNote ? ", Has note" : "")\(highlightColor != nil ? ", Highlighted" : "")")
        .accessibilityHint("Double tap to select this verse")
    }

    private var rowBackground: Color {
        if let highlightColor {
            return highlightColor
        }
        if isFlashed {
            return ShepherdTheme.goldSubtle
        }
        return Color.clear
    }

    private var rowBorder: Color {
        if isSelected {
            return ShepherdTheme.accent
        }
        if isFlashed {
            return ShepherdTheme.gold
        }
        return Color.clear
    }
}

// MARK: - Navigation Helpers

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
