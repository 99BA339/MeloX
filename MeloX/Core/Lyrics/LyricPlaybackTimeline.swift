import Foundation

struct LyricPlaybackPosition: Equatable {
    let highlightedLyricID: LyricLine.ID?
    let nextTransitionTime: TimeInterval?
}

struct LyricFocusCascadeTiming: Equatable {
    let durationOffsetsByLineOrder: [TimeInterval]
    let animationDuration: TimeInterval
    let usesBounce: Bool

    func durationOffset(for lineOrder: Int) -> TimeInterval {
        guard !durationOffsetsByLineOrder.isEmpty else { return 0 }
        let index = min(
            max(lineOrder, durationOffsetsByLineOrder.startIndex),
            durationOffsetsByLineOrder.index(
                before: durationOffsetsByLineOrder.endIndex
            )
        )
        return durationOffsetsByLineOrder[index]
    }
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
            return 0.3
        }

        return min(max(availableDuration * 0.35, 0.05), 0.3)
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

    static func focusCascadeTiming(
        maximumLineOrder: Int,
        preferredDurationOffsetPerLine: TimeInterval,
        preferredDurationOffsetIncreasePerLine: TimeInterval,
        focusColorLeadTime: TimeInterval,
        baseAnimationDuration: TimeInterval,
        preferredAnimationDuration: TimeInterval,
        prefersBounce: Bool,
        snapThreshold: TimeInterval,
        remainingDuration: TimeInterval?
    ) -> LyricFocusCascadeTiming? {
        guard maximumLineOrder >= 0,
              preferredDurationOffsetPerLine.isFinite,
              preferredDurationOffsetPerLine > 0,
              preferredDurationOffsetIncreasePerLine.isFinite,
              preferredDurationOffsetIncreasePerLine >= 0,
              baseAnimationDuration.isFinite,
              baseAnimationDuration > 0 else {
            return nil
        }
        let durationOffsetPerLine = max(
            preferredDurationOffsetPerLine,
            0
        )
        let durationOffsetIncreasePerLine = max(
            preferredDurationOffsetIncreasePerLine,
            0
        )
        let preferredDurationOffsets = (0...maximumLineOrder).map {
            accumulatedFocusCascadeDurationOffset(
                lineOrder: $0,
                durationOffsetPerLine: durationOffsetPerLine,
                durationOffsetIncreasePerLine:
                    durationOffsetIncreasePerLine
            )
        }
        let fullAnimationDuration = max(
            preferredAnimationDuration,
            baseAnimationDuration
        )
        let fullTiming = LyricFocusCascadeTiming(
            durationOffsetsByLineOrder: preferredDurationOffsets,
            animationDuration: fullAnimationDuration,
            usesBounce: prefersBounce
        )
        guard let remainingDuration, remainingDuration.isFinite else {
            return fullTiming
        }

        let availableDuration = remainingDuration
            - max(focusColorLeadTime, 0)
        let effectiveSnapThreshold = snapThreshold.isFinite
            ? max(snapThreshold, 0)
            : 0
        guard availableDuration >= effectiveSnapThreshold else {
            return nil
        }
        return fullTiming
    }

    private static func accumulatedFocusCascadeDurationOffset(
        lineOrder: Int,
        durationOffsetPerLine: TimeInterval,
        durationOffsetIncreasePerLine: TimeInterval
    ) -> TimeInterval {
        let order = Double(max(lineOrder, 0))
        let accumulatedIncrease = order * max(order - 1, 0) / 2
        return order * durationOffsetPerLine
            + accumulatedIncrease * durationOffsetIncreasePerLine
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
