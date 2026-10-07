import SwiftUI
import SwiftData

public struct BibleReaderView: View {
    @EnvironmentObject private var content: ContentStore
    @Environment(\.modelContext) private var modelContext
    /// A one-shot request to open at a verse (the verse of the day). The reader consumes it:
    /// copies it into `verseOfTheDay`, scrolls once, and sets it back to nil, so the user's
    /// own navigation afterwards is never overridden.
    @Binding public var targetVerse: DailyVerse?
    @State private var verseOfTheDay: DailyVerse?
    @State private var scrollRequest: ScrollRequest?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @Query private var allHighlights: [BibleHighlight]
    @Query private var allBookmarks: [BibleBookmark]
    @Query private var allNotes: [BibleNote]

    @State private var showPickerSheet: Bool = false
    @State private var editingNoteConfig: NoteEditorConfig? = nil
    @State private var showSavedScreen: Bool = false
    @State private var selection = VerseSelection()
    @State private var targetScrollVerse: Int? = nil
    @State private var flashedVerse: Int? = nil
    @State private var showCopiedToast: Bool = false
    @State private var lastCopiedText: String = ""

    @AppStorage("bible.book") private var selectedBookAbbrev: String = "GEN"
    @AppStorage("bible.chapter") private var selectedChapterNum: Int = 1

    public init(targetVerse: Binding<DailyVerse?> = .constant(nil)) {
        self._targetVerse = targetVerse
    }

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

    private var bookName: String {
        currentBook?.name ?? selectedBookAbbrev
    }

    /// The bundled verses in `range` of the current chapter.
    private func chapterVerses(_ range: ClosedRange<Int>) -> [BibleVerse] {
        currentChapter?.verses.filter { range.contains($0.number) } ?? []
    }

    private func chapterText(_ range: ClosedRange<Int>) -> String {
        chapterVerses(range).map(\.text).joined(separator: " ")
    }

    private var selectionReferenceText: String {
        BibleFormatter.referenceString(bookName: bookName, chapter: selectedChapterNum, verses: selection.verses)
    }

    private var selectionFormattedText: String {
        guard let range = selection.range else { return "" }
        return BibleFormatter.formattedText(bookName: bookName, chapter: selectedChapterNum, verses: chapterVerses(range))
    }

    private var selectionHasHighlight: Bool {
        let hMap = chapterHighlightsMap
        return selection.verses.contains { hMap[$0] != nil }
    }

    private var selectionIsBookmarked: Bool {
        let bMap = chapterBookmarksMap
        return selection.verses.contains { bMap[$0] != nil }
    }

