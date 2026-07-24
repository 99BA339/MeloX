import SwiftUI

struct FloatingLyricsPresentation: Equatable {
    let songID: Int?
    let lyricID: LyricLine.ID?
    let title: String
    let artist: String
    let currentText: String
    let translation: String?
    let nextText: String?
    let isPlaying: Bool
    let fontScale: Double
}

struct FloatingLyricsContentView: View {
    let presentation: FloatingLyricsPresentation

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.20, green: 0.02, blue: 0.04),
                    .black,
                    Color(red: 0.06, green: 0.01, blue: 0.02),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(.red.opacity(0.18))
                .frame(width: 420, height: 420)
                .blur(radius: 90)
                .offset(x: -360, y: -210)

            VStack(alignment: .leading, spacing: 0) {
                songHeader

                Spacer(minLength: 24)

                currentLyric

                Spacer(minLength: 24)

                nextLyric
            }
            .padding(.horizontal, 54)
            .padding(.vertical, 38)
        }
        .foregroundStyle(.white)
        .clipped()
    }

    private var songHeader: some View {
        HStack(spacing: 13) {
            Image(systemName: presentation.isPlaying ? "waveform" : "pause.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.red)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 3) {
                Text(presentation.title)
                    .font(.system(size: 24, weight: .semibold))
                    .lineLimit(1)

                Text(presentation.artist)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(1)
            }
        }
    }

    private var currentLyric: some View {
        VStack(alignment: .leading, spacing: 13) {
            Text(presentation.currentText)
                .font(
                    .system(
                        size: 52 * presentation.fontScale,
                        weight: .bold,
                        design: .rounded
                    )
                )
                .lineLimit(2)
                .minimumScaleFactor(0.55)
                .shadow(color: .red.opacity(0.28), radius: 16)

            if let translation = presentation.translation {
                Text(translation)
                    .font(
                        .system(
                            size: 25 * presentation.fontScale,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(.white.opacity(0.72))
                    .lineLimit(2)
                    .minimumScaleFactor(0.65)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var nextLyric: some View {
        if let nextText = presentation.nextText {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Image(systemName: "chevron.forward")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.red.opacity(0.8))

                Text(nextText)
                    .font(
                        .system(
                            size: 25 * presentation.fontScale,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(.white.opacity(0.42))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        } else {
            Color.clear
                .frame(height: 30)
        }
    }
}

#Preview("悬浮歌词") {
    FloatingLyricsContentView(
        presentation: FloatingLyricsPresentation(
            songID: 1,
            lyricID: "12.5-示例歌词",
            title: "正在播放的歌曲",
            artist: "歌手",
            currentText: "让音乐陪你去往更远的地方",
            translation: "Let the music carry you farther.",
            nextText: "下一句歌词会显示在这里",
            isPlaying: true,
            fontScale: 1
        )
    )
    .frame(width: 480, height: 270)
}
