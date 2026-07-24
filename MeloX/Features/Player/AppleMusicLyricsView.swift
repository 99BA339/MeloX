import SwiftUI

struct AppleMusicLyricsView: View {
    private static let bottomPreloadLineCount = 2
    private static let futureCascadeSafetyLineCount = 6
    nonisolated private static let expandedBottomDistanceScale: CGFloat = 0.68

    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @Environment(PlayerStore.self) private var player
    @Environment(AppSettings.self) private var settings

    let lyrics: [LyricLine]
    let errorMessage: String?
    let highlightedLyricID: LyricLine.ID?
    let isInterfaceHidden: Bool
    let bottomOverlayHeight: CGFloat
    let onToggleInterface: (() -> Void)?

    @State private var scrollPositionID: LyricLine.ID?
    @State private var isBrowsingLyrics = false
    @State private var browsingGeneration = 0
    @State private var playbackFocusRequestGeneration = 0
    @State private var isPreparingInitialFocus = true
    @State private var visualHighlightedLyricID: LyricLine.ID?
    @State private var visualCascadeFocusLyricID: LyricLine.ID?
    @State private var lyricFrameByID: [LyricLine.ID: CGRect] = [:]
    @State private var lyricMovementOffsetByID: [LyricLine.ID: CGFloat] = [:]
    @State private var lyricMovementAnimationByID: [
        LyricLine.ID: LyricMovementAnimationConfiguration
    ] = [:]
    @State private var lyricMovementTransition: LyricMovementTransition?
    @State private var retainedTopCascadeLyrics: [RetainedCascadeLyric] = []

    init(
        lyrics: [LyricLine],
        errorMessage: String?,
        highlightedLyricID: LyricLine.ID?,
        isInterfaceHidden: Bool = false,
        bottomOverlayHeight: CGFloat = 0,
        onToggleInterface: (() -> Void)? = nil
    ) {
        self.lyrics = lyrics
        self.errorMessage = errorMessage
        self.highlightedLyricID = highlightedLyricID
        self.isInterfaceHidden = isInterfaceHidden
        self.bottomOverlayHeight = bottomOverlayHeight
        self.onToggleInterface = onToggleInterface
        _scrollPositionID = State(initialValue: highlightedLyricID)
        _visualHighlightedLyricID = State(initialValue: highlightedLyricID)
        _visualCascadeFocusLyricID = State(initialValue: highlightedLyricID)
    }

    var body: some View {
        lyricsContent
    }

