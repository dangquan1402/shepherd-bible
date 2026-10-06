import SwiftUI
import SwiftData

public enum PrayerFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case open = "Open"
    case answered = "Answered"

    public var id: String { rawValue }
}

public struct JournalView: View {
    @ObservedObject private var auth = JournalAuthService.shared
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]
    @Query(sort: \PrayerRequest.createdAt, order: .reverse) private var prayers: [PrayerRequest]

    @State private var selectedSegment: Int = 0
    @State private var prayerFilter: PrayerFilter = .all
    @State private var quickPrayerText: String = ""

    @State private var showNewEntrySheet: Bool = false
    @State private var showNewPrayerSheet: Bool = false
    @State private var showLockSettingsSheet: Bool = false
    @State private var selectedEntry: JournalEntry? = nil
    @State private var editingPrayer: PrayerRequest? = nil
    @State private var entryToDelete: JournalEntry? = nil
    @State private var showDeleteConfirmation: Bool = false

    public init() {}

    private var openPrayers: [PrayerRequest] {
        prayers.filter { !$0.isAnswered }
    }

    private var answeredPrayers: [PrayerRequest] {
        prayers.filter { $0.isAnswered }
    }

    private var filteredPrayers: [PrayerRequest] {
        switch prayerFilter {
        case .all:
            return prayers
        case .open:
            return openPrayers
        case .answered:
            return answeredPrayers
        }
    }

    public var body: some View {
        Group {
            if auth.isLockEnabled && !auth.isUnlocked {
                JournalLockedView {
                    Task {
                        _ = await auth.authenticate()
                    }
                }
            } else {
                journalContent
            }
        }
        .navigationTitle("Journal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    Button {
                        showLockSettingsSheet = true
                    } label: {
                        Image(systemName: auth.isLockEnabled ? "lock.fill" : "lock.open")
                            .font(.system(size: 16))
                            .foregroundStyle(auth.isLockEnabled ? ShepherdTheme.accentFill : ShepherdTheme.textSecondary)
                    }
                    .accessibilityLabel("Journal Privacy Settings")

                    Button {
                        if selectedSegment == 0 {
                            showNewEntrySheet = true
                        } else {
                            showNewPrayerSheet = true
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(ShepherdTheme.accentFill)
                    }
                    .accessibilityLabel(selectedSegment == 0 ? "New Reflection" : "New Prayer")
                }
            }
        }
        .task {
            if auth.isLockEnabled && !auth.isUnlocked {
                _ = await auth.authenticate()
            }
        }
        .sheet(isPresented: $showLockSettingsSheet) {
            JournalLockSettingsSheet()
        }
        .sheet(isPresented: $showNewEntrySheet) {
            NewJournalEntrySheet()
        }
        .sheet(isPresented: $showNewPrayerSheet) {
            NewPrayerSheet()
        }
        .sheet(item: $selectedEntry) { entry in
            JournalEntryDetailView(entry: entry)
        }
        .sheet(item: $editingPrayer) { prayer in
            EditPrayerSheet(prayer: prayer)
        }
    }

    private var journalContent: some View {
        VStack(spacing: 0) {
            // Segmented Picker
            Picker("Journal Section", selection: $selectedSegment) {
                Text("Reflections (\(entries.count))").tag(0)
                Text("Prayers (\(prayers.count))").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            if selectedSegment == 0 {
                reflectionsList
            } else {
                prayersList
            }
        }
        .background(ShepherdTheme.canvasBg.ignoresSafeArea())
    }

    // MARK: - Reflections View
    private var reflectionsList: some View {
        Group {
            if entries.isEmpty {
                emptyReflectionsView
            } else {
                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(entries) { entry in
                            reflectionCard(entry)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
                .scrollEdgeEffectStyle(.soft, for: .top)
            }
        }
    }

    private var emptyReflectionsView: some View {
        ScrollView {
            VStack(spacing: 18) {
                Spacer(minLength: 40)

                Image(systemName: "book.pages")
                    .font(.system(size: 56))
                    .foregroundStyle(ShepherdTheme.accentFill)

                VStack(spacing: 6) {
                    Text("No reflections yet")
                        .font(ShepherdTheme.title1Serif())
                        .foregroundStyle(ShepherdTheme.textPrimary)

                    Text("After completing a daily lesson, write a reflection to keep here. You can also write a reflection anytime.")
                        .font(.body)
                        .foregroundStyle(ShepherdTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                ProminentGlassButton("Write a Reflection", icon: "square.and.pencil") {
                    showNewEntrySheet = true
                }
                .padding(.horizontal, 32)
                .padding(.top, 8)

                Spacer(minLength: 40)
            }
        }
    }

    private func reflectionCard(_ entry: JournalEntry) -> some View {
        Button {
            selectedEntry = entry
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                // Header: Date & Lesson Tag
                HStack(alignment: .center) {
                    Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(ShepherdTheme.textSecondary)

                    Spacer()

                    if let lessonTitle = entry.lessonTitle, !lessonTitle.isEmpty {
                        Text(lessonTitle)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(ShepherdTheme.accentFill)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(ShepherdTheme.accentSubtle)
                            .clipShape(Capsule())
                    }
                }

                // Prompt if available
                if let prompt = entry.prompt, !prompt.isEmpty {
                    Text("Prompt: \(prompt)")
                        .font(.subheadline.italic())
                        .foregroundStyle(ShepherdTheme.textSecondary)
                        .lineLimit(2)
                }

                // Reflection Body
                Text(entry.text)
                    .font(.body)
                    .foregroundStyle(ShepherdTheme.textPrimary)
                    .lineLimit(4)
                    .multilineTextAlignment(.leading)

                if let updated = entry.updatedAt {
                    Text("Edited \(updated.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption2)
                        .foregroundStyle(ShepherdTheme.textTertiary)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ShepherdTheme.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD))
            .overlay(
                RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD)
                    .stroke(ShepherdTheme.surfaceBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                selectedEntry = entry
            } label: {
                Label("Edit Reflection", systemImage: "pencil")
            }

            Button(role: .destructive) {
                deleteEntry(entry)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func deleteEntry(_ entry: JournalEntry) {
        modelContext.delete(entry)
        try? modelContext.save()
    }

    // MARK: - Prayers View
    private var prayersList: some View {
        VStack(spacing: 12) {
            // Filter Selector
            HStack(spacing: 8) {
                ForEach(PrayerFilter.allCases) { filter in
                    let count = countForFilter(filter)
                    let isSelected = prayerFilter == filter

                    Button {
                        withAnimation {
                            prayerFilter = filter
                        }
                    } label: {
                        Text("\(filter.rawValue) (\(count))")
                            .font(.subheadline.weight(isSelected ? .bold : .medium))
                            .foregroundStyle(isSelected ? Color.white : ShepherdTheme.textPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(isSelected ? ShepherdTheme.accentFill : ShepherdTheme.cardSurface)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(isSelected ? Color.clear : ShepherdTheme.surfaceBorder, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)

            // Quick Add Input
            HStack(spacing: 10) {
                TextField("Add a prayer request…", text: $quickPrayerText)
                    .font(.body)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(ShepherdTheme.cardSurface)
                    .clipShape(RoundedRectangle(cornerRadius: ShepherdTheme.radiusSM))
                    .overlay(
                        RoundedRectangle(cornerRadius: ShepherdTheme.radiusSM)
                            .stroke(ShepherdTheme.surfaceBorder, lineWidth: 1)
                    )
                    .onSubmit {
                        addQuickPrayer()
                    }

                Button {
                    addQuickPrayer()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(quickPrayerText.trimmingCharacters(in: .whitespaces).isEmpty ? ShepherdTheme.textTertiary : ShepherdTheme.accentFill)
                }
                .disabled(quickPrayerText.trimmingCharacters(in: .whitespaces).isEmpty)
                .accessibilityLabel("Add Prayer")
            }
            .padding(.horizontal, 20)

            // Prayers list or empty
            if filteredPrayers.isEmpty {
                emptyPrayersView
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredPrayers) { prayer in
                            prayerCard(prayer)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 40)
                }
                .scrollEdgeEffectStyle(.soft, for: .top)
            }
        }
    }

    private func countForFilter(_ filter: PrayerFilter) -> Int {
        switch filter {
        case .all: return prayers.count
        case .open: return openPrayers.count
        case .answered: return answeredPrayers.count
        }
    }

    private func addQuickPrayer() {
        let trimmed = quickPrayerText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let newPrayer = PrayerRequest(text: trimmed)
        modelContext.insert(newPrayer)
        try? modelContext.save()
        quickPrayerText = ""
    }

    private var emptyPrayersView: some View {
        ScrollView {
            VStack(spacing: 14) {
                Spacer(minLength: 40)

                Image(systemName: prayerFilter == .answered ? "hands.sparkles" : "heart.text.square")
                    .font(.system(size: 48))
                    .foregroundStyle(ShepherdTheme.accentFill)

                Text(prayerFilter == .answered ? "No answered prayers yet" : (prayerFilter == .open ? "No open prayer requests" : "No prayers yet"))
                    .font(ShepherdTheme.title1Serif())
                    .foregroundStyle(ShepherdTheme.textPrimary)

                Text(prayerFilter == .answered ? "When God answers a prayer, tap the checkmark to mark it answered with the date." : "Add a prayer above to begin your prayer list.")
                    .font(.body)
                    .foregroundStyle(ShepherdTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Spacer(minLength: 40)
            }
        }
    }

    private func prayerCard(_ prayer: PrayerRequest) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Button {
                toggleAnswered(prayer)
            } label: {
                Image(systemName: prayer.isAnswered ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundStyle(prayer.isAnswered ? ShepherdTheme.accentFill : ShepherdTheme.textTertiary)
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
            .accessibilityLabel(prayer.isAnswered ? "Mark unanswered" : "Mark as answered")

            VStack(alignment: .leading, spacing: 6) {
                Text(prayer.text)
                    .font(.body)
                    .foregroundStyle(ShepherdTheme.textPrimary)
                    .strikethrough(prayer.isAnswered, color: ShepherdTheme.textTertiary)

                if let notes = prayer.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.subheadline)
                        .foregroundStyle(ShepherdTheme.textSecondary)
                }

                HStack(spacing: 6) {
                    Text("Added \(prayer.createdAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(ShepherdTheme.textTertiary)

                    if prayer.isAnswered, let answered = prayer.answeredDate {
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(ShepherdTheme.textTertiary)

                        HStack(spacing: 3) {
                            Image(systemName: "sparkles")
                                .font(.caption2)
                            Text("Answered \(answered.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption.weight(.medium))
                        }
                        .foregroundStyle(ShepherdTheme.accentFill)
                    }
                }
            }

            Spacer()

            Button {
                editingPrayer = prayer
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16))
                    .foregroundStyle(ShepherdTheme.textTertiary)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ShepherdTheme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD))
        .overlay(
            RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD)
                .stroke(ShepherdTheme.surfaceBorder, lineWidth: 1)
        )
        .contextMenu {
            Button {
                toggleAnswered(prayer)
            } label: {
                Label(prayer.isAnswered ? "Mark Unanswered" : "Mark Answered", systemImage: prayer.isAnswered ? "arrow.uturn.backward" : "checkmark")
            }

            Button {
                editingPrayer = prayer
            } label: {
                Label("Edit Prayer", systemImage: "pencil")
            }

            Button(role: .destructive) {
                modelContext.delete(prayer)
                try? modelContext.save()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func toggleAnswered(_ prayer: PrayerRequest) {
        withAnimation {
            if prayer.isAnswered {
                prayer.markUnanswered()
            } else {
                prayer.markAnswered()
            }
            try? modelContext.save()
        }
    }
}

// MARK: - Journal Locked View
public struct JournalLockedView: View {
    public var onUnlock: () -> Void

    public init(onUnlock: @escaping () -> Void) {
        self.onUnlock = onUnlock
    }

    public var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(ShepherdTheme.accentSubtle)
                    .frame(width: 88, height: 88)

                Image(systemName: "lock.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(ShepherdTheme.accentFill)
            }

            VStack(spacing: 8) {
                Text("Journal Locked")
                    .font(ShepherdTheme.title1Serif())
                    .foregroundStyle(ShepherdTheme.textPrimary)

                Text("Your reflections and prayer requests are protected.")
                    .font(.body)
                    .foregroundStyle(ShepherdTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            ProminentGlassButton("Unlock Journal", icon: "faceid") {
                onUnlock()
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ShepherdTheme.canvasBg.ignoresSafeArea())
    }
}
