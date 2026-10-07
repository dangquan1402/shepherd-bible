import SwiftUI
import SwiftData

public struct SavedScriptureView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var content: ContentStore

    @Query(sort: \BibleHighlight.createdAt, order: .reverse) private var highlights: [BibleHighlight]
    @Query(sort: \BibleBookmark.createdAt, order: .reverse) private var bookmarks: [BibleBookmark]
    @Query(sort: \BibleNote.updatedAt, order: .reverse) private var notes: [BibleNote]

    public var onSelectVerse: (String, Int, Int) -> Void

    @State private var selectedFilter: SavedFilter = .all

    public enum SavedFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case highlights = "Highlights"
        case bookmarks = "Bookmarks"
        case notes = "Notes"

        public var id: String { rawValue }
    }

    public init(onSelectVerse: @escaping (String, Int, Int) -> Void) {
        self.onSelectVerse = onSelectVerse
    }

    private var items: [SavedItem] {
        switch selectedFilter {
        case .all:
            let h = highlights.map(SavedItem.highlight)
            let b = bookmarks.map(SavedItem.bookmark)
            let n = notes.map(SavedItem.note)
            return (h + b + n).sorted { $0.date > $1.date }
        case .highlights:
            return highlights.map(SavedItem.highlight)
        case .bookmarks:
            return bookmarks.map(SavedItem.bookmark)
        case .notes:
            return notes.map(SavedItem.note)
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Filter segmented control
            Picker("Filter", selection: $selectedFilter) {
                ForEach(SavedFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(ShepherdTheme.canvasBg)

            if items.isEmpty {
                emptyStateView
            } else {
                List {
                    ForEach(items) { item in
                        SavedItemRow(item: item, bookName: bookName(for: item.book)) {
                            onSelectVerse(item.book, item.chapter, item.startVerse)
                            dismiss()
                        }
                        .listRowBackground(ShepherdTheme.cardSurface)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                delete(item)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .background(ShepherdTheme.canvasBg.ignoresSafeArea())
        .navigationTitle("Saved")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func bookName(for abbrev: String) -> String {
        content.bible?.books.first { $0.abbrev == abbrev }?.name ?? abbrev
    }

    private func delete(_ item: SavedItem) {
        switch item {
        case .highlight(let h):
            modelContext.delete(h)
        case .bookmark(let b):
            modelContext.delete(b)
        case .note(let n):
            modelContext.delete(n)
        }
        try? modelContext.save()
    }

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: emptyIcon)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(ShepherdTheme.textTertiary)

            Text(emptyTitle)
                .font(ShepherdTheme.title3Serif())
                .foregroundStyle(ShepherdTheme.textPrimary)

            Text(emptyDescription)
                .font(.subheadline)
                .foregroundStyle(ShepherdTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
    }

    private var emptyIcon: String {
        switch selectedFilter {
        case .all: return "bookmark.slash"
        case .highlights: return "highlighter"
        case .bookmarks: return "bookmark"
        case .notes: return "note.text"
        }
    }

    private var emptyTitle: String {
        switch selectedFilter {
        case .all: return "No Saved Items"
        case .highlights: return "No Highlights"
        case .bookmarks: return "No Bookmarks"
        case .notes: return "No Notes"
        }
    }

    private var emptyDescription: String {
        switch selectedFilter {
        case .all:
            return "Tap any verse while reading to highlight, bookmark, or add private reflections."
        case .highlights:
            return "Highlight meaningful verses in yellow, blue, purple, rose, or amber."
        case .bookmarks:
            return "Bookmark verses to quickly return to your favorite passages."
        case .notes:
            return "Write private study notes and reflections that stay on your device."
        }
    }
}

// MARK: - Saved Item Unified Model

enum SavedItem: Identifiable {
    case highlight(BibleHighlight)
    case bookmark(BibleBookmark)
    case note(BibleNote)

    var id: String {
        switch self {
        case .highlight(let h): return "h-\(h.id)"
        case .bookmark(let b): return "b-\(b.id)"
        case .note(let n): return "n-\(n.id)"
        }
    }

    var date: Date {
        switch self {
        case .highlight(let h): return h.createdAt
        case .bookmark(let b): return b.createdAt
        case .note(let n): return n.updatedAt
        }
    }

    var book: String {
        switch self {
        case .highlight(let h): return h.book
        case .bookmark(let b): return b.book
        case .note(let n): return n.book
        }
    }

    var chapter: Int {
        switch self {
        case .highlight(let h): return h.chapter
        case .bookmark(let b): return b.chapter
        case .note(let n): return n.chapter
        }
    }

    var startVerse: Int {
        switch self {
        case .highlight(let h): return h.startVerse
        case .bookmark(let b): return b.startVerse
        case .note(let n): return n.startVerse
        }
    }

    var endVerse: Int {
        switch self {
        case .highlight(let h): return h.endVerse
        case .bookmark(let b): return b.endVerse
        case .note(let n): return n.endVerse
        }
    }

    var verseText: String {
        switch self {
        case .highlight(let h): return h.verseText
        case .bookmark(let b): return b.verseText
        case .note(let n): return n.verseText
        }
    }
}

// MARK: - Saved Item Row View

private struct SavedItemRow: View {
    let item: SavedItem
    let bookName: String
    let onTap: () -> Void

    private var reference: String {
        BibleFormatter.referenceString(
            bookName: bookName,
            chapter: item.chapter,
            startVerse: item.startVerse,
            endVerse: item.endVerse
        )
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                // Top row: Type indicator + Reference + Date
                HStack(alignment: .center, spacing: 8) {
                    badgeView

                    Text(reference)
                        .font(.headline)
                        .foregroundStyle(ShepherdTheme.textPrimary)

                    Spacer()

                    Text(item.date, style: .date)
                        .font(.caption)
                        .foregroundStyle(ShepherdTheme.textTertiary)
                }

                // Middle: Note text if note
                if case .note(let n) = item {
                    Text(n.noteText)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(ShepherdTheme.textPrimary)
                        .lineLimit(3)
                        .padding(.vertical, 2)
                }

                // Scripture snippet
                if !item.verseText.isEmpty {
                    Text(item.verseText)
                        .font(ShepherdTheme.scriptureBody())
                        .foregroundStyle(ShepherdTheme.textSecondary)
                        .lineLimit(2)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(snippetBackground)
                        .clipShape(RoundedRectangle(cornerRadius: ShepherdTheme.radiusSM))
                }

                // Footer: Attribution
                HStack {
                    Spacer()
                    Text("World English Bible")
                        .font(.caption2)
                        .foregroundStyle(ShepherdTheme.textTertiary)
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
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(accessibilityTypeDescription), \(reference)")
        .accessibilityHint("Double tap to open in Bible reader")
    }

    @ViewBuilder
    private var badgeView: some View {
        switch item {
        case .highlight(let h):
            Circle()
                .fill(h.highlightColor.swatchColor)
                .frame(width: 14, height: 14)
        case .bookmark:
            Image(systemName: "bookmark.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(ShepherdTheme.accent)
        case .note:
            Image(systemName: "square.and.pencil")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color("Note"))
        }
    }

    private var snippetBackground: Color {
        if case .highlight(let h) = item {
            return h.highlightColor.color
        }
        return ShepherdTheme.surfaceSunken
    }

    private var accessibilityTypeDescription: String {
        switch item {
        case .highlight(let h): return "Highlight, \(h.highlightColor.displayName)"
        case .bookmark: return "Bookmark"
        case .note: return "Note"
        }
    }
}