    @ViewBuilder
    private var lyricsContent: some View {
        if lyrics.isEmpty {
            if let errorMessage {
                ContentUnavailableView(
                    "暂无歌词",
                    systemImage: "quote.bubble",
                    description: Text(errorMessage)
                )
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(.rect)
                .onTapGesture {
                    onToggleInterface?()
                }
            } else {
                ProgressView("正在载入歌词")
                    .tint(.white)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(.rect)
                    .onTapGesture {
                        onToggleInterface?()
                    }
            }
        } else {
            let blurFocusLyricID = isBrowsingLyrics
                ? scrollPositionID
                : visualCascadeFocusLyricID ?? scrollPositionID ?? highlightedLyricID
            let focusNeighborIDs = lyricNeighborIDs(around: blurFocusLyricID)
            let focusEffectAnimation = lyricFocusEffectAnimation(
                for: visualHighlightedLyricID
            )
            let hasSyllableSyncedLyrics = lyrics.contains { $0.isSyllableSynced }
            let usesPseudoTiming = settings.lyricsPseudoWordByWord
                && !hasSyllableSyncedLyrics
            let showsTranslations = settings.lyricsTranslationEnabled
                && lyrics.contains { $0.translation != nil }
            let lineSpacing = CGFloat(settings.lyricsLineSpacing)
            let translationHeight = showsTranslations
                ? CGFloat(
                    settings.lyricsFontSize
                        * settings.lyricsTranslationFontScale
                        * 1.2
                ) + 2
                : 0
            let lyricStride = max(
                CGFloat(settings.lyricsFontSize) * 1.2
                    + translationHeight
                    + lineSpacing,
                1
            )
            let blurIntensity = CGFloat(settings.lyricsBlurIntensity)
            let distanceBlurScale = CGFloat(settings.lyricsDistanceBlurScale)
            let hiddenInterfaceBlurScale = CGFloat(
                settings.lyricsHiddenInterfaceBlurScale
            )
            let dimAmount = settings.lyricsDimAmount
            let currentLineScale = lyricsCurrentLineScale
            let glowOverflow = Self.lyricGlowOverflow(
                isEnabled: settings.lyricsGlowEnabled
                    && (
                        (settings.lyricsWordByWord && hasSyllableSyncedLyrics)
                            || usesPseudoTiming
                    ),
                fontSize: settings.lyricsFontSize,
                intensity: settings.lyricsGlowIntensity
            )

            GeometryReader { proxy in
                let focusPosition = lyricsFocusPosition(
                    for: proxy.size.height
                )
                let focusAnchorY = proxy.size.height * focusPosition
                let visibleViewportHeight = visibleLyricsViewportHeight(
                    for: proxy.size.height
                )
                let maskLocations = lyricsMaskLocations(
                    for: proxy.size.height
                )
                let lyricLayoutWidth = max(proxy.size.width / currentLineScale, 1)

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: CGFloat(settings.lyricsLineSpacing)) {
                        ForEach(lyrics) { line in
                            let isPlaybackLine = line.id == visualHighlightedLyricID
                            let isCascadeFocusLine = line.id == visualCascadeFocusLyricID
                            let isActualPlaybackLine = line.id == highlightedLyricID
                            let isPrecedingFocusLine = line.id == focusNeighborIDs.preceding
                            let isFollowingFocusLine = line.id == focusNeighborIDs.following
                            let isBrowsingFocus = isBrowsingLyrics && line.id == scrollPositionID
                            let isRetainedTopCascadeLine = retainedTopCascadeLyrics.contains {
                                $0.id == line.id
                            }
                            let movementOffset = lyricMovementOffsetByID[line.id, default: 0]
                            let movementAnimation = lyricMovementAnimation(
                                for: line.id
                            )
                            let focusBlurRadius = Self.lyricFocusBlurRadius(
                                intensity: blurIntensity,
                                isPrecedingFocusLine: isPrecedingFocusLine,
                                isFollowingFocusLine: isFollowingFocusLine
                            )
                            let focusScaleAnimation = lyricFocusScaleAnimation(
                                isFocused: isCascadeFocusLine
                            )

                            SynchronizedLyricText(
                                line: line,
                                isPlaybackLine: isPlaybackLine,
                                usesPseudoTiming: usesPseudoTiming,
                                fontSize: CGFloat(settings.lyricsFontSize),
                                fontWeight: settings.lyricsFontWeight,
                                showsTranslation: showsLyricTranslation(
                                    isFocusedLine: isCascadeFocusLine
                                ),
                                translationLayoutAnimation:
                                    lyricTranslationLayoutAnimation(),
                                translationVisibilityAnimation:
                                    lyricTranslationVisibilityAnimation(
                                        focusScaleAnimation: focusScaleAnimation
                                    ),
                                visualScale: isCascadeFocusLine ? currentLineScale : 1,
                                visualScaleAnimation: focusScaleAnimation,
                                layoutWidth: lyricLayoutWidth
                            )
                                .opacity(
                                    isRetainedTopCascadeLine
                                        ? 0
                                        : Self.lyricEmphasis(
                                            isPlaybackLine: isPlaybackLine,
                                            isBrowsingFocus: isBrowsingFocus,
                                            dimAmount: dimAmount
                                        )
                                )
                                .animation(
                                    focusEffectAnimation,
                                    value: isPlaybackLine
                                )
                                .contentShape(.rect)
                                .visualEffect { content, geometry in
                                    let frame = geometry.frame(in: .scrollView(axis: .vertical))
                                    let visualMidY = frame.midY + movementOffset
                                    let distance = Self.lyricVisualDistance(
                                        visualMidY: visualMidY,
                                        focusAnchorY: focusAnchorY,
                                        softensFollowingLyrics: isInterfaceHidden
                                    )
                                    let activeDistanceBlurScale = isInterfaceHidden
                                        ? hiddenInterfaceBlurScale
                                        : distanceBlurScale
                                    let bottomRevealOpacity = Self.lyricBottomRevealOpacity(
                                        frame: frame,
                                        movementOffset: movementOffset,
                                        viewportHeight: proxy.size.height
                                    )
                                    return content
                                        .blur(
                                            radius: Self.lyricDistanceBlurRadius(
                                                forPixelDistance: distance,
                                                lyricStride: lyricStride,
                                                intensity: blurIntensity
                                                    * activeDistanceBlurScale
                                            )
                                        )
                                        .opacity(
                                            Self.lyricOpacity(
                                                forPixelDistance: distance,
                                                lyricStride: lyricStride,
                                                dimAmount: dimAmount
                                            ) * bottomRevealOpacity
                                        )
                                        .offset(y: movementOffset)
                                }
                                .animation(
                                    movementAnimation,
                                    value: movementOffset
                                )
                                .blur(radius: focusBlurRadius)
                                .animation(focusEffectAnimation, value: focusBlurRadius)
                                .onGeometryChange(for: CGRect.self) { geometry in
                                    geometry.frame(in: .scrollView(axis: .vertical))
                                } action: { frame in
                                    lyricFrameByID[line.id] = frame
                                }
                                .gesture(lyricTapGesture(for: line))
                                .id(line.id)
                                .onDisappear {
                                    lyricFrameByID.removeValue(forKey: line.id)
                                }
                                .accessibilityLabel(
                                    line.accessibilityText(
                                        includingTranslation:
                                            settings.lyricsTranslationEnabled
                                                && showsLyricTranslation(
                                                    isFocusedLine:
                                                        isActualPlaybackLine
                                                )
                                    )
                                )
                                .accessibilityValue(
                                    lyricAccessibilityValue(
                                        isPlaybackLine: isActualPlaybackLine,
                                        isBrowsingFocus: isBrowsingFocus
                                    )
                                )
                                .accessibilityHint(settings.lyricsTapToSeek ? "双击跳转到这行歌词" : "歌词跳转已在设置中关闭")
                                .accessibilityAddTraits(settings.lyricsTapToSeek ? .isButton : [])
                                .accessibilityAction {
                                    seek(to: line)
                                }
                        }
                    }
                    .scrollTargetLayout()
                    .padding(.top, max(proxy.size.height * focusPosition, 40))
                    .padding(.bottom, max(proxy.size.height * (1 - focusPosition), 40))
                }
                .scrollIndicators(.hidden)
                .scrollClipDisabled()
                .scrollPosition(
                    id: $scrollPositionID,
                    anchor: UnitPoint(x: 0.5, y: focusPosition)
                )
                .transaction { transaction in
                    if isPreparingInitialFocus {
                        transaction.animation = nil
                    }
                }
                .overlay(alignment: .topLeading) {
                    retainedTopCascadeLyricsOverlay(
                        viewportSize: proxy.size,
                        lyricLayoutWidth: lyricLayoutWidth,
                        focusPosition: focusPosition,
                        lyricStride: lyricStride,
                        blurIntensity: blurIntensity,
                        distanceBlurScale: distanceBlurScale,
                        hiddenInterfaceBlurScale: hiddenInterfaceBlurScale,
                        dimAmount: dimAmount,
                        currentLineScale: currentLineScale,
                        usesPseudoTiming: usesPseudoTiming,
                        focusEffectAnimation: focusEffectAnimation
                    )
                }
                .mask {
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .black, location: maskLocations.topOpaque),
                            .init(color: .black, location: maskLocations.bottomOpaque),
                            .init(color: .clear, location: maskLocations.bottomClear),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(width: proxy.size.width + glowOverflow * 2)
                }
                .onScrollPhaseChange { _, newPhase in
                    switch newPhase {
                    case .tracking, .interacting:
                        browsingGeneration += 1
                        resetMovementOffsets()
                        isBrowsingLyrics = true
                    case .idle:
                        schedulePlaybackFollowing()
                    case .decelerating, .animating:
                        break
                    }
                }
                .onChange(of: highlightedLyricID) { _, newValue in
                    guard newValue == nil else { return }
                    visualHighlightedLyricID = nil
                    visualCascadeFocusLyricID = nil
                    lyricMovementOffsetByID.removeAll()
                    lyricMovementAnimationByID.removeAll()
                    lyricMovementTransition = nil
                    retainedTopCascadeLyrics.removeAll()
                }
                .onChange(of: player.seekRevision) { _, _ in
                    requestPlaybackFocus()
                }
                .onChange(of: player.isPlaying) { wasPlaying, isPlaying in
                    guard !wasPlaying, isPlaying else { return }
                    requestPlaybackFocus()
                }
                .onAppear {
                    synchronizeFocusIfNeeded()
                }
                .task(id: focusMovementTrigger) {
                    await cascadeMoveFocus(
                        to: highlightedLyricID,
                        viewportHeight: proxy.size.height,
                        visibleViewportHeight: visibleViewportHeight,
                        preloadLineCount: Self.bottomPreloadLineCount
                    )
                    guard !Task.isCancelled else { return }
                    isPreparingInitialFocus = false
                }
                .onDisappear {
                    browsingGeneration += 1
                    lyricFrameByID.removeAll()
                    lyricMovementOffsetByID.removeAll()
                    lyricMovementAnimationByID.removeAll()
                    lyricMovementTransition = nil
                    retainedTopCascadeLyrics.removeAll()
                }
            }
        }
    }

    @ViewBuilder
    private func retainedTopCascadeLyricsOverlay(
        viewportSize: CGSize,
        lyricLayoutWidth: CGFloat,
        focusPosition: CGFloat,
        lyricStride: CGFloat,
        blurIntensity: CGFloat,
        distanceBlurScale: CGFloat,
        hiddenInterfaceBlurScale: CGFloat,
        dimAmount: Double,
        currentLineScale: CGFloat,
        usesPseudoTiming: Bool,
        focusEffectAnimation: Animation?
    ) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(retainedTopCascadeLyrics) { retainedLyric in
                if let line = lyrics.first(where: { $0.id == retainedLyric.id }) {
                    let isPlaybackLine = line.id == visualHighlightedLyricID
                    let isCascadeFocusLine = line.id == visualCascadeFocusLyricID
                    let isBrowsingFocus = isBrowsingLyrics && line.id == scrollPositionID
                    let blurFocusLyricID = isBrowsingLyrics
                        ? scrollPositionID
                        : visualCascadeFocusLyricID ?? scrollPositionID ?? highlightedLyricID
                    let focusNeighborIDs = lyricNeighborIDs(around: blurFocusLyricID)
                    let movementOffset = lyricMovementOffsetByID[
                        line.id,
                        default: retainedLyric.movementDistance
                    ]
                    let movementAnimation = lyricMovementAnimation(for: line.id)
                    let visualOffset = movementOffset - retainedLyric.movementDistance
                    let visualMidY = retainedLyric.frame.midY + visualOffset
                    let focusAnchorY = viewportSize.height * focusPosition
                    let distance = Self.lyricVisualDistance(
                        visualMidY: visualMidY,
                        focusAnchorY: focusAnchorY,
                        softensFollowingLyrics: isInterfaceHidden
                    )
                    let activeDistanceBlurScale = isInterfaceHidden
                        ? hiddenInterfaceBlurScale
                        : distanceBlurScale
                    let focusBlurRadius = Self.lyricFocusBlurRadius(
                        intensity: blurIntensity,
                        isPrecedingFocusLine: line.id == focusNeighborIDs.preceding,
                        isFollowingFocusLine: line.id == focusNeighborIDs.following
                    )
                    let focusScaleAnimation = lyricFocusScaleAnimation(
                        isFocused: isCascadeFocusLine
                    )

                    SynchronizedLyricText(
                        line: line,
                        isPlaybackLine: isPlaybackLine,
                        usesPseudoTiming: usesPseudoTiming,
                        fontSize: CGFloat(settings.lyricsFontSize),
                        fontWeight: settings.lyricsFontWeight,
                        showsTranslation: showsLyricTranslation(
                            isFocusedLine: isCascadeFocusLine
                        ),
                        translationLayoutAnimation:
                            lyricTranslationLayoutAnimation(),
                        translationVisibilityAnimation:
                            lyricTranslationVisibilityAnimation(
                                focusScaleAnimation: focusScaleAnimation
                            ),
                        visualScale: isCascadeFocusLine ? currentLineScale : 1,
                        visualScaleAnimation: focusScaleAnimation,
                        layoutWidth: lyricLayoutWidth
                    )
                    .opacity(
                        Self.lyricEmphasis(
                            isPlaybackLine: isPlaybackLine,
                            isBrowsingFocus: isBrowsingFocus,
                            dimAmount: dimAmount
                        )
                    )
                    .animation(focusEffectAnimation, value: isPlaybackLine)
                    .blur(
                        radius: Self.lyricDistanceBlurRadius(
                            forPixelDistance: distance,
                            lyricStride: lyricStride,
                            intensity: blurIntensity * activeDistanceBlurScale
                        )
                    )
                    .opacity(
                        Self.lyricOpacity(
                            forPixelDistance: distance,
                            lyricStride: lyricStride,
                            dimAmount: dimAmount
                        )
                    )
                    .blur(radius: focusBlurRadius)
                    .animation(focusEffectAnimation, value: focusBlurRadius)
                    .frame(width: viewportSize.width, alignment: .leading)
                    .offset(
                        y: retainedLyric.frame.minY + visualOffset
                    )
                    .animation(
                        movementAnimation,
                        value: movementOffset
                    )
                }
            }
        }
        .frame(
            width: viewportSize.width,
            height: viewportSize.height,
            alignment: .topLeading
        )
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var preferredLyricsFocusPosition: CGFloat {
        CGFloat(
            min(
                max(
                    settings.lyricsFocusPosition,
                    AppSettings.lyricsFocusPositionRange.lowerBound
                ),
                AppSettings.lyricsFocusPositionRange.upperBound
            )
        )
    }

    private func lyricsFocusPosition(for viewportHeight: CGFloat) -> CGFloat {
        guard viewportHeight > 0 else { return preferredLyricsFocusPosition }
        return preferredLyricsFocusPosition
            * referenceLyricsViewportHeight(for: viewportHeight)
            / viewportHeight
    }

    private func referenceLyricsViewportHeight(
        for viewportHeight: CGFloat
    ) -> CGFloat {
        let overlayHeight = min(
            max(bottomOverlayHeight, 0),
            max(viewportHeight - 1, 0)
        )
        return max(viewportHeight - overlayHeight, 1)
    }

    private func visibleLyricsViewportHeight(
        for viewportHeight: CGFloat
    ) -> CGFloat {
        isInterfaceHidden
            ? viewportHeight
            : referenceLyricsViewportHeight(for: viewportHeight)
    }

    private func lyricsMaskLocations(
        for viewportHeight: CGFloat
    ) -> (
        topOpaque: CGFloat,
        bottomOpaque: CGFloat,
        bottomClear: CGFloat
    ) {
        guard viewportHeight > 0 else { return (0.08, 0.84, 1) }
        let referenceRatio = referenceLyricsViewportHeight(for: viewportHeight)
            / viewportHeight
        return (
            topOpaque: 0.08 * referenceRatio,
            bottomOpaque: isInterfaceHidden ? 0.92 : 0.84 * referenceRatio,
            bottomClear: isInterfaceHidden ? 1 : referenceRatio
        )
    }

    private var lyricsCurrentLineScale: CGFloat {
        CGFloat(
            min(
                max(
                    settings.lyricsCurrentLineScale,
                    AppSettings.lyricsCurrentLineScaleRange.lowerBound
                ),
                AppSettings.lyricsCurrentLineScaleRange.upperBound
            )
        )
    }

    private func lyricFocusScaleAnimation(
        isFocused: Bool
    ) -> Animation? {
        guard !accessibilityReduceMotion else { return nil }

        let duration = lyricFocusScaleDuration()
        guard isFocused, settings.lyricsFocusScaleBounceEnabled else {
            return .smooth(duration: duration)
        }

        let bounce = min(
            max(
                settings.lyricsFocusScaleBounce,
                AppSettings.lyricsFocusScaleBounceRange.lowerBound
            ),
            AppSettings.lyricsFocusScaleBounceRange.upperBound
        )
        return lyricSpringAnimation(
            duration: duration,
            bounce: bounce
        )
    }

    private func showsLyricTranslation(isFocusedLine: Bool) -> Bool {
        switch settings.lyricsTranslationDisplayMode {
        case .focusedLine:
            isFocusedLine
        case .allLines:
            true
        }
    }

    private func lyricTranslationVisibilityAnimation(
        focusScaleAnimation: Animation?
    ) -> Animation? {
        guard !accessibilityReduceMotion else { return nil }
        if settings.lyricsTranslationDisplayMode == .focusedLine {
            return focusScaleAnimation
        }
        let duration = min(
            max(settings.lyricsFocusCascadeDuration * 0.7, 0.16),
            0.32
        )
        return .smooth(duration: duration)
    }

    private func lyricTranslationLayoutAnimation() -> Animation? {
        guard !accessibilityReduceMotion else { return nil }
        let duration: TimeInterval
        if settings.lyricsTranslationDisplayMode == .focusedLine {
            duration = lyricFocusScaleDuration()
        } else {
            duration = min(
                max(settings.lyricsFocusCascadeDuration * 0.7, 0.16),
                0.32
            )
        }
        return .smooth(duration: duration)
    }

    private func lyricFocusScaleDuration() -> TimeInterval {
        if settings.lyricsFocusScaleBounceEnabled {
            return min(
                max(
                    settings.lyricsFocusScaleBounceDuration,
                    AppSettings.lyricsFocusScaleBounceDurationRange.lowerBound
                ),
                AppSettings.lyricsFocusScaleBounceDurationRange.upperBound
            )
        }
        return min(
            max(
                LyricPlaybackTimeline.focusAnimationDuration(
                    for: highlightedLyricID,
                    in: lyrics
                ),
                0.28
            ),
            0.42
        )
    }

    private func lyricSpringAnimation(
        duration: TimeInterval,
        bounce: Double
    ) -> Animation {
        .spring(
            duration: duration,
            bounce: bounce,
            blendDuration: min(max(duration * 0.22, 0.06), 0.14)
        )
    }

    private func lyricSpringSettlingTailDuration(
        animationDuration: TimeInterval,
        bounce: Double
    ) -> TimeInterval {
        guard bounce > 0 else { return 0 }
        return min(
            max(animationDuration * bounce * 0.25, 1.0 / 60.0),
            0.12
        )
    }

    private var focusMovementTrigger: LyricFocusMovementTrigger {
        LyricFocusMovementTrigger(
            highlightedLyricID: highlightedLyricID,
            isBrowsingLyrics: isBrowsingLyrics,
            playbackFocusRequestGeneration: playbackFocusRequestGeneration
        )
    }

    private func lyricFocusEffectAnimation(
        for highlightedLyricID: LyricLine.ID?
    ) -> Animation? {
        guard !accessibilityReduceMotion else { return nil }
        let movementDuration = LyricPlaybackTimeline.focusAnimationDuration(
            for: highlightedLyricID,
            in: lyrics
        )
        return .easeInOut(duration: max(movementDuration, 0.2))
    }

    private var lyricsFocusColorLeadTime: TimeInterval {
        min(
            max(
                settings.lyricsFocusColorLeadTime,
                AppSettings.lyricsFocusColorLeadTimeRange.lowerBound
            ),
            AppSettings.lyricsFocusColorLeadTimeRange.upperBound
        )
    }

    private func remainingFocusDuration(
        for highlightedLyricID: LyricLine.ID
    ) -> TimeInterval? {
        guard player.isPlaying else { return nil }
        return LyricPlaybackTimeline.remainingFocusDuration(
            for: highlightedLyricID,
            at: player.estimatedProgress() + settings.lyricsAdvanceTime,
            in: lyrics
        )
    }

    private func waitForLyricFrame(
        for id: LyricLine.ID
    ) async -> CGRect? {
        for attempt in 0..<30 {
            if let frame = lyricFrameByID[id] {
                return frame
            }
            guard !Task.isCancelled, attempt < 29 else { return nil }
            do {
                try await Task.sleep(for: .milliseconds(16))
            } catch {
                return nil
            }
        }
        return nil
    }

    private func waitForPreparedFocus(
        id: LyricLine.ID,
        viewportAnchorY: CGFloat,
        focusPosition: CGFloat
    ) async -> Bool {
        for attempt in 0..<30 {
            if let frame = lyricFrameByID[id] {
                let preparedAnchorY = frame.minY
                    + frame.height * focusPosition
                if abs(preparedAnchorY - viewportAnchorY) <= 2 {
                    return true
                }
            }
            guard !Task.isCancelled, attempt < 29 else { return false }
            do {
                try await Task.sleep(for: .milliseconds(16))
            } catch {
                return false
            }
        }
        return false
    }

    private func cascadeMoveFocus(
        to highlightedLyricID: LyricLine.ID?,
        viewportHeight: CGFloat,
        visibleViewportHeight: CGFloat,
        preloadLineCount: Int
    ) async {
        guard let highlightedLyricID else {
            resetMovementOffsets()
            guard let firstLyricID = lyrics.first?.id else { return }
            await ensureFocusAlignment(
                to: firstLyricID,
                viewportHeight: viewportHeight,
                animated: false
            )
            return
        }
        guard !isBrowsingLyrics else {
            resetMovementOffsets()
            visualHighlightedLyricID = highlightedLyricID
            visualCascadeFocusLyricID = highlightedLyricID
            return
        }
        let movementFocusLyricID = lyricMovementTransition?.focusID
            ?? visualCascadeFocusLyricID
            ?? scrollPositionID
        guard movementFocusLyricID != highlightedLyricID else {
            visualHighlightedLyricID = highlightedLyricID
            visualCascadeFocusLyricID = highlightedLyricID
            await ensureFocusAlignment(
                to: highlightedLyricID,
                viewportHeight: viewportHeight,
                animated: !isPreparingInitialFocus
            )
            return
        }
        guard isAdjacentFocusTransition(
            from: movementFocusLyricID,
            to: highlightedLyricID
        ) else {
            await moveFocusWithoutCascade(
                to: highlightedLyricID,
                viewportHeight: viewportHeight
            )
            return
        }

        guard !accessibilityReduceMotion,
              settings.lyricsFocusCascadeDelay > 0 else {
            await moveFocusWithoutCascade(
                to: highlightedLyricID,
                viewportHeight: viewportHeight
            )
            return
        }
        let remainingDurationAtTransition = remainingFocusDuration(
            for: highlightedLyricID
        )
        guard let nextFocusFrame = await waitForLyricFrame(
            for: highlightedLyricID
        ) else {
            guard !Task.isCancelled else { return }
            await moveFocusWithoutCascade(
                to: highlightedLyricID,
                viewportHeight: viewportHeight
            )
            return
        }

        let focusPosition = lyricsFocusPosition(for: viewportHeight)
        let viewportAnchorY = viewportHeight * focusPosition
        let nextFocusAnchorY = nextFocusFrame.minY
            + nextFocusFrame.height * focusPosition
        let movementDistance = nextFocusAnchorY - viewportAnchorY
        guard abs(movementDistance) > 0.5 else {
            completeCascadeMovement(to: highlightedLyricID)
            return
        }

        let carriedMovementOffsets = lyricMovementTransition?
            .presentationOffsets(at: .now) ?? [:]
        let initialVisibleIDs = lyricFrameByID
            .filter { entry in
                let frame = entry.value
                let carriedOffset = carriedMovementOffsets[
                    entry.key,
                    default: 0
                ]
                return frame.maxY + carriedOffset >= 0
                    && frame.minY + carriedOffset <= visibleViewportHeight
            }
            .sorted { left, right in
                let leftMinY = left.value.minY
                    + carriedMovementOffsets[left.key, default: 0]
                let rightMinY = right.value.minY
                    + carriedMovementOffsets[right.key, default: 0]
                return leftMinY < rightMinY
            }
            .map(\.key)
        let baseAnimationDuration = LyricPlaybackTimeline.focusAnimationDuration(
            for: highlightedLyricID,
            in: lyrics
        )
        let cascadeAnimationDuration = LyricPlaybackTimeline.focusCascadeAnimationDuration(
            baseDuration: baseAnimationDuration,
            preferredDuration: settings.lyricsFocusCascadeDuration
        )
        let prefersCascadeBounce = settings.lyricsFocusCascadeBounceEnabled
        let focusColorLeadTime = lyricsFocusColorLeadTime
        let retainedTopLyrics: [RetainedCascadeLyric] = initialVisibleIDs.compactMap { id in
            guard movementDistance > 0,
                  let frame = lyricFrameByID[id],
                  frame.minY < movementDistance else {
                return nil
            }
            return RetainedCascadeLyric(
                id: id,
                frame: frame,
                movementDistance: movementDistance
            )
        }
        let preparedMovementOffsets = Dictionary(
            uniqueKeysWithValues: lyrics.map { line in
                (
                    line.id,
                    movementDistance
                        + carriedMovementOffsets[line.id, default: 0]
                )
            }
        )
        let preparedMovementTransition = LyricMovementTransition(
            focusID: highlightedLyricID,
            initialOffsetsByID: preparedMovementOffsets
        )

        var preparationTransaction = Transaction(animation: nil)
        preparationTransaction.disablesAnimations = true
        withTransaction(preparationTransaction) {
            retainedTopCascadeLyrics = retainedTopLyrics
            lyricMovementAnimationByID.removeAll()
            lyricMovementOffsetByID = preparedMovementOffsets
            lyricMovementTransition = preparedMovementTransition
            scrollPositionID = highlightedLyricID
        }

        let destinationIsPrepared = await waitForPreparedFocus(
            id: highlightedLyricID,
            viewportAnchorY: viewportAnchorY,
            focusPosition: focusPosition
        )
        guard !Task.isCancelled else { return }
        guard destinationIsPrepared else {
            completeCascadeMovement(to: highlightedLyricID)
            await ensureFocusAlignment(
                to: highlightedLyricID,
                viewportHeight: viewportHeight,
                animated: false
            )
            return
        }

        let destinationVisibleIDs = lyricFrameByID
            .filter { entry in
                let frame = entry.value
                return frame.maxY >= 0 && frame.minY <= visibleViewportHeight
            }
            .sorted { left, right in
                left.value.minY < right.value.minY
            }
            .map(\.key)
        let lyricIndexByID = Dictionary(
            uniqueKeysWithValues: lyrics.enumerated().map { index, line in
                (line.id, index)
            }
        )
        guard let highlightedIndex = lyricIndexByID[highlightedLyricID] else {
            completeCascadeMovement(to: highlightedLyricID)
            return
        }
        var movingIDSet = Set(initialVisibleIDs)
        movingIDSet.formUnion(destinationVisibleIDs)
        let guaranteedFutureEndIndex = min(
            highlightedIndex + Self.futureCascadeSafetyLineCount + 1,
            lyrics.endIndex
        )
        for index in highlightedIndex..<guaranteedFutureEndIndex {
            movingIDSet.insert(lyrics[index].id)
        }
        if preloadLineCount > 0,
           let bottomVisibleIndex = destinationVisibleIDs
            .compactMap({ lyricIndexByID[$0] })
            .max() {
            let preloadStartIndex = bottomVisibleIndex + 1
            let preloadEndIndex = min(
                preloadStartIndex + preloadLineCount,
                lyrics.endIndex
            )
            if preloadStartIndex < preloadEndIndex {
                for index in preloadStartIndex..<preloadEndIndex {
                    movingIDSet.insert(lyrics[index].id)
                }
            }
        }
        let movingIndexes = movingIDSet.compactMap { lyricIndexByID[$0] }
        guard let firstMovingIndex = movingIndexes.min(),
              let lastMovingIndex = movingIndexes.max() else {
            completeCascadeMovement(to: highlightedLyricID)
            return
        }
        let orderedMovingIDs = lyrics[firstMovingIndex...lastMovingIndex]
            .map(\.id)
        guard orderedMovingIDs.count > 1 else {
            completeCascadeMovement(to: highlightedLyricID)
            return
        }
        let movementOrderByID = Dictionary(
            uniqueKeysWithValues: orderedMovingIDs.map { id in
                let lineIndex = lyricIndexByID[id] ?? highlightedIndex
                let lineOrder = max(
                    lineIndex - highlightedIndex,
                    0
                )
                return (id, lineOrder)
            }
        )
        let maximumLineOrder = movementOrderByID.values.max() ?? 0
        guard let cascadeTiming = LyricPlaybackTimeline.focusCascadeTiming(
            maximumLineOrder: maximumLineOrder,
            preferredDurationOffsetPerLine:
                settings.lyricsFocusCascadeDelay,
            preferredDurationOffsetIncreasePerLine:
                settings.lyricsFocusCascadeDelayIncrease,
            focusColorLeadTime: focusColorLeadTime,
            baseAnimationDuration: baseAnimationDuration,
            preferredAnimationDuration: cascadeAnimationDuration,
            prefersBounce: prefersCascadeBounce,
            snapThreshold: settings.lyricsFocusSnapThreshold,
            remainingDuration: remainingDurationAtTransition
        ) else {
            completeCascadeMovement(to: highlightedLyricID)
            return
        }
        await animatePreparedCascade(
            orderedMovingIDs,
            to: highlightedLyricID,
            movementOrderByID: movementOrderByID,
            cascadeTiming: cascadeTiming,
            focusColorLeadTime: focusColorLeadTime,
            transitionID: preparedMovementTransition.id
        )
    }

    private func animatePreparedCascade(
        _ orderedMovingIDs: [LyricLine.ID],
        to highlightedLyricID: LyricLine.ID,
        movementOrderByID: [LyricLine.ID: Int],
        cascadeTiming: LyricFocusCascadeTiming,
        focusColorLeadTime: TimeInterval,
        transitionID: UUID
    ) async {
        let animationDuration = cascadeTiming.animationDuration
        let usesBounce = cascadeTiming.usesBounce
        let movementAnimations = Dictionary(
            uniqueKeysWithValues: orderedMovingIDs.map { id in
                let lineOrder = movementOrderByID[id, default: 0]
                let durationOffset = cascadeTiming.durationOffset(
                    for: lineOrder
                )
                return (
                    id,
                    LyricMovementAnimationConfiguration(
                        duration: animationDuration + durationOffset,
                        usesBounce: usesBounce,
                        bounce: settings.lyricsFocusCascadeBounce
                    )
                )
            }
        )
        let longestMovementDuration = movementAnimations.values
            .map(\.duration)
            .max() ?? animationDuration
        var destinationOffsets = lyricMovementOffsetByID
        for id in orderedMovingIDs {
            destinationOffsets[id] = 0
        }

        var configurationTransaction = Transaction(animation: nil)
        configurationTransaction.disablesAnimations = true
        withTransaction(configurationTransaction) {
            lyricMovementAnimationByID = movementAnimations
        }
        do {
            try await Task.sleep(for: .milliseconds(16))
        } catch {
            return
        }
        guard !Task.isCancelled,
              lyricMovementTransition?.id == transitionID else { return }

        if focusColorLeadTime >= 0 {
            startFocusColorTransition(to: highlightedLyricID)
        }
        if focusColorLeadTime > 0 {
            do {
                try await Task.sleep(for: .seconds(focusColorLeadTime))
            } catch {
                return
            }
        }
        guard !Task.isCancelled,
              let preparedTransition = lyricMovementTransition,
              preparedTransition.id == transitionID else { return }

        lyricMovementTransition = preparedTransition.starting(
            with: movementAnimations,
            at: .now
        )
        visualCascadeFocusLyricID = highlightedLyricID
        lyricMovementOffsetByID = destinationOffsets

        let focusColorDelayAfterMovement = max(-focusColorLeadTime, 0)
        if focusColorDelayAfterMovement > 0 {
            do {
                try await Task.sleep(
                    for: .seconds(focusColorDelayAfterMovement)
                )
            } catch {
                return
            }
            guard !Task.isCancelled,
                  lyricMovementTransition?.id == transitionID else { return }
            startFocusColorTransition(to: highlightedLyricID)
        }

        let totalMovementWait = max(
            longestMovementDuration,
            focusColorDelayAfterMovement + animationDuration
        ) + (
            usesBounce
                ? lyricSpringSettlingTailDuration(
                    animationDuration: longestMovementDuration,
                    bounce: settings.lyricsFocusCascadeBounce
                )
                : 0
        )
        let remainingMovementWait =
            totalMovementWait - focusColorDelayAfterMovement
        if remainingMovementWait > 0 {
            do {
                try await Task.sleep(
                    for: .seconds(remainingMovementWait)
                )
            } catch {
                return
            }
        }
        guard !Task.isCancelled,
              lyricMovementTransition?.id == transitionID else { return }
        completeCascadeMovement(to: highlightedLyricID)
    }

    private func lyricMovementAnimation(
        for id: LyricLine.ID
    ) -> Animation? {
        guard !accessibilityReduceMotion,
              let configuration = lyricMovementAnimationByID[id] else {
            return nil
        }
        if configuration.usesBounce {
            return lyricSpringAnimation(
                duration: configuration.duration,
                bounce: configuration.bounce
            )
        }
        return .smooth(duration: configuration.duration)
    }

    private func startFocusColorTransition(
        to highlightedLyricID: LyricLine.ID
    ) {
        withAnimation(lyricFocusEffectAnimation(for: highlightedLyricID)) {
            visualHighlightedLyricID = highlightedLyricID
        }
    }

    private func isAdjacentFocusTransition(
        from currentID: LyricLine.ID?,
        to nextID: LyricLine.ID
    ) -> Bool {
        guard let currentID,
              let currentIndex = lyrics.firstIndex(where: { $0.id == currentID }),
              let nextIndex = lyrics.firstIndex(where: { $0.id == nextID }) else {
            return false
        }
        return abs(nextIndex - currentIndex) == 1
    }

    private func moveFocusWithoutCascade(
        to id: LyricLine.ID,
        viewportHeight: CGFloat
    ) async {
        resetMovementOffsets()
        await ensureFocusAlignment(
            to: id,
            viewportHeight: viewportHeight,
            animated: true
        )
        await Task.yield()
        guard !Task.isCancelled else { return }
        withAnimation(
            accessibilityReduceMotion
                ? nil
                : .easeInOut(
                    duration: LyricPlaybackTimeline.focusAnimationDuration(
                        for: id,
                        in: lyrics
                    )
                )
        ) {
            visualHighlightedLyricID = id
            visualCascadeFocusLyricID = id
        }
    }

    private func completeCascadeMovement(to id: LyricLine.ID) {
        var transaction = Transaction(animation: nil)
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            scrollPositionID = id
            visualHighlightedLyricID = id
            visualCascadeFocusLyricID = id
            lyricMovementOffsetByID.removeAll()
            lyricMovementAnimationByID.removeAll()
            lyricMovementTransition = nil
            retainedTopCascadeLyrics.removeAll()
        }
    }

    private func resetMovementOffsets() {
        var transaction = Transaction(animation: nil)
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            lyricMovementOffsetByID.removeAll()
            lyricMovementAnimationByID.removeAll()
            lyricMovementTransition = nil
            retainedTopCascadeLyrics.removeAll()
        }
    }

    private func lyricNeighborIDs(
        around focusedLyricID: LyricLine.ID?
    ) -> (
        preceding: LyricLine.ID?,
        following: LyricLine.ID?
    ) {
        guard let focusedLyricID,
              let focusIndex = lyrics.firstIndex(where: { $0.id == focusedLyricID }) else {
            return (nil, nil)
        }

        let precedingID = focusIndex > lyrics.startIndex
            ? lyrics[lyrics.index(before: focusIndex)].id
            : nil
        let followingIndex = lyrics.index(after: focusIndex)
        let followingID = followingIndex < lyrics.endIndex
            ? lyrics[followingIndex].id
            : nil
        return (precedingID, followingID)
    }

    private func lyricAccessibilityValue(
        isPlaybackLine: Bool,
        isBrowsingFocus: Bool
    ) -> String {
        switch (isPlaybackLine, isBrowsingFocus) {
        case (true, true): "当前播放，浏览焦点"
        case (true, false): "当前播放"
        case (false, true): "浏览焦点"
        case (false, false): ""
        }
    }

    nonisolated private static func lyricDistanceBlurRadius(
        forPixelDistance distance: CGFloat,
        lyricStride: CGFloat,
        intensity: CGFloat
    ) -> CGFloat {
        let lineDistance = distance / lyricStride
        let blurProgress = max(lineDistance - 1.35, 0)
        let baseRadius = min(blurProgress * 3.1, 10)
        return baseRadius * intensity
    }

    nonisolated private static func lyricVisualDistance(
        visualMidY: CGFloat,
        focusAnchorY: CGFloat,
        softensFollowingLyrics: Bool
    ) -> CGFloat {
        let signedDistance = visualMidY - focusAnchorY
        guard softensFollowingLyrics, signedDistance > 0 else {
            return abs(signedDistance)
        }
        return signedDistance * expandedBottomDistanceScale
    }

    nonisolated private static func lyricFocusBlurRadius(
        intensity: CGFloat,
        isPrecedingFocusLine: Bool,
        isFollowingFocusLine: Bool
    ) -> CGFloat {
        let precedingLineRadius: CGFloat = isPrecedingFocusLine ? 0.9 : 0
        let followingLineRadius: CGFloat = isFollowingFocusLine ? 0.55 : 0
        return (precedingLineRadius + followingLineRadius) * intensity
    }

    nonisolated private static func lyricOpacity(
        forPixelDistance distance: CGFloat,
        lyricStride: CGFloat,
        dimAmount: Double
    ) -> Double {
        let lineDistance = Double(distance / lyricStride)
        let baseOpacity: Double
        switch lineDistance {
        case ...1:
            baseOpacity = 1 - lineDistance * 0.44
        case ...2:
            baseOpacity = 0.56 - (lineDistance - 1) * 0.22
        default:
            baseOpacity = max(0.12, 0.34 - (lineDistance - 2) * 0.07)
        }
        return 1 - (1 - baseOpacity) * dimAmount
    }

    nonisolated private static func lyricBottomRevealOpacity(
        frame: CGRect,
        movementOffset: CGFloat,
        viewportHeight: CGFloat
    ) -> Double {
        let visualMinY = frame.minY + movementOffset
        let revealDistance = min(max(frame.height * 0.8, 32), 72)
        let progress = (viewportHeight - visualMinY) / revealDistance
        return Double(min(max(progress, 0), 1))
    }

    nonisolated private static func lyricEmphasis(
        isPlaybackLine: Bool,
        isBrowsingFocus: Bool,
        dimAmount: Double
    ) -> Double {
        guard !isPlaybackLine else { return 1 }
        let baseOpacity = isBrowsingFocus ? 0.7 : 0.52
        return 1 - (1 - baseOpacity) * dimAmount
    }

    nonisolated private static func lyricGlowOverflow(
        isEnabled: Bool,
        fontSize: Double,
        intensity: Double
    ) -> CGFloat {
        guard isEnabled else { return 0 }
        return CGFloat(min(max(fontSize * intensity * 0.75, 16), 32))
    }

    private func schedulePlaybackFollowing() {
        guard isBrowsingLyrics, settings.lyricsAutoFollow else { return }
        let generation = browsingGeneration
        let delay = settings.lyricsFollowDelay

        Task { @MainActor in
            do {
                try await Task.sleep(for: .seconds(delay))
            } catch {
                return
            }
            guard generation == browsingGeneration else { return }
            isBrowsingLyrics = false
        }
    }

    private func requestPlaybackFocus() {
        browsingGeneration += 1
        isBrowsingLyrics = false
        playbackFocusRequestGeneration += 1
    }

    private func synchronizeFocusIfNeeded() {
        let existingFocusIsValid = scrollPositionID.map { focusedID in
            lyrics.contains { $0.id == focusedID }
        } ?? false
        guard !existingFocusIsValid else { return }

        guard let initialID = highlightedLyricID ?? lyrics.first?.id else { return }
        moveFocus(to: initialID, animated: false)
    }

    private func seek(to line: LyricLine) {
        guard settings.lyricsTapToSeek else { return }
        browsingGeneration += 1
        isBrowsingLyrics = false
        resetMovementOffsets()
        moveFocus(to: line.id, animated: true)
        player.seek(to: line.time)
    }

    private func lyricTapGesture(for line: LyricLine) -> some Gesture {
        TapGesture(count: 2)
            .exclusively(before: TapGesture(count: 1))
            .onEnded { gesture in
                switch gesture {
                case .first:
                    seek(to: line)
                case .second:
                    onToggleInterface?()
                }
            }
    }

    private func moveFocus(to id: LyricLine.ID, animated: Bool) {
        let update = {
            scrollPositionID = id
        }

        if animated, !accessibilityReduceMotion {
            withAnimation(
                .smooth(
                    duration: LyricPlaybackTimeline.focusAnimationDuration(
                        for: id,
                        in: lyrics
                    )
                ),
                update
            )
        } else {
            update()
        }
    }

    private func ensureFocusAlignment(
        to id: LyricLine.ID,
        viewportHeight: CGFloat,
        animated: Bool
    ) async {
        let focusPosition = lyricsFocusPosition(for: viewportHeight)
        let viewportAnchorY = viewportHeight * focusPosition

        if let frame = lyricFrameByID[id] {
            let currentAnchorY = frame.minY + frame.height * focusPosition
            if abs(currentAnchorY - viewportAnchorY) <= 2 {
                return
            }
        }

        for attempt in 0..<3 {
            guard !Task.isCancelled else { return }

            if scrollPositionID == id || attempt > 0 {
                var resetTransaction = Transaction(animation: nil)
                resetTransaction.disablesAnimations = true
                withTransaction(resetTransaction) {
                    scrollPositionID = nil
                }
                await Task.yield()
                guard !Task.isCancelled else { return }
            }

            moveFocus(to: id, animated: animated && attempt == 0)
            let isAligned = await waitForPreparedFocus(
                id: id,
                viewportAnchorY: viewportAnchorY,
                focusPosition: focusPosition
            )
            if isAligned {
                return
            }
        }
    }
}

private struct LyricFocusMovementTrigger: Hashable {
    let highlightedLyricID: LyricLine.ID?
    let isBrowsingLyrics: Bool
    let playbackFocusRequestGeneration: Int
}

private struct RetainedCascadeLyric: Identifiable, Equatable {
    let id: LyricLine.ID
    let frame: CGRect
    let movementDistance: CGFloat
}
