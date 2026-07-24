import AVFoundation
import AVKit
import CoreMedia
import Observation
import UIKit

@MainActor
@Observable
final class FloatingLyricsController: NSObject {
    private(set) var isSupported: Bool
    private(set) var isPossible = false
    private(set) var isActive = false
    private(set) var restorationRequestID = 0
    private(set) var errorMessage: String?

    @ObservationIgnored
    private let player: PlayerStore

    @ObservationIgnored
    private let settings: AppSettings

    @ObservationIgnored
    private let lyricsStore: LyricsStore

    @ObservationIgnored
    private let displayLayer = AVSampleBufferDisplayLayer()

    @ObservationIgnored
    private let frameRenderer: FloatingLyricsFrameRenderer

    @ObservationIgnored
    private let artworkLoader = FloatingLyricsArtworkLoader()

    @ObservationIgnored
    private var pictureInPictureController: AVPictureInPictureController?

    @ObservationIgnored
    private var playbackTimebase: CMTimebase?

    @ObservationIgnored
    private weak var sourceHostLayer: CALayer?

    @ObservationIgnored
    private var lastPresentation: FloatingLyricsPresentation?

    @ObservationIgnored
    private var lastPlaybackState: PlaybackState?

    @ObservationIgnored
    private var restorationCompletion: ((Bool) -> Void)?

    init(
        player: PlayerStore,
        settings: AppSettings,
        lyricsStore: LyricsStore
    ) {
        self.player = player
        self.settings = settings
        self.lyricsStore = lyricsStore
        frameRenderer = FloatingLyricsFrameRenderer(
            player: player,
            settings: settings
        )
        isSupported = AVPictureInPictureController
            .isPictureInPictureSupported()
        super.init()

        displayLayer.videoGravity = .resizeAspect
        displayLayer.backgroundColor = UIColor.black.cgColor
        configurePlaybackTimebase()

        guard isSupported else { return }

        let contentSource = AVPictureInPictureController.ContentSource(
            sampleBufferDisplayLayer: displayLayer,
            playbackDelegate: self
        )
        let controller = AVPictureInPictureController(
            contentSource: contentSource
        )
        controller.delegate = self
        controller.requiresLinearPlayback = false
        pictureInPictureController = controller
    }

    func monitor() async {
        refreshArtworkIfNeeded()
        refreshFrame(force: true)

        while !Task.isCancelled {
            let pictureInPicturePossible = pictureInPictureController?
                .isPictureInPicturePossible ?? false
            if isPossible != pictureInPicturePossible {
                isPossible = pictureInPicturePossible
            }
            refreshArtworkIfNeeded()
            synchronizePlaybackState()
            refreshFrame()

            do {
                try await Task.sleep(
                    for: .seconds(frameUpdateInterval)
                )
            } catch {
                return
            }
        }
    }

    func toggle() {
        guard let pictureInPictureController else {
            errorMessage = "当前设备不支持系统画中画。"
            return
        }

        if pictureInPictureController.isPictureInPictureActive {
            pictureInPictureController.stopPictureInPicture()
            return
        }

        refreshArtworkIfNeeded()
        refreshFrame(force: true)
        synchronizePlaybackState(force: true)
        isPossible = pictureInPictureController
            .isPictureInPicturePossible

        guard player.currentSong != nil else {
            errorMessage = "请先播放一首歌曲。"
            return
        }
        guard isPossible else {
            errorMessage = "系统画中画暂时不可用，请稍后再试。"
            return
        }

        pictureInPictureController.startPictureInPicture()
    }

    func attachDisplayLayer(to hostLayer: CALayer, bounds: CGRect) {
        if displayLayer.superlayer !== hostLayer {
            displayLayer.removeFromSuperlayer()
            hostLayer.addSublayer(displayLayer)
        }
        sourceHostLayer = hostLayer
        displayLayer.frame = bounds
        refreshArtworkIfNeeded()
        refreshFrame(force: true)
    }

    func updateDisplayLayerFrame(_ bounds: CGRect) {
        displayLayer.frame = bounds
    }

