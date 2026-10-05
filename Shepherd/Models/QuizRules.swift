import Foundation

public enum QuizRules {
    public static func answeringVerse(
        for question: QuizQuestion,
        in lesson: Lesson,
        verses: (String) -> String?
    ) -> (ref: String, text: String) {
        let correctText = question.choices[question.correctIndex]
        for ref in lesson.verseRefs {
            if let text = verses(ref),
               text.localizedCaseInsensitiveContains(correctText) {
                return (ref, text)
            }
        }
        if let firstRef = lesson.verseRefs.first, let text = verses(firstRef) {
            return (firstRef, text)
        }
        return ("GEN.1.1", "In the beginning, God created the heavens and the earth.")
    }
}
