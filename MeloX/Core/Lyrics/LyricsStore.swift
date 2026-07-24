import Foundation
import Observation

@MainActor
@Observable
final class LyricsStore {
    private(set) var songID: Int?
    private(set) var lyrics: [LyricLine] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    @ObservationIgnored
    private let api: NeteaseAPI

    @ObservationIgnored
    private var loadGeneration = 0

    init(api: NeteaseAPI) {
        self.api = api
    }

    func load(for songID: Int?) async {
        loadGeneration += 1
        let generation = loadGeneration

        self.songID = songID
        lyrics = []
        errorMessage = nil
        isLoading = songID != nil

        guard let songID else { return }

        do {
            let loadedLyrics = try await api.lyrics(id: songID)
            try Task.checkCancellation()
            guard generation == loadGeneration else { return }

            lyrics = loadedLyrics
            errorMessage = loadedLyrics.isEmpty
                ? "当前歌曲暂无滚动歌词。"
                : nil
            isLoading = false
        } catch is CancellationError {
            return
        } catch {
            guard generation == loadGeneration else { return }
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}
