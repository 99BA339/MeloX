import SwiftUI

struct LyricMovementAnimationConfiguration: Equatable {
    let delay: TimeInterval
    let duration: TimeInterval
    let usesBounce: Bool
    let bounce: Double
}

struct LyricMovementTransition: Equatable {
    let id: UUID
    let focusID: LyricLine.ID
    let initialOffsetsByID: [LyricLine.ID: CGFloat]
    let destinationOffsetsByID: [LyricLine.ID: CGFloat]
    let animationByID: [
        LyricLine.ID: LyricMovementAnimationConfiguration
    ]
    let startedAt: Date?

    init(
        id: UUID = UUID(),
        focusID: LyricLine.ID,
        initialOffsetsByID: [LyricLine.ID: CGFloat],
        destinationOffsetsByID: [LyricLine.ID: CGFloat] = [:],
        animationByID: [
            LyricLine.ID: LyricMovementAnimationConfiguration
        ] = [:],
        startedAt: Date? = nil
    ) {
        self.id = id
        self.focusID = focusID
        self.initialOffsetsByID = initialOffsetsByID
        self.destinationOffsetsByID = destinationOffsetsByID
        self.animationByID = animationByID
        self.startedAt = startedAt
    }

    func starting(
        with animationByID: [
            LyricLine.ID: LyricMovementAnimationConfiguration
        ],
        at date: Date
    ) -> Self {
        let animatedInitialOffsets = initialOffsetsByID.filter {
            animationByID[$0.key] != nil
        }
        let animatedDestinationOffsets = destinationOffsetsByID.filter {
            animationByID[$0.key] != nil
        }
        return Self(
            id: id,
            focusID: focusID,
            initialOffsetsByID: animatedInitialOffsets,
            destinationOffsetsByID: animatedDestinationOffsets,
            animationByID: animationByID,
            startedAt: date
        )
    }

    func presentationOffsets(
        at date: Date
    ) -> [LyricLine.ID: CGFloat] {
        guard let startedAt else { return initialOffsetsByID }
        let elapsed = max(date.timeIntervalSince(startedAt), 0)

        var animatedIDs = Set(initialOffsetsByID.keys)
        animatedIDs.formUnion(destinationOffsetsByID.keys)
        return animatedIDs.reduce(into: [:]) { offsets, id in
            let destinationOffset = destinationOffsetsByID[id, default: 0]
            let initialOffset = initialOffsetsByID[
                id,
                default: destinationOffset
            ]
            guard let configuration = animationByID[id] else {
                offsets[id] = initialOffset
                return
            }
            let animationElapsed = max(
                elapsed - configuration.delay,
                0
            )

            let spring: Spring = configuration.usesBounce
                ? Spring(
                    duration: configuration.duration,
                    bounce: configuration.bounce
                )
                : .snappy(duration: configuration.duration)
            let progress = spring.value(
                target: 1,
                initialVelocity: 0,
                time: animationElapsed
            )
            offsets[id] = destinationOffset
                + (initialOffset - destinationOffset)
                    * CGFloat(1 - progress)
        }
    }
}
