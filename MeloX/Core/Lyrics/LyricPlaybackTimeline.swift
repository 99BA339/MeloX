import Foundation

struct LyricPlaybackPosition: Equatable {
    let highlightedLyricID: LyricLine.ID?
    let nextTransitionTime: TimeInterval?
}

struct LyricFocusCascadeTiming: Equatable {
    let delayPerLine: TimeInterval
    let delayIncreasePerLine: TimeInterval
    let animationDuration: TimeInterval
    let usesBounce: Bool
}

enum LyricPlaybackTimeline {
    static func position(
        at playbackTime: TimeInterval,
        in lyrics: [LyricLine]
    ) -> LyricPlaybackPosition {
        guard !lyrics.isEmpty else {
            return LyricPlaybackPosition(
                highlightedLyricID: nil,
                nextTransitionTime: nil
            )
        }

        var lowerBound = lyrics.startIndex
        var upperBound = lyrics.endIndex
        while lowerBound < upperBound {
            let middleIndex = lowerBound + (upperBound - lowerBound) / 2
            if lyrics[middleIndex].time <= playbackTime {
                lowerBound = middleIndex + 1
            } else {
                upperBound = middleIndex
            }
        }

        let highlightedLyricID = lowerBound > lyrics.startIndex
            ? lyrics[lyrics.index(before: lowerBound)].id
            : nil
        let nextTransitionTime = lowerBound < lyrics.endIndex
            ? lyrics[lowerBound].time
            : nil
        return LyricPlaybackPosition(
            highlightedLyricID: highlightedLyricID,
            nextTransitionTime: nextTransitionTime
        )
    }

    static func focusAnimationDuration(
        for highlightedLyricID: LyricLine.ID?,
        in lyrics: [LyricLine]
    ) -> TimeInterval {
        guard let availableDuration = availableFocusDuration(
            for: highlightedLyricID,
            in: lyrics
        ) else {
            return 0.34
        }

        return min(max(availableDuration * 0.35, 0.05), 0.34)
    }

    static func focusCascadeAnimationDuration(
        baseDuration: TimeInterval,
        preferredDuration: TimeInterval
    ) -> TimeInterval {
        let duration = max(baseDuration, 0)
        let configuredDuration = preferredDuration.isFinite
            ? max(preferredDuration, 0)
            : 0
        return max(duration, configuredDuration)
    }

    static func focusCascadeDelay(
        visibleOrder: Int,
        visibleLineCount: Int,
        preferredDelayPerLine: TimeInterval,
        preferredDelayIncreasePerLine: TimeInterval,
        highlightedLyricID: LyricLine.ID?,
        in lyrics: [LyricLine]
    ) -> TimeInterval {
        guard visibleOrder > 0,
              visibleLineCount > 1,
              preferredDelayPerLine > 0 else {
            return 0
        }

        let lastVisibleOrder = visibleLineCount - 1
        let effectiveDelays = effectiveFocusCascadeDelays(
            visibleLineCount: visibleLineCount,
            preferredDelayPerLine: preferredDelayPerLine,
            preferredDelayIncreasePerLine: preferredDelayIncreasePerLine,
            highlightedLyricID: highlightedLyricID,
            in: lyrics
        )
        return accumulatedFocusCascadeDelay(
            visibleOrder: min(visibleOrder, lastVisibleOrder),
            delayPerLine: effectiveDelays.delayPerLine,
            delayIncreasePerLine: effectiveDelays.delayIncreasePerLine
        )
    }

