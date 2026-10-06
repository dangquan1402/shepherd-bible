import Foundation

@MainActor
public final class ContentStore: ObservableObject {
    public static let shared = ContentStore()

    @Published public private(set) var bible: BibleBundle?
    @Published public private(set) var paths: [StudyPath] = []

    private var verseIndex: [String: String] = [:]
    private var bibleLoad: Task<Void, Never>?

    public init() {}

    /// Paths load synchronously (small). The 4.8 MB Bible decodes off the main thread; views
    /// observe `bible` and re-render when it arrives.
    public func loadIfNeeded() {
        if paths.isEmpty {
            do {
                let url = try Self.resourceURL("paths")
                let bundle = try JSONDecoder().decode(PathBundle.self, from: Data(contentsOf: url))
                paths = bundle.paths.sorted { $0.sortOrder < $1.sortOrder }
            } catch {
                print("ContentStore paths load error: \(error)")
            }
        }
        if bible == nil, bibleLoad == nil {
            bibleLoad = Task { await self.loadBible() }
        }
    }

    /// Await the Bible (tests, and anything that needs verse text right now).
    public func ensureBibleLoaded() async {
        loadIfNeeded()
        await bibleLoad?.value
    }

    private func loadBible() async {
        let started = Date()
        let result: Result<DecodedBible, Error> = await Task.detached(priority: .userInitiated) {
            Result { try Self.decodeBible(from: Data(contentsOf: Self.resourceURL("web"))) }
        }.value
        switch result {
        case .success(let decoded):
            verseIndex = decoded.index
            bible = decoded.bundle
            #if DEBUG
            print("ContentStore: Bible decoded in \(Int(Date().timeIntervalSince(started) * 1000)) ms, \(decoded.index.count) verses")
            #endif
        case .failure(let error):
            print("ContentStore Bible load error: \(error)")
            bibleLoad = nil
        }
    }

    public struct DecodedBible: Sendable {
        public let bundle: BibleBundle
        public let index: [String: String]
    }

    public nonisolated static func decodeBible(from data: Data) throws -> DecodedBible {
        let bundle = try JSONDecoder().decode(BibleBundle.self, from: data)
        var index: [String: String] = [:]
        index.reserveCapacity(31_200)
        for book in bundle.books {
            for chapter in book.chapters {
                for verse in chapter.verses {
                    index["\(book.abbrev).\(chapter.number).\(verse.number)"] = verse.text
                }
            }
        }
        return DecodedBible(bundle: bundle, index: index)
    }

    public func verse(ref: String) -> String? {
        verseIndex[ref]
    }

    public func path(id: String?) -> StudyPath? {
        guard let id else { return nil }
        return paths.first { $0.id == id }
    }

    public func path(containing lesson: Lesson) -> StudyPath? {
        paths.first { $0.lessons.contains(lesson) }
    }

    /// The path the Today tab follows: the profile's choice, else the first path (the free one).
    public func activePath(id: String?) -> StudyPath? {
        path(id: id) ?? paths.first
    }

    // MARK: - Reference display

    /// "PHP.4.7" -> "Philippians 4:7".
    public nonisolated static func displayRef(_ ref: String) -> String {
        let parts = ref.split(separator: ".")
        guard parts.count == 3,
              let chapterNum = Int(parts[1]),
              let verseNum = Int(parts[2]) else {
            return ref
        }
        return "\(bookName(String(parts[0]))) \(chapterNum):\(verseNum)"
    }

    /// Consecutive verses collapse into ranges:
    /// ["MAT.6.9", "MAT.6.11", "PHP.4.6", "PHP.4.7"] -> "Matthew 6:9, 11; Philippians 4:6–7".
    public nonisolated static func displayRefs(_ refs: [String]) -> String {
        struct Group { let book: String; let chapter: Int; var runs: [(Int, Int)] }
        var groups: [Group] = []
        for ref in refs {
            let parts = ref.split(separator: ".")
            guard parts.count == 3, let c = Int(parts[1]), let v = Int(parts[2]) else { continue }
            let book = String(parts[0])
            if var last = groups.last, last.book == book, last.chapter == c {
                if let run = last.runs.last, run.1 + 1 == v {
                    last.runs[last.runs.count - 1].1 = v
                } else {
                    last.runs.append((v, v))
                }
                groups[groups.count - 1] = last
            } else {
                groups.append(Group(book: book, chapter: c, runs: [(v, v)]))
            }
        }
        return groups.map { g in
            let runs = g.runs.map { $0.0 == $0.1 ? "\($0.0)" : "\($0.0)–\($0.1)" }.joined(separator: ", ")
            return "\(bookName(g.book)) \(g.chapter):\(runs)"
        }.joined(separator: "; ")
    }

    /// Book names as the bundled WEB spells them (a unit test keeps this table equal to web.json),
    /// except that a single psalm is cited as "Psalm".
    public nonisolated static func bookName(_ abbrev: String) -> String {
        bookNames[abbrev] ?? abbrev
    }

    public nonisolated static let bookNames: [String: String] = [
        "GEN": "Genesis", "EXO": "Exodus", "LEV": "Leviticus", "NUM": "Numbers", "DEU": "Deuteronomy",
        "JOS": "Joshua", "JDG": "Judges", "RUT": "Ruth", "1SA": "1 Samuel", "2SA": "2 Samuel",
        "1KI": "1 Kings", "2KI": "2 Kings", "1CH": "1 Chronicles", "2CH": "2 Chronicles", "EZR": "Ezra",
        "NEH": "Nehemiah", "EST": "Esther", "JOB": "Job", "PSA": "Psalm", "PRO": "Proverbs",
        "ECC": "Ecclesiastes", "SNG": "Song of Solomon", "ISA": "Isaiah", "JER": "Jeremiah",
        "LAM": "Lamentations", "EZK": "Ezekiel", "DAN": "Daniel", "HOS": "Hosea", "JOL": "Joel",
        "AMO": "Amos", "OBA": "Obadiah", "JON": "Jonah", "MIC": "Micah", "NAM": "Nahum",
        "HAB": "Habakkuk", "ZEP": "Zephaniah", "HAG": "Haggai", "ZEC": "Zechariah", "MAL": "Malachi",
        "MAT": "Matthew", "MRK": "Mark", "LUK": "Luke", "JHN": "John", "ACT": "Acts", "ROM": "Romans",
        "1CO": "1 Corinthians", "2CO": "2 Corinthians", "GAL": "Galatians", "EPH": "Ephesians",
        "PHP": "Philippians", "COL": "Colossians", "1TH": "1 Thessalonians", "2TH": "2 Thessalonians",
        "1TI": "1 Timothy", "2TI": "2 Timothy", "TIT": "Titus", "PHM": "Philemon", "HEB": "Hebrews",
        "JAS": "James", "1PE": "1 Peter", "2PE": "2 Peter", "1JN": "1 John", "2JN": "2 John",
        "3JN": "3 John", "JUD": "Jude", "REV": "Revelation",
    ]

    private nonisolated static func resourceURL(_ name: String) throws -> URL {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
            throw NSError(domain: "Shepherd", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing \(name).json in bundle"])
        }
        return url
    }
}
