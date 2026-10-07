import SwiftUI
import SwiftData

public struct JournalView: View {
    @ObservedObject private var auth = JournalAuthService.shared
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @EnvironmentObject private var content: ContentStore

    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]
    @Query(sort: \PrayerRequest.createdAt, order: .reverse) private var prayers: [PrayerRequest]

    @State private var selectedSegment: Int = 0
    @State private var grouping: JournalGrouping = .date
    @State private var prayerFilter: PrayerFilter = .all
    @State private var quickPrayerText: String = ""

    @State private var showNewEntrySheet: Bool = false
    @State private var showNewPrayerSheet: Bool = false
    @State private var showLockSettingsSheet: Bool = false
    @State private var selectedEntry: JournalEntry? = nil
    @State private var editingPrayer: PrayerRequest? = nil
    @State private var entryToDelete: JournalEntry? = nil
    @State private var prayerToDelete: PrayerRequest? = nil

    public init() {}

    private var isLocked: Bool {
        auth.isLockEnabled && !auth.isUnlocked
    }

    public var body: some View {
        Group {
            if isLocked {
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

                    if !isLocked {
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
        }
        .task {
            if isLocked {
                _ = await auth.authenticate()
            }
        }
        .onDisappear {
            auth.journalDidDisappear()
        }
        .onChange(of: isLocked) { _, locked in
            // A sheet would stay on top of the locked screen: close every one that shows entries.
            guard locked else { return }
            selectedEntry = nil
            editingPrayer = nil
            showNewEntrySheet = false
            showNewPrayerSheet = false
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
        .alert("Delete Reflection?", isPresented: Binding(
            get: { entryToDelete != nil },
            set: { if !$0 { entryToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let entry = entryToDelete {
                    modelContext.delete(entry)
                    try? modelContext.save()
                }
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .alert("Delete Prayer?", isPresented: Binding(
            get: { prayerToDelete != nil },
            set: { if !$0 { prayerToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let prayer = prayerToDelete {
                    modelContext.delete(prayer)
                    try? modelContext.save()
                }
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }

    private var journalContent: some View {
        VStack(spacing: 0) {
            Picker("Journal Section", selection: $selectedSegment) {
                Text("Reflections (\(entries.count))").tag(0)
                Text("Prayers (\(prayers.count))").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    if selectedSegment == 0 {
                        reflectionsContent
                    } else {
                        prayersContent
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 40)
            }
            .scrollEdgeEffectStyle(.soft, for: .top)
        }
        .background(ShepherdTheme.canvasBg.ignoresSafeArea())
    }

    // MARK: - Reflections

    @ViewBuilder
    private var reflectionsContent: some View {
        if entries.isEmpty {
            emptyState(
                icon: "book.pages",
                title: "No reflections yet",
                message: "After completing a daily lesson, write a reflection to keep here. You can also write a reflection anytime."
            )
            ProminentGlassButton("Write a Reflection", icon: "square.and.pencil") {
                showNewEntrySheet = true
            }
            .padding(.horizontal, 12)
        } else {
            Picker("Arrange", selection: $grouping) {
                ForEach(JournalGrouping.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.menu)
            .tint(ShepherdTheme.accent)
            .accessibilityIdentifier("ReflectionGroupingMenu")

            switch grouping {
            case .date:
                ForEach(entries) { entry in
                    reflectionCard(entry)
                }
            case .path:
                ForEach(JournalGrouping.byPath(entries, paths: content.paths)) { section in
                    Text(section.title.uppercased())
                        .font(ShepherdTheme.scriptureEyebrow())
                        .foregroundStyle(ShepherdTheme.accentFill)
                        .padding(.top, 6)
                        .accessibilityAddTraits(.isHeader)
                    ForEach(section.entries) { entry in
                        reflectionCard(entry)
                    }
                }
            }
        }
    }

    private func emptyState(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 52))
                .foregroundStyle(ShepherdTheme.accentFill)
                .accessibilityHidden(true)

            Text(title)
                .font(ShepherdTheme.title1Serif())
                .foregroundStyle(ShepherdTheme.textPrimary)

            Text(message)
                .font(.body)
                .foregroundStyle(ShepherdTheme.textSecondary)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.top, 32)
        .padding(.bottom, 8)
    }

    private func reflectionCard(_ entry: JournalEntry) -> some View {
        Button {
            selectedEntry = entry
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .center) {
                        reflectionDate(entry)
                        Spacer()
                        reflectionTag(entry)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        reflectionDate(entry)
                        reflectionTag(entry)
                    }
                }

                if let prompt = entry.prompt, !prompt.isEmpty {
                    Text("Prompt: \(prompt)")
                        .font(.subheadline.italic())
                        .foregroundStyle(ShepherdTheme.textSecondary)
                        .lineLimit(2)
                }

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
            .shepherdSurfaceCard()
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                selectedEntry = entry
            } label: {
                Label("Edit Reflection", systemImage: "pencil")
            }

            Button(role: .destructive) {
                entryToDelete = entry
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func reflectionDate(_ entry: JournalEntry) -> some View {
        Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
            .font(.footnote.weight(.medium))
            .foregroundStyle(ShepherdTheme.textSecondary)
    }

    @ViewBuilder
    private func reflectionTag(_ entry: JournalEntry) -> some View {
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

    // MARK: - Prayers

    @ViewBuilder
    private var prayersContent: some View {
        prayerFilterControl
        quickAddField

        let shown = prayerFilter.apply(to: prayers)
        if shown.isEmpty {
            emptyState(
                icon: prayerFilter == .answered ? "hands.sparkles" : "heart.text.square",
                title: prayerFilter == .answered ? "No answered prayers yet" : (prayerFilter == .open ? "No open prayer requests" : "No prayers yet"),
                message: prayerFilter == .answered ? "When God answers a prayer, tap the circle to mark it answered with the date." : "Add a prayer above to begin your prayer list."
            )
        } else {
            ForEach(shown) { prayer in
                prayerCard(prayer)
            }
        }
    }

    /// Pills at regular sizes; at accessibility sizes three pills cannot fit a row, so a menu.
    @ViewBuilder
    private var prayerFilterControl: some View {
        if dynamicTypeSize.isAccessibilitySize {
            Picker("Show", selection: $prayerFilter) {
                ForEach(PrayerFilter.allCases) { filter in
                    Text("\(filter.rawValue) (\(filter.apply(to: prayers).count))").tag(filter)
                }
            }
            .pickerStyle(.menu)
            .tint(ShepherdTheme.accent)
            .accessibilityIdentifier("PrayerFilterMenu")
        } else {
            HStack(spacing: 8) {
                ForEach(PrayerFilter.allCases) { filter in
                    let isSelected = prayerFilter == filter
                    Button {
                        withAnimation {
                            prayerFilter = filter
                        }
                    } label: {
                        Text("\(filter.rawValue) (\(filter.apply(to: prayers).count))")
                            .font(.subheadline.weight(isSelected ? .bold : .medium))
                            .lineLimit(1)
                            .foregroundStyle(isSelected ? ShepherdTheme.onAccent : ShepherdTheme.textPrimary)
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
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
                Spacer()
            }
        }
    }

    private var quickAddField: some View {
        HStack(spacing: 10) {
            TextField("Add a prayer request…", text: $quickPrayerText)
                .font(.body)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .shepherdSurfaceCard(cornerRadius: ShepherdTheme.radiusSM)
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
    }

    private func addQuickPrayer() {
        let trimmed = quickPrayerText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let newPrayer = PrayerRequest(text: trimmed)
        modelContext.insert(newPrayer)
        try? modelContext.save()
        quickPrayerText = ""
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

                Text("Added \(prayer.createdAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(ShepherdTheme.textTertiary)

                if prayer.isAnswered, let answered = prayer.answeredDate {
                    Label("Answered \(answered.formatted(date: .abbreviated, time: .omitted))", systemImage: "sparkles")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(ShepherdTheme.accentFill)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                editingPrayer = prayer
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16))
                    .foregroundStyle(ShepherdTheme.textTertiary)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Edit prayer")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .shepherdSurfaceCard()
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
                prayerToDelete = prayer
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
