import SwiftUI

struct LyricMovementAnimationConfiguration: Equatable {
    let duration: TimeInterval
    let usesBounce: Bool
    let bounce: Double
}

struct LyricMovementTransition: Equatable {
    let id: UUID
    let focusID: LyricLine.ID
    let initialOffsetsByID: [LyricLine.ID: CGFloat]
    let animationByID: [
        LyricLine.ID: LyricMovementAnimationConfiguration
    ]
    let startedAt: Date?

    init(
        id: UUID = UUID(),
        focusID: LyricLine.ID,
        initialOffsetsByID: [LyricLine.ID: CGFloat],
        animationByID: [
            LyricLine.ID: LyricMovementAnimationConfiguration
        ] = [:],
        startedAt: Date? = nil
    ) {
        self.id = id
        self.focusID = focusID
        self.initialOffsetsByID = initialOffsetsByID
        self.animationByID = animationByID
        self.startedAt = startedAt
    }

    func starting(
        with animationByID: [
            LyricLine.ID: LyricMovementAnimationConfiguration
        ],
        at date: Date
    ) -> Self {
        Self(
            id: id,
            focusID: focusID,
            initialOffsetsByID: initialOffsetsByID,
            animationByID: animationByID,
            startedAt: date
        )
    }

    func presentationOffsets(
        at date: Date
    ) -> [LyricLine.ID: CGFloat] {
        guard let startedAt else { return initialOffsetsByID }
        let elapsed = max(date.timeIntervalSince(startedAt), 0)

        return initialOffsetsByID.reduce(into: [:]) { offsets, entry in
            let (id, initialOffset) = entry
            guard let configuration = animationByID[id] else {
                offsets[id] = initialOffset
                return
            }

            let spring: Spring = configuration.usesBounce
                ? Spring(
                    duration: configuration.duration,
                    bounce: configuration.bounce
                )
                : .smooth(duration: configuration.duration)
            let progress = spring.value(
                target: 1,
                initialVelocity: 0,
                time: elapsed
            )
            offsets[id] = initialOffset * CGFloat(1 - progress)
        }
    }
}
