import CoreGraphics
import CoreImage
import Foundation

@MainActor
final class FloatingLyricsArtworkLoader {
    private(set) var image: CGImage?

    private var selectedSongID: Int?
    private var selectedURL: URL?
    private var loadTask: Task<Void, Never>?
    private let context = CIContext(options: [.cacheIntermediates: false])

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
                let requestURL = Self.optimizedURL(from: url)
                let (data, response) = try await URLSession.shared.data(
                    from: requestURL
                )
                try Task.checkCancellation()
                guard let response = response as? HTTPURLResponse,
                      (200..<300).contains(response.statusCode),
                      let sourceImage = CIImage(
                        data: data,
                        options: [.applyOrientationProperty: true]
                      ),
                      let loadedImage = self?.makeDisplayImage(
                        from: sourceImage
                      ),
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

    private func makeDisplayImage(from sourceImage: CIImage) -> CGImage? {
        let extent = sourceImage.extent.integral
        guard !extent.isEmpty, !extent.isInfinite else { return nil }

        let maximumDimension = max(extent.width, extent.height)
        let preparedImage: CIImage
        if maximumDimension > 480 {
            let scale = 480 / maximumDimension
            preparedImage = sourceImage.transformed(
                by: CGAffineTransform(scaleX: scale, y: scale)
            )
        } else {
            preparedImage = sourceImage
        }

        let outputExtent = preparedImage.extent.integral
        return context.createCGImage(
            preparedImage,
            from: outputExtent,
            format: .RGBA8,
            colorSpace: CGColorSpace(name: CGColorSpace.sRGB)
        )
    }

    private static func optimizedURL(from url: URL) -> URL {
        guard url.host?.hasSuffix(".music.126.net") == true,
              var components = URLComponents(
                url: url,
                resolvingAgainstBaseURL: false
              ) else {
            return url
        }

        var queryItems = components.queryItems ?? []
        queryItems.removeAll {
            $0.name.caseInsensitiveCompare("param") == .orderedSame
        }
        queryItems.append(
            URLQueryItem(name: "param", value: "480y480")
        )
        components.queryItems = queryItems
        return components.url ?? url
    }
}
