import SwiftUI

struct PlayerSettingsView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(PlayerStore.self) private var player

    @State private var showsResetConfirmation = false
    @State private var isResettingSettings = false

    var body: some View {
        @Bindable var settings = settings

        Form {
            Section {
                Picker("音质", selection: $settings.quality) {
                    ForEach(MusicQuality.allCases) { quality in
                        Text(quality.title).tag(quality)
                    }
                }

                Picker(
                    "音量控制",
                    selection: $settings.playerVolumeControlMode
                ) {
                    ForEach(PlayerVolumeControlMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }

                NavigationLink {
                    EqualizerSettingsView()
                } label: {
                    LabeledContent(
                        "均衡器",
                        value: settings.equalizer.summary
                    )
                }
            } header: {
                Text("音频")
            } footer: {
                Text(settings.playerVolumeControlMode.description)
            }

            Section {
                valueSlider(
                    title: "背景模糊",
                    value: $settings.playerBackgroundBlur,
                    range: 0...140,
                    step: 5,
                    valueText: "\(Int(settings.playerBackgroundBlur))"
                )

                valueSlider(
                    title: "背景色彩",
                    value: $settings.playerBackgroundSaturation,
                    range: 0.4...1.2,
                    step: 0.05,
                    valueText: "\(Int(settings.playerBackgroundSaturation * 100))%"
                )

                Toggle("暂停时缩小封面", isOn: $settings.shrinksPausedArtwork)
            } header: {
                Text("播放器外观")
            } footer: {
                Text("背景选项会实时作用于展开的播放器。")
            }

            Section {
                Toggle("记住所处页面", isOn: $settings.rememberNowPlayingPage)

                Toggle("上一首优先回到歌曲开头", isOn: $settings.previousRestartsCurrentSong)
            } header: {
                Text("播放器行为")
            } footer: {
                Text("页面记忆会恢复上次关闭时的封面、歌词或队列。关闭上一首回到开头后，按钮会始终直接切换歌曲。")
            }

            Section {
                NavigationLink {
                    SkylineLyricsSettingsView()
                } label: {
                    Label("全屏天际歌词", systemImage: "textformat.size")
                }
            } header: {
                Text("全屏歌词")
            } footer: {
                Text("调整播放器横屏状态下全屏天际歌词的文字和背景动态效果。")
            }

            Section {
                NavigationLink {
                    FloatingLyricsSettingsView()
                } label: {
                    Label("悬浮窗歌词", systemImage: "pip")
                }
            } header: {
                Text("悬浮歌词")
            } footer: {
                Text("通过系统画中画在其他应用上方显示当前歌词和下一句。")
            }

            Section {
                Picker("歌词样式", selection: $settings.lyricsStyle) {
                    ForEach(LyricsStyle.allCases) { style in
                        Label(style.title, systemImage: style.systemImage)
                            .tag(style)
                    }
                }

                if settings.lyricsStyle == .textPV {
                    NavigationLink {
                        TextPVSettingsView()
                    } label: {
                        LabeledContent("文字PV设置", value: settings.textPV.style.title)
                    }
                }

                valueSlider(
                    title: "字体大小",
                    value: $settings.lyricsFontSize,
                    range: 20...36,
                    step: 1,
                    valueText: "\(Int(settings.lyricsFontSize)) 磅"
                )

                Picker(
                    "歌词字体粗细",
                    selection: $settings.lyricsFontWeight
                ) {
                    ForEach(LyricsFontWeight.allCases) { weight in
                        Text(weight.title).tag(weight)
                    }
                }

                if settings.lyricsStyle == .appleMusic {
                    valueSlider(
                        title: "当前歌词大小",
                        value: $settings.lyricsCurrentLineScale,
                        range: AppSettings.lyricsCurrentLineScaleRange,
                        step: 0.01,
                        valueText: "\(Int((settings.lyricsCurrentLineScale * 100).rounded()))%"
                    )

                    valueSlider(
                        title: "歌词行距",
                        value: $settings.lyricsLineSpacing,
                        range: 12...36,
                        step: 1,
                        valueText: "\(Int(settings.lyricsLineSpacing))"
                    )

                    valueSlider(
                        title: "基础模糊强度",
                        value: $settings.lyricsBlurIntensity,
                        range: 0...2,
                        step: 0.1,
                        valueText: settings.lyricsBlurIntensity.formatted(
                            .number.precision(.fractionLength(1))
                        )
                    )

                    valueSlider(
                        title: "默认逐句模糊加强",
                        value: $settings.lyricsDistanceBlurScale,
                        range: AppSettings.lyricsDistanceBlurScaleRange,
                        step: 0.05,
                        valueText: "\(Int((settings.lyricsDistanceBlurScale * 100).rounded()))%"
                    )

                    valueSlider(
                        title: "隐藏 UI 逐句模糊加强",
                        value: $settings.lyricsHiddenInterfaceBlurScale,
                        range: AppSettings.lyricsDistanceBlurScaleRange,
                        step: 0.05,
                        valueText: "\(Int((settings.lyricsHiddenInterfaceBlurScale * 100).rounded()))%"
                    )

                    valueSlider(
                        title: "非焦点歌词变暗",
                        value: $settings.lyricsDimAmount,
                        range: 0...1,
                        step: 0.1,
                        valueText: "\(Int(settings.lyricsDimAmount * 100))%"
                    )

                    valueSlider(
                        title: "焦点垂直位置",
                        value: $settings.lyricsFocusPosition,
                        range: AppSettings.lyricsFocusPositionRange,
                        step: 0.01,
                        valueText: "距顶部 \(Int(settings.lyricsFocusPosition * 100))%"
                    )
                }

            } header: {
                Text("歌词外观")
            } footer: {
                Text("\(settings.lyricsStyle.title)：\(settings.lyricsStyle.description)。歌词字体粗细会同时应用于原文、翻译和全屏天际歌词；EVA 与文字PV保留各自模板字体。逐字动效仅用于 Apple Music 样式。逐句模糊加强只调整随焦点距离递增的模糊，100% 为原始强度；默认状态与隐藏 UI 后可以分别设置。")
            }

            Section {
                Picker("刷新频率", selection: $settings.lyricsRefreshRate) {
                    ForEach(LyricsRefreshRate.allCases) { refreshRate in
                        Text(refreshRate.title).tag(refreshRate)
                    }
                }
            } header: {
                Text("歌词性能")
            } footer: {
                Text("默认使用 60 FPS，并应用到所有歌词页；高负载文字PV模板会自动限制为 30 FPS，避免影响播放器操作。较高刷新频率会增加耗电；系统低电量模式期间会自动降至 30 FPS，退出后恢复所选频率。")
            }

            Section {
                valueSlider(
                    title: "基础拖尾延迟",
                    value: $settings.lyricsFocusCascadeDelay,
                    range: AppSettings.lyricsFocusCascadeDelayRange,
                    step: 0.001,
                    valueText: "\(Int((settings.lyricsFocusCascadeDelay * 1_000).rounded())) 毫秒"
                )

                valueSlider(
                    title: "逐句拖尾增量",
                    value: $settings.lyricsFocusCascadeDelayIncrease,
                    range: AppSettings.lyricsFocusCascadeDelayIncreaseRange,
                    step: 0.001,
                    valueText: "\(Int((settings.lyricsFocusCascadeDelayIncrease * 1_000).rounded())) 毫秒/句"
                )

                valueSlider(
                    title: "后续歌词启动延迟",
                    value: $settings.lyricsFocusCascadeFollowingDelay,
                    range: AppSettings.lyricsFocusCascadeFollowingDelayRange,
                    step: 0.001,
                    valueText: "\(Int((settings.lyricsFocusCascadeFollowingDelay * 1_000).rounded())) 毫秒"
                )

                valueSlider(
                    title: "拖尾追赶节奏",
                    value: $settings.lyricsFocusCascadeCatchUpRatio,
                    range: AppSettings.lyricsFocusCascadeCatchUpRatioRange,
                    step: 0.01,
                    valueText: "\(Int((settings.lyricsFocusCascadeCatchUpRatio * 100).rounded()))%"
                )

                valueSlider(
                    title: "位移收束时长",
                    value: $settings.lyricsFocusCascadeDuration,
                    range: AppSettings.lyricsFocusCascadeDurationRange,
                    step: 0.01,
                    valueText: "\(settings.lyricsFocusCascadeDuration.formatted(.number.precision(.fractionLength(2)))) 秒"
                )

                valueSlider(
                    title: "瞬移阈值",
                    value: $settings.lyricsFocusSnapThreshold,
                    range: AppSettings.lyricsFocusSnapThresholdRange,
                    step: 0.001,
                    valueText: "\(Int((settings.lyricsFocusSnapThreshold * 1_000).rounded())) 毫秒"
                )

                Toggle(
                    "启用位移回弹",
                    isOn: $settings.lyricsFocusCascadeBounceEnabled
                )

                if settings.lyricsFocusCascadeBounceEnabled {
                    valueSlider(
                        title: "回弹弹性",
                        value: $settings.lyricsFocusCascadeBounce,
                        range: AppSettings.lyricsFocusCascadeBounceRange,
                        step: 0.01,
                        valueText: "\(Int((settings.lyricsFocusCascadeBounce * 100).rounded()))%"
                    )
                }

                Toggle(
                    "启用升格回弹",
                    isOn: $settings.lyricsFocusScaleBounceEnabled
                )

                if settings.lyricsFocusScaleBounceEnabled {
                    valueSlider(
                        title: "升格回弹时长",
                        value: $settings.lyricsFocusScaleBounceDuration,
                        range: AppSettings.lyricsFocusScaleBounceDurationRange,
                        step: 0.01,
                        valueText: "\(settings.lyricsFocusScaleBounceDuration.formatted(.number.precision(.fractionLength(2)))) 秒"
                    )

                    valueSlider(
                        title: "升格回弹弹性",
                        value: $settings.lyricsFocusScaleBounce,
                        range: AppSettings.lyricsFocusScaleBounceRange,
                        step: 0.01,
                        valueText: "\(Int((settings.lyricsFocusScaleBounce * 100).rounded()))%"
                    )
                }

                valueSlider(
                    title: "焦点颜色提前",
                    value: $settings.lyricsFocusColorLeadTime,
                    range: AppSettings.lyricsFocusColorLeadTimeRange,
                    step: 0.005,
                    valueText: "\(Int((settings.lyricsFocusColorLeadTime * 1_000).rounded())) 毫秒"
                )
            } header: {
                Text("歌词动画")
            } footer: {
                Text("当前句及之前的歌词先移动，等待“后续歌词启动延迟”（默认 40 毫秒）后，下一句及之后的歌词才开始位移；后续歌词的实际延迟再由“基础拖尾延迟”和“逐句拖尾增量”完整累计，不设内部最大延迟；三项均可调至 0 毫秒。“拖尾追赶节奏”默认 96%，数值越低追赶越快。位移基准时长为 0.68 秒，默认关闭位移回弹；当前句升格放大另有独立的 0.58 秒、28% 回弹。瞬移阈值默认 260 毫秒，可在 50–500 毫秒之间调整；剩余时间短于该阈值时会直接对齐。")
            }

            Section {
                Toggle("显示歌词翻译", isOn: $settings.lyricsTranslationEnabled)

                if settings.lyricsTranslationEnabled {
                    if settings.lyricsStyle == .appleMusic {
                        Picker(
                            "翻译显示方式",
                            selection: $settings.lyricsTranslationDisplayMode
                        ) {
                            ForEach(LyricsTranslationDisplayMode.allCases) { mode in
                                Text(mode.title).tag(mode)
                            }
                        }
                    }

                    valueSlider(
                        title: "翻译歌词大小",
                        value: $settings.lyricsTranslationFontScale,
                        range: 0.5...0.8,
                        step: 0.05,
                        valueText: "\(Int(settings.lyricsTranslationFontScale * 100))%"
                    )

                    valueSlider(
                        title: "翻译歌词亮度",
                        value: $settings.lyricsTranslationOpacity,
                        range: 0.4...0.9,
                        step: 0.05,
                        valueText: "\(Int(settings.lyricsTranslationOpacity * 100))%"
                    )
                }

                Toggle("逐字歌词", isOn: $settings.lyricsWordByWord)

                if settings.lyricsWordByWord || settings.lyricsPseudoWordByWord {
                    Toggle("逐字歌词光效", isOn: $settings.lyricsGlowEnabled)

                    valueSlider(
                        title: "长音判定阈值",
                        value: $settings.lyricsLongSyllableDurationThreshold,
                        range:
                            AppSettings
                                .lyricsLongSyllableDurationThresholdRange,
                        step: 0.05,
                        valueText: "\(settings.lyricsLongSyllableDurationThreshold.formatted(.number.precision(.fractionLength(2)))) 秒"
                    )

                    if settings.lyricsGlowEnabled {
                        Toggle(
                            "仅长音显示辉光",
                            isOn: $settings.lyricsGlowLongSyllablesOnly
                        )

                        valueSlider(
                            title: "逐字光效强度",
                            value: $settings.lyricsGlowIntensity,
                            range: 0.4...1.6,
                            step: 0.1,
                            valueText: settings.lyricsGlowIntensity.formatted(
                                .number.precision(.fractionLength(1))
                            )
                        )
                    }
                }
            } header: {
                Text("歌词内容与光效")
            } footer: {
                Text("中英翻译直接使用网易云提供的 ytlrc 或 tlyric。Apple Music 样式默认只展开当前播放行的翻译，换句时旧翻译收起、新翻译淡入并参与整页位移；也可以改为全部显示。逐字歌词开关仅控制歌曲自带的 YRC 时间轴。长音判定阈值默认 0.70 秒，并同时控制膨胀和“仅长音显示辉光”的触发；关闭该选项后，普通音节也会显示辉光，但膨胀仍只用于长音。")
            }

            Section {
                Toggle("启用伪逐字歌词", isOn: $settings.lyricsPseudoWordByWord)
            } header: {
                Text("伪逐字歌词")
            } footer: {
                Text("默认关闭，仅在整首歌没有 YRC 时间轴时，按照每行字数和持续时间生成逐字进度；该开关可独立于歌曲自带的逐字歌词使用。")
            }

            Section {
                Picker(
                    "屏幕常亮",
                    selection: $settings.playerScreenAwakeMode
                ) {
                    ForEach(PlayerScreenAwakeMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
            } header: {
                Text("屏幕常亮")
            } footer: {
                Text("用于阻止系统自动锁屏。天际歌词继续使用其独立的屏幕常亮设置。")
            }

            Section {
                Toggle("双击歌词跳转", isOn: $settings.lyricsTapToSeek)

                valueSlider(
                    title: "歌词提前量",
                    value: $settings.lyricsAdvanceTime,
                    range: 0...5,
                    step: 0.1,
                    valueText: "\(settings.lyricsAdvanceTime.formatted(.number.precision(.fractionLength(1)))) 秒"
                )

                Toggle("浏览后恢复跟随", isOn: $settings.lyricsAutoFollow)

                if settings.lyricsAutoFollow {
                    valueSlider(
                        title: "恢复跟随等待",
                        value: $settings.lyricsFollowDelay,
                        range: 1...10,
                        step: 1,
                        valueText: "\(Int(settings.lyricsFollowDelay)) 秒"
                    )
                }
            } header: {
                Text("歌词交互")
            } footer: {
                Text("提前量会让歌词比歌曲时间更早进入播放焦点；仅在启用恢复跟随后才会在手动浏览后返回播放位置。")
            }

            Section {
                Button("恢复播放器默认设置", role: .destructive) {
                    showsResetConfirmation = true
                }
                .disabled(isResettingSettings)
            }
        }
        .navigationTitle("播放器")
        .onChange(of: settings.playerVolumeControlMode) {
            player.applyVolumeControlMode()
        }
        .confirmationDialog("恢复播放器默认设置？", isPresented: $showsResetConfirmation) {
            Button("恢复默认设置", role: .destructive) {
                resetPlayerSettings()
            }
        }
    }

    private func resetPlayerSettings() {
        guard !isResettingSettings else { return }
        isResettingSettings = true

        Task { @MainActor in
            await Task.yield()

            var transaction = Transaction(animation: nil)
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                settings.resetPlayerSettings()
            }

            await Task.yield()
            player.applyEqualizerSettings()
            isResettingSettings = false
        }
    }

    private func valueSlider(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        valueText: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            LabeledContent(title, value: valueText)
            Slider(value: value, in: range, step: step)
                .accessibilityLabel(title)
                .accessibilityValue(valueText)
        }
    }
}