    private var selectionExistingNote: BibleNote? {
        let nMap = chapterNotesMap
        return selection.verses.lazy.compactMap { nMap[$0]?.first }.first
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
                                .foregroundStyle(ShepherdTheme.brand)
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
                        .padding(.bottom, selection.isEmpty ? 60 : (dynamicTypeSize.isAccessibilitySize ? 520 : 180))
                    }
                    .onChange(of: selectedChapterNum) { _, _ in chapterChanged(proxy) }
                    .onChange(of: selectedBookAbbrev) { _, _ in chapterChanged(proxy) }
                    .onChange(of: targetVerse) { _, _ in consumeTarget() }
                    .onAppear { consumeTarget() }
                    .task(id: scrollRequest) {
                        guard let request = scrollRequest else { return }
                        // The Bible decodes off the main thread; on a cold start wait for it, then let
                        // the chapter lay out before scrolling to the verse.
                        await content.ensureBibleLoaded()
                        try? await Task.sleep(for: .milliseconds(150))
                        guard !Task.isCancelled else { return }
                        withAnimation(.spring(duration: 0.45, bounce: 0.15)) {
                            proxy.scrollTo("verse-\(request.verse)", anchor: .center)
                        }
                        scrollRequest = nil
                    }
                    .onChange(of: selection) { old, new in
                        // At accessibility sizes the action menu fills the lower half of the
                        // screen, so lift a newly selected verse above it.
                        if dynamicTypeSize.isAccessibilitySize, old.isEmpty, let first = new.range?.lowerBound {
                            withAnimation(ShepherdTheme.morphSpring) {
                                proxy.scrollTo("verse-\(first)", anchor: .top)
                            }
                        }
                    }
                    .onChange(of: targetScrollVerse) { _, newTarget in
                        if let target = newTarget {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.spring(duration: 0.4)) {
                                    proxy.scrollTo("verse-\(target)", anchor: .center)
                                }
                                flashVerse(target)
                                // Reset, so opening the same Saved item again scrolls again.
                                targetScrollVerse = nil
                            }
                        }
                    }
                }

                // Toast Pill
                if showCopiedToast {
                    VStack {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(ShepherdTheme.brand)
                            Text("Copied to clipboard")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(ShepherdTheme.textPrimary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .shepherdGlassCard(cornerRadius: ShepherdTheme.radiusPill)
                        .accessibilityElement(children: .combine)
                        .accessibilityIdentifier("CopiedToast")
                        .modifier(CopiedTextEcho(text: lastCopiedText))
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 12)
                        Spacer()
                    }
                    .allowsHitTesting(false)
                }

                // Floating Action Menu
                if !selection.isEmpty {
                    actionMenuView
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(ShepherdTheme.morphSpring, value: selection)
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
                    selection.clear()
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
                let isSelected = selection.contains(verse.number)
                let highlight = hMap[verse.number]
                let isBookmarked = bMap[verse.number] != nil
                let hasNote = !(nMap[verse.number]?.isEmpty ?? true)
                let isFlashed = (flashedVerse == verse.number)
                let isVerseOfTheDay = verseOfTheDay.map {
                    $0.bookAbbrev == book.abbrev && $0.chapter == chapter.number && $0.verse == verse.number
                } ?? false

                VerseRowView(
                    verse: verse,
                    highlight: highlight?.highlightColor,
                    isBookmarked: isBookmarked,
                    hasNote: hasNote,
                    isSelected: isSelected,
                    isFlashed: isFlashed,
                    isVerseOfTheDay: isVerseOfTheDay,
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

    private struct ScrollRequest: Equatable {
        let id = UUID()
        let verse: Int
    }

    /// Turns a pending `targetVerse` into a highlight plus one scroll, then clears it.
    private func consumeTarget() {
        guard let target = targetVerse else { return }
        targetVerse = nil
        verseOfTheDay = target
        selectedBookAbbrev = target.bookAbbrev
        selectedChapterNum = target.chapter
        scrollRequest = ScrollRequest(verse: target.verse)
    }

    /// A new chapter starts at the top with nothing selected (a pending verse scroll runs after
    /// this), and the verse-of-the-day highlight only lives in its own chapter.
    private func chapterChanged(_ proxy: ScrollViewProxy) {
        selection.clear()
        proxy.scrollTo("top", anchor: .top)
        if let votd = verseOfTheDay, votd.bookAbbrev != selectedBookAbbrev || votd.chapter != selectedChapterNum {
            verseOfTheDay = nil
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
                    .accessibilityIdentifier("SelectionReference")

                Spacer()

                Button {
                    withAnimation(ShepherdTheme.morphSpring) {
                        selection.clear()
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

            // Bookmark, Note, Copy, Share: one row while every label fits on one line,
            // otherwise (large and accessibility text sizes) one action per line.
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 18) {
                    actionButtons(stacked: false)
                }
                VStack(spacing: 4) {
                    actionButtons(stacked: true)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .shepherdGlassCard(cornerRadius: ShepherdTheme.radiusXL)
        .padding(.horizontal, 16)
        .padding(.bottom, 68)
    }

    @ViewBuilder
    private func actionButtons(stacked: Bool) -> some View {
        let bookmarked = selectionIsBookmarked
        let hasNote = selectionExistingNote != nil

        Button {
            toggleBookmark()
        } label: {
            actionLabel(
                bookmarked ? "Bookmarked" : "Bookmark",
                icon: bookmarked ? "bookmark.fill" : "bookmark",
                tint: bookmarked ? ShepherdTheme.brand : ShepherdTheme.textPrimary,
                stacked: stacked
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("BookmarkActionButton")
        .accessibilityLabel(bookmarked ? "Remove Bookmark" : "Add Bookmark")

        Button {
            openNoteEditor()
        } label: {
            actionLabel(
                hasNote ? "Edit Note" : "Note",
                icon: hasNote ? "note.text.badge.plus" : "square.and.pencil",
                tint: hasNote ? ShepherdTheme.brand : ShepherdTheme.textPrimary,
                stacked: stacked
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("NoteActionButton")
        .accessibilityLabel(hasNote ? "Edit Note" : "Add Note")

        Button {
            copySelection()
        } label: {
            actionLabel("Copy", icon: "doc.on.doc", tint: ShepherdTheme.textPrimary, stacked: stacked)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("CopyActionButton")
        .accessibilityLabel("Copy Scripture with attribution")

        ShareLink(item: selectionFormattedText) {
            actionLabel("Share", icon: "square.and.arrow.up", tint: ShepherdTheme.textPrimary, stacked: stacked)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("ShareActionButton")
        .accessibilityLabel("Share Scripture with attribution")
    }

    /// Icon over label in the row layout, icon beside label in the stacked one. Labels never wrap:
    /// the row only fits when every label fits on one line.
    @ViewBuilder
    private func actionLabel(_ title: String, icon: String, tint: Color, stacked: Bool) -> some View {
        let image = Image(systemName: icon)
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(tint)
        let label = Text(title)
            .font(.caption2.weight(.medium))
            .foregroundStyle(ShepherdTheme.textSecondary)
            .lineLimit(1)
            .fixedSize()
        if stacked {
            HStack(spacing: 12) {
                image
                label
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(Rectangle())
        } else {
            VStack(spacing: 4) {
                image
                label
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(Rectangle())
        }
    }

    // MARK: - Actions Logic

    private func toggleVerseSelection(_ number: Int) {
        withAnimation(ShepherdTheme.morphSpring) {
            selection.tap(number)
        }
    }

    private var chapterHighlights: [BibleHighlight] {
        allHighlights.filter { $0.book == selectedBookAbbrev && $0.chapter == selectedChapterNum }
    }

    private var chapterBookmarks: [BibleBookmark] {
        allBookmarks.filter { $0.book == selectedBookAbbrev && $0.chapter == selectedChapterNum }
    }

    /// Replaces the chapter's highlights with `spans`, keeping each surviving piece's colour and date.
    /// Only highlights that overlap `range` are touched; the rest of each one is re-saved as its own record.
    private func rewriteHighlights(around range: ClosedRange<Int>, _ edit: ([VerseSpan<HighlightValue>]) -> [VerseSpan<HighlightValue>]) {
        let touched = chapterHighlights.filter { $0.overlaps(start: range.lowerBound, end: range.upperBound) }
        let spans = touched.map {
            VerseSpan($0.startVerse...$0.endVerse, HighlightValue(colorName: $0.colorName, createdAt: $0.createdAt))
        }
        touched.forEach(modelContext.delete)
        for span in edit(spans) {
            modelContext.insert(BibleHighlight(
                book: selectedBookAbbrev,
                chapter: selectedChapterNum,
                startVerse: span.range.lowerBound,
                endVerse: span.range.upperBound,
                colorName: span.value.colorName,
                createdAt: span.value.createdAt,
                verseText: chapterText(span.range)
            ))
        }
        try? modelContext.save()
    }

    private func applyHighlight(_ color: BibleHighlightColor) {
        guard let range = selection.range else { return }
        let new = VerseSpan(range, HighlightValue(colorName: color.rawValue, createdAt: .now))
        rewriteHighlights(around: range) { BibleRangeEditor.applying(new, to: $0) }
        clearSelection()
    }

    private func removeHighlight() {
        guard let range = selection.range else { return }
        rewriteHighlights(around: range) { BibleRangeEditor.removing(range, from: $0) }
        clearSelection()
    }

    /// Bookmarks the selection, or, when any selected verse is bookmarked, removes the bookmark from
    /// the selected verses only (bookmarked verses outside the selection stay bookmarked).
    private func toggleBookmark() {
        guard let range = selection.range else { return }
        let touched = chapterBookmarks.filter { $0.overlaps(start: range.lowerBound, end: range.upperBound) }
        if touched.isEmpty {
            modelContext.insert(BibleBookmark(
                book: selectedBookAbbrev,
                chapter: selectedChapterNum,
                startVerse: range.lowerBound,
                endVerse: range.upperBound,
                verseText: chapterText(range)
            ))
        } else {
            let spans = touched.map { VerseSpan($0.startVerse...$0.endVerse, $0.createdAt) }
            touched.forEach(modelContext.delete)
            for span in BibleRangeEditor.removing(range, from: spans) {
                modelContext.insert(BibleBookmark(
                    book: selectedBookAbbrev,
                    chapter: selectedChapterNum,
                    startVerse: span.range.lowerBound,
                    endVerse: span.range.upperBound,
                    createdAt: span.value,
                    verseText: chapterText(span.range)
                ))
            }
        }
        try? modelContext.save()
        clearSelection()
    }

    /// Edits the note on the selection if there is one (showing that note's own verses), else
    /// starts a note on the selected verses.
    private func openNoteEditor() {
        guard let range = selection.range else { return }
        let existing = selectionExistingNote
        editingNoteConfig = NoteEditorConfig(
            bookName: bookName,
            bookAbbrev: selectedBookAbbrev,
            chapter: selectedChapterNum,
            startVerse: existing?.startVerse ?? range.lowerBound,
            endVerse: existing?.endVerse ?? range.upperBound,
            verseText: existing.map { chapterText($0.startVerse...$0.endVerse) } ?? chapterText(range),
            existingNote: existing
        )
    }

    private func copySelection() {
        let text = selectionFormattedText
        UIPasteboard.general.string = text
        lastCopiedText = text
        showCopiedToast = true
        clearSelection()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(ShepherdTheme.morphSpring) {
                showCopiedToast = false
            }
        }
    }

    private func clearSelection() {
        withAnimation(ShepherdTheme.morphSpring) {
            selection.clear()
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

/// What a highlight span carries through a range edit.
private struct HighlightValue: Equatable {
    let colorName: String
    let createdAt: Date
}

/// DEBUG and `-uitestEchoCopy` only: exposes the copied text as the toast's accessibility value, so a
/// UI test can check what Copy put on the pasteboard without reading the pasteboard itself.
private struct CopiedTextEcho: ViewModifier {
    let text: String

    func body(content: Content) -> some View {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-uitestEchoCopy") {
            content.accessibilityValue(text)
        } else {
            content
        }
        #else
        content
        #endif
    }
}

// MARK: - Verse Row View

private struct VerseRowView: View {
    let verse: BibleVerse
    let highlight: BibleHighlightColor?
    let isBookmarked: Bool
    let hasNote: Bool
    let isSelected: Bool
    let isFlashed: Bool
    let isVerseOfTheDay: Bool
    let onTap: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Verse number + badges
            VStack(alignment: .trailing, spacing: 3) {
                Text("\(verse.number)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(isSelected ? ShepherdTheme.brand : ShepherdTheme.brand.opacity(0.85))

                if isBookmarked {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(ShepherdTheme.brand)
                }

                if hasNote {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(ShepherdTheme.brand)
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
        .accessibilityLabel("Verse \(verse.number), \(verse.text)\(isBookmarked ? ", Bookmarked" : "")\(hasNote ? ", Has note" : "")\(highlight.map { ", Highlighted \($0.displayName)" } ?? "")")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityHint(isSelected ? "Double tap to deselect" : "Double tap to select this verse")
        .accessibilityIdentifier("verse-\(verse.number)")
        .accessibilityValue(isVerseOfTheDay ? "Verse of the day" : "")
    }

    private var rowBackground: Color {
        if let highlight {
            return highlight.color
        }
        if isFlashed {
            return ShepherdTheme.joySubtle
        }
        if isVerseOfTheDay {
            return ShepherdTheme.brandSubtle
        }
        return Color.clear
    }

    private var rowBorder: Color {
        if isSelected {
            return ShepherdTheme.brand
        }
        if isFlashed {
            return ShepherdTheme.joy
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
