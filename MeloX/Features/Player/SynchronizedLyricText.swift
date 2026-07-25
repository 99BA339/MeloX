import SwiftUI

enum SynchronizedLyricTextAlignment: Equatable {
    case leading
    case center

    var textAlignment: TextAlignment {
        switch self {
        case .leading: .leading
        case .center: .center
        }
    }

    var frameAlignment: Alignment {
        switch self {
        case .leading: .leading
        case .center: .center
        }
    }

    var scaleAnchor: UnitPoint {
        switch self {
        case .leading: .topLeading
        case .center: .top
        }
    }
}

struct SynchronizedLyricText: View {
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @Environment(\.effectiveLyricsRefreshRate) private var effectiveLyricsRefreshRate
    @Environment(PlayerStore.self) private var player
    @Environment(AppSettings.self) private var settings

    let line: LyricLine
    let isPlaybackLine: Bool
    let usesPseudoTiming: Bool
    let fontSize: CGFloat
    let fontWeight: LyricsFontWeight
    let alignment: SynchronizedLyricTextAlignment
    let fontScale: CGFloat
    let primaryColor: Color
    let showsTranslation: Bool
    let reservesTranslationSpace: Bool
    let onTranslationHeightChange: ((CGFloat) -> Void)?
    let translationLayoutAnimation: Animation?
    let translationVisibilityAnimation: Animation?
    let visualScale: CGFloat
    let visualScaleAnimation: Animation?
    let layoutWidth: CGFloat?
    let playbackScaleRange: ClosedRange<CGFloat>?
    let playbackScaleStartDelay: TimeInterval
    private let synchronizedText: Text
    private let pseudoSynchronizedText: Text
    private let hasPseudoSyllables: Bool
    private let timedPlaybackRange: ClosedRange<TimeInterval>?

    init(
        line: LyricLine,
        isPlaybackLine: Bool,
        usesPseudoTiming: Bool,
        fontSize: CGFloat,
        fontWeight: LyricsFontWeight = .bold,
        alignment: SynchronizedLyricTextAlignment = .leading,
        fontScale: CGFloat = 1,
        primaryColor: Color = .white,
        showsTranslation: Bool = true,
        reservesTranslationSpace: Bool = true,
        onTranslationHeightChange: ((CGFloat) -> Void)? = nil,
        translationLayoutAnimation: Animation? = nil,
        translationVisibilityAnimation: Animation? = nil,
        visualScale: CGFloat = 1,
        visualScaleAnimation: Animation? = nil,
        layoutWidth: CGFloat? = nil,
        playbackScaleRange: ClosedRange<CGFloat>? = nil,
        playbackScaleStartDelay: TimeInterval = 0
    ) {
        self.line = line
        self.isPlaybackLine = isPlaybackLine
        self.usesPseudoTiming = usesPseudoTiming
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.alignment = alignment
        self.fontScale = fontScale
        self.primaryColor = primaryColor
        self.showsTranslation = showsTranslation
        self.reservesTranslationSpace = reservesTranslationSpace
        self.onTranslationHeightChange = onTranslationHeightChange
        self.translationLayoutAnimation = translationLayoutAnimation
        self.translationVisibilityAnimation = translationVisibilityAnimation
        self.visualScale = visualScale
        self.visualScaleAnimation = visualScaleAnimation
        self.layoutWidth = layoutWidth
        self.playbackScaleRange = playbackScaleRange
        self.playbackScaleStartDelay = playbackScaleStartDelay

        let pseudoSyllables = usesPseudoTiming
            ? line.makePseudoSyllables()
            : []
        let activeSyllables = line.syllables.isEmpty
            ? pseudoSyllables
            : line.syllables
        let timedLayoutWidth = layoutWidth.map {
            $0 / max(playbackScaleRange?.upperBound ?? 1, 1)
        }
        synchronizedText = TimedLyricTextBuilder.text(
            from: line.syllables,
            constrainedWidth: timedLayoutWidth,
            fontSize: fontSize,
            fontWeight: fontWeight
        )
        pseudoSynchronizedText = TimedLyricTextBuilder.text(
            from: pseudoSyllables,
            constrainedWidth: timedLayoutWidth,
            fontSize: fontSize,
            fontWeight: fontWeight
        )
        hasPseudoSyllables = !pseudoSyllables.isEmpty
        if let firstSyllable = activeSyllables.first,
           let lastSyllable = activeSyllables.last,
           lastSyllable.endTime > firstSyllable.startTime {
            timedPlaybackRange = firstSyllable.startTime...lastSyllable.endTime
        } else {
            timedPlaybackRange = nil
        }
    }

