import Foundation

@MainActor
final class ContentStore: ObservableObject {
    static let shared = ContentStore()

    @Published private(set) var bible: BibleBundle?
    @Published private(set) var paths: [StudyPath] = []
    @Published private(set) var loadError: String?

    func loadIfNeeded() {
        guard bible == nil || paths.isEmpty else { return }
        do {
            bible = try loadJSON("sample_bible", as: BibleBundle.self)
            let bundle = try loadJSON("paths", as: PathBundle.self)
            paths = bundle.paths
        } catch {
            loadError = error.localizedDescription
        }
    }

    func verse(ref: String) -> String? {
        // refs like "JHN.1.1" or "GEN.1.1"
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

    private func loadJSON<T: Decodable>(_ name: String, as type: T.Type) throws -> T {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
            throw NSError(domain: "Shepherd", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing \(name).json in bundle"])
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(T.self, from: data)
    }
}
