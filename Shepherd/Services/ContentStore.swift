import Foundation

@MainActor
public final class ContentStore: ObservableObject {
    public static let shared = ContentStore()

    @Published public private(set) var bible: BibleBundle?
    @Published public private(set) var paths: [StudyPath] = []

    public init() {}

    public func loadIfNeeded() {
        guard bible == nil || paths.isEmpty else { return }
        do {
            bible = try loadJSON("sample_bible", as: BibleBundle.self)
            let bundle = try loadJSON("paths", as: PathBundle.self)
            paths = bundle.paths
        } catch {
            print("ContentStore load error: \(error)")
        }
    }

    public func verse(ref: String) -> String? {
        let parts = ref.split(separator: ".")
        guard parts.count == 3,
              let chapterNum = Int(parts[1]),
              let verseNum = Int(parts[2]),
              let book = bible?.books.first(where: { $0.abbrev == parts[0] }),
              let chapter = book.chapters.first(where: { $0.number == chapterNum }),
              let verse = chapter.verses.first(where: { $0.number == verseNum })
        else { return nil }
        return verse.text
    }

    public static func displayRef(_ ref: String) -> String {
        let parts = ref.split(separator: ".")
        guard parts.count == 3,
              let chapterNum = Int(parts[1]),
              let verseNum = Int(parts[2]) else {
            return ref
        }
        let abbrev = String(parts[0])
        let bookName: String = {
            switch abbrev {
            case "GEN": return "Genesis"
            case "EXO": return "Exodus"
            case "LEV": return "Leviticus"
            case "NUM": return "Numbers"
            case "DEU": return "Deuteronomy"
            case "PSA": return "Psalms"
            case "PRO": return "Proverbs"
            case "MAT": return "Matthew"
            case "MRK": return "Mark"
            case "LUK": return "Luke"
            case "JHN": return "John"
            case "ACT": return "Acts"
            case "ROM": return "Romans"
            case "PHP": return "Philippians"
            case "REV": return "Revelation"
            default: return abbrev
            }
        }()
        return "\(bookName) \(chapterNum):\(verseNum)"
    }

    private func loadJSON<T: Decodable>(_ name: String, as type: T.Type) throws -> T {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
            throw NSError(domain: "Shepherd", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing \(name).json in bundle"])
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(T.self, from: data)
    }
}