    var body: some View {
        LyricTranslationLayout(
            expansion:
                reservesTranslationSpace && displaysTranslation
                    ? 1
                    : 0,
            spacing: 2
        ) {
            primaryLyric
                .animation(
                    accessibilityReduceMotion ? nil : .easeInOut(duration: 0.28),
                    value: usesTimedLyrics
                )

            if let translation = line.translation {
                Text(verbatim: translation)
                    .font(
                        .system(
                            size: translationFontSize,
                            weight: fontWeight.swiftUIWeight
                        )
                    )
                    .foregroundStyle(.white.opacity(settings.lyricsTranslationOpacity))
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(
                        maxWidth: .infinity,
                        alignment: alignment.frameAlignment
                    )
                    .onGeometryChange(for: CGFloat.self) { geometry in
                        geometry.size.height
                    } action: { height in
                        onTranslationHeightChange?(height)
                    }
                    .opacity(displaysTranslation ? 1 : 0)
                    .animation(
                        accessibilityReduceMotion
                            ? nil
                            : translationVisibilityAnimation,
                        value: displaysTranslation
                    )
            }
        }
        .animation(
            accessibilityReduceMotion ? nil : translationLayoutAnimation,
            value: displaysTranslation
        )
        .multilineTextAlignment(alignment.textAlignment)
        .frame(width: layoutWidth, alignment: alignment.frameAlignment)
        .scaleEffect(visualScale, anchor: alignment.scaleAnchor)
        .animation(
            accessibilityReduceMotion ? nil : visualScaleAnimation,
            value: visualScale
        )
        .frame(maxWidth: .infinity, alignment: alignment.frameAlignment)
    }

    private var primaryLyric: some View {
        stablePrimaryLyric
            .opacity(usesTimedLyrics ? 0 : 1)
            .overlay(alignment: alignment.frameAlignment) {
                if usesTimedLyrics {
                    synchronizedPrimaryLyric
                }
            }
    }

    private var stablePrimaryLyric: some View {
        stablePrimaryContent
            .font(primaryFont)
            .foregroundStyle(primaryColor)
            .multilineTextAlignment(alignment.textAlignment)
            .lineLimit(nil)
            .fixedSize(
                horizontal: supportsTimedLyrics,
                vertical: true
            )
            .frame(
                width: primaryLayoutWidth,
                alignment: alignment.frameAlignment
            )
            .frame(
                maxWidth: .infinity,
                alignment: alignment.frameAlignment
            )
    }

    private var synchronizedPrimaryLyric: some View {
        TimelineView(
            .animation(
                minimumInterval: effectiveLyricsRefreshRate.minimumInterval,
                paused: !player.isPlaying
            )
        ) { context in
            let playbackTime = player.estimatedProgress(at: context.date)
                + settings.lyricsAdvanceTime

            activeSynchronizedText
                .font(primaryFont)
                .foregroundStyle(primaryColor)
                .multilineTextAlignment(alignment.textAlignment)
                .lineLimit(nil)
                .textRenderer(
                    lyricTextRenderer(at: playbackTime)
                )
                .frame(
                    width: timedLayoutWidth,
                    alignment: alignment.frameAlignment
                )
                .frame(
                    maxWidth: .infinity,
                    alignment: alignment.frameAlignment
                )
                .scaleEffect(
                    playbackScale(at: playbackTime),
                    anchor: .center
                )
        }
    }

    private var stablePrimaryContent: Text {
        supportsTimedLyrics
            ? activeSynchronizedText
            : Text(verbatim: line.text)
    }

