import Foundation

public final class DailyVerseService: Sendable {
    public static let shared = DailyVerseService()

    public let verses: [DailyVerse]

    public static let fallback = DailyVerse(
        dayIndex: 1,
        ref: "PSA.23.1",
        bookAbbrev: "PSA",
        chapter: 23,
        verse: 1,
        bookName: "Psalm",
        displayRef: "Psalm 23:1",
        text: "The LORD is my shepherd; I shall lack nothing."
    )

    public init(items: [DailyVerseItem]? = nil) {
        if let items {
            self.verses = Self.convert(items: items)
        } else {
            let loaded = Self.loadItemsFromBundle()
            self.verses = Self.convert(items: loaded)
        }
    }

    public func verse(for date: Date = .now, calendar: Calendar = .current) -> DailyVerse {
        guard !verses.isEmpty else { return Self.fallback }
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let rawIndex = (dayOfYear - 1) % verses.count
        let index = rawIndex >= 0 ? rawIndex : (rawIndex + verses.count) % verses.count
        return verses[index]
    }

    public func nextMidnight(after date: Date = .now, calendar: Calendar = .current) -> Date {
        calendar.nextDate(after: date, matching: DateComponents(hour: 0, minute: 0, second: 0), matchingPolicy: .nextTime)
            ?? calendar.startOfDay(for: date).addingTimeInterval(86400)
    }

    private static func loadItemsFromBundle() -> [DailyVerseItem] {
        guard let url = findResourceURL(name: "daily_verses", ext: "json") else {
            #if DEBUG
            print("DailyVerseService: daily_verses.json not found in bundles")
            #endif
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([DailyVerseItem].self, from: data)
        } catch {
            #if DEBUG
            print("DailyVerseService decode error: \(error)")
            #endif
            return []
        }
    }

    private static func findResourceURL(name: String, ext: String) -> URL? {
        if let url = Bundle.main.url(forResource: name, withExtension: ext) {
            return url
        }
        for bundle in Bundle.allBundles {
            if let url = bundle.url(forResource: name, withExtension: ext) {
                return url
            }
        }
        return nil
    }

    private static func convert(items: [DailyVerseItem]) -> [DailyVerse] {
        items.enumerated().map { idx, item in
            let parts = item.ref.split(separator: ".")
            let bookAbbrev = parts.count > 0 ? String(parts[0]) : "GEN"
            let chapter = parts.count > 1 ? Int(parts[1]) ?? 1 : 1
            let verseNum = parts.count > 2 ? Int(parts[2]) ?? 1 : 1
            let bName = bookNames[bookAbbrev] ?? (bookAbbrev == "PSA" ? "Psalm" : bookAbbrev)
            let display = "\(bName) \(chapter):\(verseNum)"
            return DailyVerse(
                dayIndex: item.day ?? (idx + 1),
                ref: item.ref,
                bookAbbrev: bookAbbrev,
                chapter: chapter,
                verse: verseNum,
                bookName: bName,
                displayRef: display,
                text: item.text
            )
        }
    }

    public static let bookNames: [String: String] = [
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
}
