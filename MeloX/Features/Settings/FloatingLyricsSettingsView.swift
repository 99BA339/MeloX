import SwiftUI

struct FloatingLyricsSettingsView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(FloatingLyricsController.self) private var floatingLyrics

    var body: some View {
        @Bindable var preferences = settings.floatingLyrics

        Form {
            Section {
                LabeledContent(
                    "系统画中画",
                    value: floatingLyrics.isSupported ? "支持" : "不支持"
                )

                Toggle(
                    "显示翻译",
                    isOn: $preferences.showsTranslation
                )
                Toggle(
                    "显示下一句",
                    isOn: $preferences.showsNextLine
                )

                VStack(alignment: .leading, spacing: 8) {
                    LabeledContent(
                        "歌词大小",
                        value: "\(Int((preferences.fontScale * 100).rounded()))%"
                    )
                    Slider(
                        value: $preferences.fontScale,
                        in: FloatingLyricsPreferences.fontScaleRange,
                        step: 0.05
                    )
                    .accessibilityLabel("悬浮歌词大小")
                }
            } header: {
                Text("显示")
            } footer: {
                Text("翻译仍会遵循播放器中的“显示歌词翻译”总开关。")
            }

            Section {
                Label(
                    "播放歌曲后，在播放器底部轻点画中画按钮即可开启。悬浮窗支持播放、暂停和前后跳转。",
                    systemImage: "pip"
                )
            } header: {
                Text("使用方式")
            }
        }
        .navigationTitle("悬浮窗歌词")
    }
}