    private func lyricTextRenderer(
        at playbackTime: TimeInterval
    ) -> LyricGlowTextRenderer {
        LyricGlowTextRenderer(
            playbackTime: playbackTime,
            style: .init(
                glowRadius: glowRadius,
                glowOpacity: glowOpacity,
                glowsLongSyllablesOnly:
                    settings.lyricsGlowLongSyllablesOnly,
                longSyllableDurationThreshold:
                    settings.lyricsLongSyllableDurationThreshold,
                unplayedOpacity: 0.3,
                maximumUnplayedBlurRadius: maximumUnplayedBlurRadius,
                playedRise: playedRise,
                maximumLongSyllableScale: maximumLongSyllableScale,
                longSyllableExpansionPadding: longSyllableExpansionPadding
            ),
            layoutConfiguration: .init(
                width: timedLayoutWidth,
                centersLines: alignment == .center
            )
        )
    }

    private var primaryLayoutWidth: CGFloat? {
        supportsTimedLyrics ? timedLayoutWidth : layoutWidth
    }

    private var supportsTimedLyrics: Bool {
        (settings.lyricsWordByWord && line.isSyllableSynced)
            || (usesPseudoTiming && hasPseudoSyllables)
    }

    private var usesTimedLyrics: Bool {
        isPlaybackLine && supportsTimedLyrics
    }

    private var activeSynchronizedText: Text {
        line.isSyllableSynced
            ? synchronizedText
            : pseudoSynchronizedText
    }

    private var primaryFont: Font {
        .system(size: fontSize, weight: fontWeight.swiftUIWeight)
    }

    private var translationFontSize: CGFloat {
        max(
            CGFloat(settings.lyricsFontSize * settings.lyricsTranslationFontScale) * fontScale,
            13 * fontScale
        )
    }

    private var displaysTranslation: Bool {
        showsTranslation
            && settings.lyricsTranslationEnabled
            && line.translation != nil
    }

    private var glowRadius: CGFloat {
        guard settings.lyricsGlowEnabled else { return 0 }
        return CGFloat(
            Double(fontSize)
                * 0.34
                * settings.lyricsGlowIntensity
        )
    }

    private var glowOpacity: Double {
        guard settings.lyricsGlowEnabled else { return 0 }
        return min(settings.lyricsGlowIntensity * 0.9, 1)
    }

    private var maximumUnplayedBlurRadius: CGFloat {
        CGFloat(settings.lyricsBlurIntensity) * 0.55 * fontScale
    }

    private var playedRise: CGFloat {
        guard !accessibilityReduceMotion else { return 0 }
        return min(max(fontSize * 0.1, 1.5), 6)
    }

    private var maximumLongSyllableScale: CGFloat {
        accessibilityReduceMotion ? 1 : 1.08
    }

    private var longSyllableExpansionPadding: CGFloat {
        fontSize * (maximumLongSyllableScale - 1)
    }

    private var timedLayoutWidth: CGFloat? {
        guard let layoutWidth,
              let maximumScale = playbackScaleRange?.upperBound else {
            return layoutWidth
        }
        return layoutWidth / max(maximumScale, 1)
    }

    private func playbackScale(at playbackTime: TimeInterval) -> CGFloat {
        guard !accessibilityReduceMotion,
              let playbackScaleRange,
              let timedPlaybackRange else {
            return 1
        }

        let glowTailDuration = settings.lyricsGlowEnabled
            ? LyricGlowTextRenderer.glowTailDuration
            : 0
        let playbackScaleEndTime = timedPlaybackRange.upperBound
            + glowTailDuration
        let fullDuration = playbackScaleEndTime
            - timedPlaybackRange.lowerBound
        guard fullDuration > 0 else { return playbackScaleRange.upperBound }

        let minimumContinuationDuration = min(fullDuration * 0.35, 0.25)
        let maximumStartDelay = max(
            fullDuration - minimumContinuationDuration,
            0
        )
        let effectiveStartTime = timedPlaybackRange.lowerBound
            + min(max(playbackScaleStartDelay, 0), maximumStartDelay)
        let continuationDuration = playbackScaleEndTime
            - effectiveStartTime
        guard continuationDuration > 0 else {
            return playbackScaleRange.upperBound
        }

        let rawProgress = (playbackTime - effectiveStartTime)
            / continuationDuration
        let progress = min(max(rawProgress, 0), 1)
        let easedProgress = progress * progress * (3 - 2 * progress)
        return playbackScaleRange.lowerBound
            + (playbackScaleRange.upperBound - playbackScaleRange.lowerBound)
                * CGFloat(easedProgress)
    }
}