    func detachDisplayLayer(from hostLayer: CALayer) {
        guard sourceHostLayer === hostLayer else { return }
        displayLayer.removeFromSuperlayer()
        sourceHostLayer = nil
        isPossible = false
    }

    func completeRestoration(success: Bool) {
        restorationCompletion?(success)
        restorationCompletion = nil
    }

    func dismissError() {
        errorMessage = nil
    }

    private func configurePlaybackTimebase() {
        var timebase: CMTimebase?
        let status = CMTimebaseCreateWithSourceClock(
            allocator: kCFAllocatorDefault,
            sourceClock: CMClockGetHostTimeClock(),
            timebaseOut: &timebase
        )
        guard status == noErr, let timebase else { return }

        playbackTimebase = timebase
        displayLayer.controlTimebase = timebase
        CMTimebaseSetTime(timebase, time: .zero)
        CMTimebaseSetRate(timebase, rate: 0)
    }

    private func synchronizePlaybackState(force: Bool = false) {
        let state = PlaybackState(
            songID: player.currentSong?.id,
            isPlaying: player.isPlaying,
            duration: player.duration,
            seekRevision: player.seekRevision
        )
        let stateChanged = state != lastPlaybackState
        guard force || stateChanged else { return }

        if let playbackTimebase {
            let currentTime = CMTime(
                seconds: player.estimatedProgress(),
                preferredTimescale: 600
            )
            CMTimebaseSetRate(playbackTimebase, rate: 0)
            CMTimebaseSetTime(playbackTimebase, time: currentTime)
            CMTimebaseSetRate(
                playbackTimebase,
                rate: player.isPlaying ? 1 : 0
            )
        }

        lastPlaybackState = state
        pictureInPictureController?.invalidatePlaybackState()
    }

    private func refreshFrame(force: Bool = false) {
        let presentation = makePresentation()
        guard force || presentation != lastPresentation else { return }

        let presentationTime = playbackTimebase.map {
            CMTimebaseGetTime($0)
        } ?? CMClockGetTime(CMClockGetHostTimeClock())
        guard let sampleBuffer = frameRenderer.makeSampleBuffer(
            presentation: presentation,
            artworkImage: artworkLoader.image,
            presentationTime: presentationTime
        ) else {
            return
        }

        displayLayer.sampleBufferRenderer.enqueue(sampleBuffer)
        lastPresentation = presentation
    }

    private var frameUpdateInterval: TimeInterval {
        if isActive, player.isPlaying {
            return max(
                settings.lyricsRefreshRate.minimumInterval,
                1.0 / 30.0
            )
        }
        return isActive ? 0.25 : 0.8
    }

    private func refreshArtworkIfNeeded() {
        let song = player.currentSong
        artworkLoader.loadIfNeeded(
            songID: song?.id,
            url: song?.album?.artworkURL
        ) { [weak self] in
            self?.refreshFrame(force: true)
        }
    }

