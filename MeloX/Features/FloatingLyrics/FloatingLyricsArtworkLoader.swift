import Foundation
import UIKit

@MainActor
final class FloatingLyricsArtworkLoader {
    private(set) var image: UIImage?

    private var selectedSongID: Int?
    private var selectedURL: URL?
    private var loadTask: Task<Void, Never>?

    func loadIfNeeded(
        songID: Int?,
        url: URL?,
        onImageLoaded: @escaping @MainActor () -> Void
    ) {
        guard selectedSongID != songID || selectedURL != url else {
            return
        }

        selectedSongID = songID
        selectedURL = url
        image = nil
        loadTask?.cancel()

        guard let songID, let url else { return }

        loadTask = Task { [weak self] in
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                try Task.checkCancellation()
                guard let loadedImage = UIImage(data: data),
                      self?.selectedSongID == songID,
                      self?.selectedURL == url else {
                    return
                }

                self?.image = loadedImage
                onImageLoaded()
            } catch {
                return
            }
        }
    }
}
