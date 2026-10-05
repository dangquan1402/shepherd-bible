import SwiftUI

struct PathListView: View {
    @EnvironmentObject private var content: ContentStore

    var body: some View {
        NavigationStack {
            List(content.paths) { path in
                NavigationLink(path.title) {
                    List(path.lessons) { lesson in
                        NavigationLink(lesson.title) {
                            LessonView(lesson: lesson)
                        }
                    }
                    .navigationTitle(path.title)
                }
            }
            .navigationTitle("Paths")
        }
    }
}