    private func makePresentation() -> FloatingLyricsPresentation {
        guard let song = player.currentSong else {
            return FloatingLyricsPresentation(
                songID: nil,
                title: "MeloX",
                artist: "悬浮歌词",
                currentLine: nil,
                upcomingLines: [],
                fallbackText: "播放音乐后显示歌词",
                playbackTime: 0,
                isPlaying: false,
                usesPseudoTiming: false,
                showsTranslation: false,
                fontScale: settings.floatingLyrics.fontScale
            )
        }

        let lyrics = lyricsStore.songID == song.id
            ? lyricsStore.lyrics
            : []
        let playbackTime = player.estimatedProgress()
            + settings.lyricsAdvanceTime
        let position = LyricPlaybackTimeline.position(
            at: playbackTime,
            in: lyrics
        )
        let currentIndex = position.highlightedLyricID.flatMap { lyricID in
            lyrics.firstIndex(where: { $0.id == lyricID })
        }
        let currentLine = currentIndex.map { lyrics[$0] }
        let upcomingLines: [LyricLine]
        if settings.floatingLyrics.showsNextLine {
            let firstUpcomingIndex = currentIndex.map {
                lyrics.index(after: $0)
            } ?? lyrics.startIndex
            upcomingLines = firstUpcomingIndex < lyrics.endIndex
                ? Array(lyrics[firstUpcomingIndex...].prefix(2))
                : []
        } else {
            upcomingLines = []
        }

        let fallbackText: String
        if let currentLine {
            fallbackText = currentLine.text
        } else if lyricsStore.songID != song.id || lyricsStore.isLoading {
            fallbackText = "正在载入歌词…"
        } else if lyricsStore.errorMessage != nil || lyrics.isEmpty {
            fallbackText = "当前歌曲暂无滚动歌词"
        } else {
            fallbackText = "♪"
        }

        let usesPseudoTiming = settings.lyricsPseudoWordByWord
            && !lyrics.contains(where: \.isSyllableSynced)
        return FloatingLyricsPresentation(
            songID: song.id,
            title: song.name,
            artist: song.artistText,
            currentLine: currentLine,
            upcomingLines: upcomingLines,
            fallbackText: fallbackText,
            playbackTime: playbackTime,
            isPlaying: player.isPlaying,
            usesPseudoTiming: usesPseudoTiming,
            showsTranslation: settings.lyricsTranslationEnabled
                && settings.floatingLyrics.showsTranslation,
            fontScale: settings.floatingLyrics.fontScale
        )
    }
}

extension FloatingLyricsController: AVPictureInPictureControllerDelegate {
    func pictureInPictureControllerWillStartPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        refreshFrame(force: true)
    }

    func pictureInPictureControllerDidStartPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        isActive = true
        isPossible = true
    }

    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        failedToStartPictureInPictureWithError error: any Error
    ) {
        isActive = false
        errorMessage = error.localizedDescription
    }

    func pictureInPictureControllerDidStopPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        isActive = false
        isPossible = pictureInPictureController
            .isPictureInPicturePossible
    }

    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        restoreUserInterfaceForPictureInPictureStopWithCompletionHandler
            completionHandler: @escaping (Bool) -> Void
    ) {
        restorationCompletion?(false)
        restorationCompletion = completionHandler
        restorationRequestID += 1
    }
}

extension FloatingLyricsController:
    AVPictureInPictureSampleBufferPlaybackDelegate {
    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        setPlaying playing: Bool
    ) {
        if player.isPlaying != playing {
            player.togglePlayback()
        }
        synchronizePlaybackState(force: true)
        refreshFrame(force: true)
    }

    func pictureInPictureControllerTimeRangeForPlayback(
        _ pictureInPictureController: AVPictureInPictureController
    ) -> CMTimeRange {
        guard let song = player.currentSong else { return .invalid }

        let songDuration = TimeInterval(song.durationMS) / 1_000
        let duration = max(player.duration, songDuration, 1) + 1
        return CMTimeRange(
            start: .zero,
            duration: CMTime(seconds: duration, preferredTimescale: 600)
        )
    }

    func pictureInPictureControllerIsPlaybackPaused(
        _ pictureInPictureController: AVPictureInPictureController
    ) -> Bool {
        !player.isPlaying
    }

    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        didTransitionToRenderSize newRenderSize: CMVideoDimensions
    ) {
        refreshFrame(force: true)
    }

    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        skipByInterval skipInterval: CMTime,
        completion completionHandler: @escaping () -> Void
    ) {
        let targetTime = player.estimatedProgress()
            + skipInterval.seconds
        player.seek(to: targetTime)
        synchronizePlaybackState(force: true)
        refreshFrame(force: true)
        completionHandler()
    }

    func pictureInPictureControllerShouldProhibitBackgroundAudioPlayback(
        _ pictureInPictureController: AVPictureInPictureController
    ) -> Bool {
        false
    }
}

private struct PlaybackState: Equatable {
    let songID: Int?
    let isPlaying: Bool
    let duration: TimeInterval
    let seekRevision: Int
}