    static func focusCascadeTiming(
        visibleLineCount: Int,
        preferredDelayPerLine: TimeInterval,
        preferredDelayIncreasePerLine: TimeInterval,
        focusColorLeadTime: TimeInterval,
        baseAnimationDuration: TimeInterval,
        preferredAnimationDuration: TimeInterval,
        prefersBounce: Bool,
        remainingDuration: TimeInterval?,
        highlightedLyricID: LyricLine.ID?,
        in lyrics: [LyricLine]
    ) -> LyricFocusCascadeTiming? {
        guard visibleLineCount > 1,
              preferredDelayPerLine.isFinite,
              preferredDelayPerLine > 0,
              preferredDelayIncreasePerLine.isFinite,
              preferredDelayIncreasePerLine >= 0,
              baseAnimationDuration.isFinite,
              baseAnimationDuration > 0 else {
            return nil
        }
        let effectiveDelays = effectiveFocusCascadeDelays(
            visibleLineCount: visibleLineCount,
            preferredDelayPerLine: preferredDelayPerLine,
            preferredDelayIncreasePerLine: preferredDelayIncreasePerLine,
            highlightedLyricID: highlightedLyricID,
            in: lyrics
        )
        let finalLaunchDelay = accumulatedFocusCascadeDelay(
            visibleOrder: visibleLineCount - 1,
            delayPerLine: effectiveDelays.delayPerLine,
            delayIncreasePerLine: effectiveDelays.delayIncreasePerLine
        )
        let fullAnimationDuration = max(
            preferredAnimationDuration,
            baseAnimationDuration
        )
        let fullTiming = LyricFocusCascadeTiming(
            delayPerLine: effectiveDelays.delayPerLine,
            delayIncreasePerLine: effectiveDelays.delayIncreasePerLine,
            animationDuration: fullAnimationDuration,
            usesBounce: prefersBounce
        )
        guard let remainingDuration, remainingDuration.isFinite else {
            return fullTiming
        }

        let schedulingMargin: TimeInterval = 1.0 / 120.0
        let availableDuration = remainingDuration
            - max(focusColorLeadTime, 0)
            - schedulingMargin
        guard availableDuration > 0 else { return nil }

        if finalLaunchDelay + fullAnimationDuration <= availableDuration {
            return fullTiming
        }
        if finalLaunchDelay + baseAnimationDuration <= availableDuration {
            return LyricFocusCascadeTiming(
                delayPerLine: effectiveDelays.delayPerLine,
                delayIncreasePerLine: effectiveDelays.delayIncreasePerLine,
                animationDuration: baseAnimationDuration,
                usesBounce: false
            )
        }

        let fullNormalDuration = finalLaunchDelay + baseAnimationDuration
        guard fullNormalDuration > 0 else { return nil }
        let compression = min(max(availableDuration / fullNormalDuration, 0), 1)
        let compressedAnimationDuration = baseAnimationDuration * compression
        let minimumAnimationDuration = min(baseAnimationDuration, 0.05)
        guard compressedAnimationDuration >= minimumAnimationDuration else {
            return nil
        }

        return LyricFocusCascadeTiming(
            delayPerLine: effectiveDelays.delayPerLine * compression,
            delayIncreasePerLine: effectiveDelays.delayIncreasePerLine
                * compression,
            animationDuration: compressedAnimationDuration,
            usesBounce: false
        )
    }

    private static func effectiveFocusCascadeDelays(
        visibleLineCount: Int,
        preferredDelayPerLine: TimeInterval,
        preferredDelayIncreasePerLine: TimeInterval,
        highlightedLyricID: LyricLine.ID?,
        in lyrics: [LyricLine]
    ) -> (
        delayPerLine: TimeInterval,
        delayIncreasePerLine: TimeInterval
    ) {
        let delayPerLine = max(preferredDelayPerLine, 0)
        let delayIncreasePerLine = max(preferredDelayIncreasePerLine, 0)
        let finalVisibleOrder = max(visibleLineCount - 1, 0)
        let preferredTotalDelay = accumulatedFocusCascadeDelay(
            visibleOrder: finalVisibleOrder,
            delayPerLine: delayPerLine,
            delayIncreasePerLine: delayIncreasePerLine
        )
        guard preferredTotalDelay > 0 else {
            return (0, 0)
        }

        let maximumTotalDelay = availableFocusDuration(
            for: highlightedLyricID,
            in: lyrics
        ).map { min($0 * 0.45, 0.8) } ?? 0.4
        let scale = min(maximumTotalDelay / preferredTotalDelay, 1)
        return (
            delayPerLine * scale,
            delayIncreasePerLine * scale
        )
    }

    private static func accumulatedFocusCascadeDelay(
        visibleOrder: Int,
        delayPerLine: TimeInterval,
        delayIncreasePerLine: TimeInterval
    ) -> TimeInterval {
        let order = Double(max(visibleOrder, 0))
        let accumulatedIncrease = order * max(order - 1, 0) / 2
        return order * delayPerLine
            + accumulatedIncrease * delayIncreasePerLine
    }

    static func remainingFocusDuration(
        for highlightedLyricID: LyricLine.ID?,
        at playbackTime: TimeInterval,
        in lyrics: [LyricLine]
    ) -> TimeInterval? {
        guard let highlightedLyricID,
              playbackTime.isFinite,
              let index = lyrics.firstIndex(where: { $0.id == highlightedLyricID }) else {
            return nil
        }
        let followingIndex = lyrics.index(after: index)
        guard followingIndex < lyrics.endIndex else { return nil }

        let remainingDuration = lyrics[followingIndex].time - playbackTime
        guard remainingDuration.isFinite else { return nil }
        return max(remainingDuration, 0)
    }

    private static func availableFocusDuration(
        for highlightedLyricID: LyricLine.ID?,
        in lyrics: [LyricLine]
    ) -> TimeInterval? {
        guard let highlightedLyricID,
              let index = lyrics.firstIndex(where: { $0.id == highlightedLyricID }) else {
            return nil
        }

        let followingIndex = lyrics.index(after: index)
        let availableDuration = followingIndex < lyrics.endIndex
            ? lyrics[followingIndex].time - lyrics[index].time
            : lyrics[index].duration
        guard let availableDuration,
              availableDuration.isFinite,
              availableDuration > 0 else {
            return nil
        }
        return availableDuration
    }
}
