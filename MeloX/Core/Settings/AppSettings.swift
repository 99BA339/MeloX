import Foundation
import Observation

enum MusicQuality: String, CaseIterable, Identifiable, Codable {
    case standard = "128000"
    case high = "320000"
    case lossless = "flac"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .standard: "标准"
        case .high: "高品质"
        case .lossless: "无损"
        }
    }

    var bitrate: String {
        self == .lossless ? "350000" : rawValue
    }

    var downloadBitrate: Int {
        switch self {
        case .standard: 128_000
        case .high: 320_000
        case .lossless: 999_000
        }
    }
}

@MainActor
@Observable
final class AppSettings {
    private static let lyricsFocusCascadeConfigurationVersion = 9
    private static let previousDefaultLyricsFocusCascadeDelays = [
        0.025,
        0.017,
        0.08,
        0.12,
    ]
    private static let previousDefaultLyricsFocusCascadeDelayIncreases = [
        0.005,
        0.0,
        0.002,
        0.032,
        0.12,
    ]
    private static let previousDefaultLyricsFocusCascadeBounceEnabled = true
    private static let previousDefaultLyricsFocusCascadeBounces = [0.42]
    private static let previousDefaultLyricsFocusCascadeDurations = [
        0.48,
        0.76,
        0.3,
    ]
    private static let previousDefaultLyricsFontSizes = [25.0, 26.0]
    private static let previousDefaultLyricsCurrentLineScales = [1.2]
    private static let previousDefaultLyricsLineSpacings = [27.0]
    private static let previousDefaultLyricsFocusPositions = [0.28, 0.19, 0.21]
    private static let previousDefaultLyricsFocusSnapThresholds = [0.08]
    private static let previousDefaultLyricsTranslationOpacities = [0.66]
    private static let previousDefaultLyricsTranslationFontScales = [0.62]
    private static let previousDefaultLyricsFocusScaleBounces = [0.18]
    private static let previousDefaultLyricsFocusScaleBounceDurations = [0.3]
    static let defaultPlayerVolumeControlMode: PlayerVolumeControlMode = .system
    static let automaticCachePlaybackThresholdOptions = [3, 5, 10, 20]
    static let defaultLyricsFontSize = 28.0
    static let defaultLyricsFontWeight: LyricsFontWeight = .heavy
    static let defaultLyricsCurrentLineScale = 1.18
    static let defaultLyricsLineSpacing = 28.0
    static let defaultLyricsBlurIntensity = 0.8
    static let defaultLyricsDimAmount = 1.0
    static let defaultLyricsFocusPosition = 0.25
    static let lyricsFocusPositionRange = 0.05...0.8
    static let lyricsCurrentLineScaleRange = 1.0...1.5
    static let defaultLyricsDistanceBlurScale = 0.65
    static let defaultLyricsHiddenInterfaceBlurScale = 0.6
    static let lyricsDistanceBlurScaleRange = 0.0...1.5
    static let defaultLyricsFocusCascadeDelay = 0.07
    static let lyricsFocusCascadeDelayRange = 0.02...0.1
    static let defaultLyricsFocusCascadeDelayIncrease = 0.03
    static let lyricsFocusCascadeDelayIncreaseRange = 0.02...0.1
    static let defaultLyricsFocusCascadeDuration = 0.68
    static let lyricsFocusCascadeDurationRange = 0.2...1.2
    static let defaultLyricsFocusSnapThreshold = 0.26
    static let lyricsFocusSnapThresholdRange = 0.05...0.5
    static let defaultLyricsFocusCascadeBounceEnabled = false
    static let defaultLyricsFocusCascadeBounce = 0.28
    static let lyricsFocusCascadeBounceRange = 0.0...0.8
    static let defaultLyricsFocusScaleBounceEnabled = true
    static let defaultLyricsFocusScaleBounce = 0.28
    static let lyricsFocusScaleBounceRange = 0.0...0.5
    static let defaultLyricsFocusScaleBounceDuration = 0.58
    static let lyricsFocusScaleBounceDurationRange = 0.15...0.8
    static let defaultLyricsFocusColorLeadTime = 0.0
    static let lyricsFocusColorLeadTimeRange = -0.3...0.3
    static let defaultLyricsTranslationFontScale = 0.65
    static let defaultLyricsTranslationOpacity = 0.9
    static let defaultLyricsGlowLongSyllablesOnly = true
    static let defaultLyricsLongSyllableDurationThreshold = 0.7
    static let lyricsLongSyllableDurationThresholdRange = 0.3...1.5
    private enum Key {
        static let hasCompletedOnboarding = "melox.hasCompletedOnboarding"
        static let cookie = "musicCookie"
        static let quality = "musicQuality"
        static let playerVolumeControlMode = "playerVolumeControlMode"
        static let defaultLaunchTab = "defaultLaunchTab"
        static let restoresLastSelectedTab = "restoresLastSelectedTab"
        static let lastSelectedTab = "lastSelectedTab"
        static let defaultLibraryPage = "defaultLibraryPage"
        static let restoresLastLibraryPage = "restoresLastLibraryPage"
        static let lastLibraryPage = "lastLibraryPage"
        static let area = "musicArea"
        static let showPlayCount = "showPlayCount"
        static let playerBackgroundBlur = "playerBackgroundBlur"
        static let playerBackgroundSaturation = "playerBackgroundSaturation"
        static let shrinksPausedArtwork = "shrinksPausedArtwork"
        static let lyricsStyle = "lyricsStyle"
        static let lyricsFontSize = "lyricsFontSize"
        static let lyricsFontWeight = "lyricsFontWeight"
        static let lyricsCurrentLineScale = "lyricsCurrentLineScale"
        static let lyricsLineSpacing = "lyricsLineSpacing"
        static let lyricsBlurIntensity = "lyricsBlurIntensity"
        static let lyricsDistanceBlurScale = "lyricsDistanceBlurScale"
        static let lyricsHiddenInterfaceBlurScale = "lyricsHiddenInterfaceBlurScale"
        static let lyricsDimAmount = "lyricsDimAmount"
        static let lyricsTapToSeek = "lyricsTapToSeek"
        static let lyricsWordByWord = "lyricsWordByWord"
        static let lyricsPseudoWordByWord = "lyricsPseudoWordByWord"
        static let lyricsGlowEnabled = "lyricsGlowEnabled"
        static let lyricsGlowLongSyllablesOnly =
            "lyricsGlowLongSyllablesOnly"
        static let lyricsLongSyllableDurationThreshold =
            "lyricsLongSyllableDurationThreshold"
        static let lyricsGlowIntensity = "lyricsGlowIntensity"
        static let lyricsTranslationEnabled = "lyricsTranslationEnabled"
        static let lyricsTranslationDisplayMode = "lyricsTranslationDisplayMode"
        static let lyricsTranslationFontScale = "lyricsTranslationFontScale"
        static let lyricsTranslationOpacity = "lyricsTranslationOpacity"
        static let lyricsAutoFollow = "lyricsAutoFollow"
        static let lyricsFollowDelay = "lyricsFollowDelay"
        static let lyricsFocusPosition = "lyricsFocusPosition"
        static let lyricsFocusCascadeDelay = "lyricsFocusCascadeDelay"
        static let lyricsFocusCascadeDelayIncrease =
            "lyricsFocusCascadeDelayIncrease"
        static let lyricsFocusCascadeDuration = "lyricsFocusCascadeDuration"
        static let lyricsFocusSnapThreshold = "lyricsFocusSnapThreshold"
        static let lyricsFocusCascadeConfigurationVersion =
            "lyricsFocusCascadeConfigurationVersion"
        static let lyricsFocusCascadeBounceEnabled = "lyricsFocusCascadeBounceEnabled"
        static let lyricsFocusCascadeBounce = "lyricsFocusCascadeBounce"
        static let lyricsFocusScaleBounceEnabled = "lyricsFocusScaleBounceEnabled"
        static let lyricsFocusScaleBounce = "lyricsFocusScaleBounce"
        static let lyricsFocusScaleBounceDuration =
            "lyricsFocusScaleBounceDuration"
        static let legacyLyricsFocusCascadeMinimumBounceDuration =
            "lyricsFocusCascadeMinimumBounceDuration"
        static let lyricsFocusColorLeadTime = "lyricsFocusColorLeadTime"
        static let lyricsAdvanceTime = "lyricsAdvanceTime"
        static let lyricsRefreshRate = "lyricsRefreshRate"
        static let playerScreenAwakeMode = "playerScreenAwakeMode"
        static let legacyLyricsKeepsScreenAwake = "lyricsKeepsScreenAwake"
        static let rememberNowPlayingPage = "rememberNowPlayingPage"
        static let rememberedNowPlayingPage = "rememberedNowPlayingPage"
        static let previousRestartsCurrentSong = "previousRestartsCurrentSong"
        static let checksUpdatesOnLaunch = "checksUpdatesOnLaunch"
        static let automaticallyCachesFrequentlyPlayedSongs = "automaticallyCachesFrequentlyPlayedSongs"
        static let automaticCachePlaybackThreshold = "automaticCachePlaybackThreshold"
        static let automaticCacheQuality = "automaticCacheQuality"
    }

    var hasCompletedOnboarding: Bool {
        didSet {
            defaults.set(
                hasCompletedOnboarding,
                forKey: Key.hasCompletedOnboarding
            )
        }
    }

    var cookie: String {
        didSet { defaults.set(cookie, forKey: Key.cookie) }
    }

    var quality: MusicQuality {
        didSet { defaults.set(quality.rawValue, forKey: Key.quality) }
    }

    var playerVolumeControlMode: PlayerVolumeControlMode {
        didSet {
            defaults.set(
                playerVolumeControlMode.rawValue,
                forKey: Key.playerVolumeControlMode
            )
        }
    }

    var defaultLaunchTab: AppTab {
        didSet {
            defaults.set(defaultLaunchTab.rawValue, forKey: Key.defaultLaunchTab)
        }
    }

    var restoresLastSelectedTab: Bool {
        didSet {
            defaults.set(
                restoresLastSelectedTab,
                forKey: Key.restoresLastSelectedTab
            )
        }
    }

    var lastSelectedTab: AppTab {
        didSet {
            defaults.set(lastSelectedTab.rawValue, forKey: Key.lastSelectedTab)
        }
    }

    var defaultLibraryPage: LibraryPage {
        didSet {
            defaults.set(
                defaultLibraryPage.rawValue,
                forKey: Key.defaultLibraryPage
            )
        }
    }

    var restoresLastLibraryPage: Bool {
        didSet {
            defaults.set(
                restoresLastLibraryPage,
                forKey: Key.restoresLastLibraryPage
            )
        }
    }

    var lastLibraryPage: LibraryPage {
        didSet {
            defaults.set(lastLibraryPage.rawValue, forKey: Key.lastLibraryPage)
        }
    }

    var launchTab: AppTab {
        restoresLastSelectedTab ? lastSelectedTab : defaultLaunchTab
    }

    var initialLibraryPage: LibraryPage {
        restoresLastLibraryPage ? lastLibraryPage : defaultLibraryPage
    }

    var musicArea: String {
        didSet { defaults.set(musicArea, forKey: Key.area) }
    }

    var showPlayCount: Bool {
        didSet { defaults.set(showPlayCount, forKey: Key.showPlayCount) }
    }

    var playerBackgroundBlur: Double {
        didSet { defaults.set(playerBackgroundBlur, forKey: Key.playerBackgroundBlur) }
    }

    var playerBackgroundSaturation: Double {
        didSet { defaults.set(playerBackgroundSaturation, forKey: Key.playerBackgroundSaturation) }
    }

    var shrinksPausedArtwork: Bool {
        didSet { defaults.set(shrinksPausedArtwork, forKey: Key.shrinksPausedArtwork) }
    }

    var lyricsStyle: LyricsStyle {
        didSet { defaults.set(lyricsStyle.rawValue, forKey: Key.lyricsStyle) }
    }

    var lyricsFontSize: Double {
        didSet { defaults.set(lyricsFontSize, forKey: Key.lyricsFontSize) }
    }

    var lyricsFontWeight: LyricsFontWeight {
        didSet {
            defaults.set(
                lyricsFontWeight.rawValue,
                forKey: Key.lyricsFontWeight
            )
        }
    }

    var lyricsCurrentLineScale: Double {
        didSet { defaults.set(lyricsCurrentLineScale, forKey: Key.lyricsCurrentLineScale) }
    }

    var lyricsLineSpacing: Double {
        didSet { defaults.set(lyricsLineSpacing, forKey: Key.lyricsLineSpacing) }
    }

    var lyricsBlurIntensity: Double {
        didSet { defaults.set(lyricsBlurIntensity, forKey: Key.lyricsBlurIntensity) }
    }

    var lyricsDistanceBlurScale: Double {
        didSet {
            defaults.set(
                lyricsDistanceBlurScale,
                forKey: Key.lyricsDistanceBlurScale
            )
        }
    }

    var lyricsHiddenInterfaceBlurScale: Double {
        didSet {
            defaults.set(
                lyricsHiddenInterfaceBlurScale,
                forKey: Key.lyricsHiddenInterfaceBlurScale
            )
        }
    }

    var lyricsDimAmount: Double {
        didSet { defaults.set(lyricsDimAmount, forKey: Key.lyricsDimAmount) }
    }

    var lyricsTapToSeek: Bool {
        didSet { defaults.set(lyricsTapToSeek, forKey: Key.lyricsTapToSeek) }
    }

    var lyricsWordByWord: Bool {
        didSet { defaults.set(lyricsWordByWord, forKey: Key.lyricsWordByWord) }
    }

    var lyricsPseudoWordByWord: Bool {
        didSet { defaults.set(lyricsPseudoWordByWord, forKey: Key.lyricsPseudoWordByWord) }
    }

    var lyricsGlowEnabled: Bool {
        didSet { defaults.set(lyricsGlowEnabled, forKey: Key.lyricsGlowEnabled) }
    }

    var lyricsGlowLongSyllablesOnly: Bool {
        didSet {
            defaults.set(
                lyricsGlowLongSyllablesOnly,
                forKey: Key.lyricsGlowLongSyllablesOnly
            )
        }
    }

    var lyricsLongSyllableDurationThreshold: Double {
        didSet {
            defaults.set(
                lyricsLongSyllableDurationThreshold,
                forKey: Key.lyricsLongSyllableDurationThreshold
            )
        }
    }

    var lyricsGlowIntensity: Double {
        didSet { defaults.set(lyricsGlowIntensity, forKey: Key.lyricsGlowIntensity) }
    }

    var lyricsTranslationEnabled: Bool {
        didSet { defaults.set(lyricsTranslationEnabled, forKey: Key.lyricsTranslationEnabled) }
    }

    var lyricsTranslationDisplayMode: LyricsTranslationDisplayMode {
        didSet {
            defaults.set(
                lyricsTranslationDisplayMode.rawValue,
                forKey: Key.lyricsTranslationDisplayMode
            )
        }
    }

    var lyricsTranslationFontScale: Double {
        didSet { defaults.set(lyricsTranslationFontScale, forKey: Key.lyricsTranslationFontScale) }
    }

    var lyricsTranslationOpacity: Double {
        didSet { defaults.set(lyricsTranslationOpacity, forKey: Key.lyricsTranslationOpacity) }
    }

    var lyricsAutoFollow: Bool {
        didSet { defaults.set(lyricsAutoFollow, forKey: Key.lyricsAutoFollow) }
    }

    var lyricsFollowDelay: Double {
        didSet { defaults.set(lyricsFollowDelay, forKey: Key.lyricsFollowDelay) }
    }

    var lyricsFocusPosition: Double {
        didSet { defaults.set(lyricsFocusPosition, forKey: Key.lyricsFocusPosition) }
    }

    var lyricsFocusCascadeDelay: Double {
        didSet {
            defaults.set(
                lyricsFocusCascadeDelay,
                forKey: Key.lyricsFocusCascadeDelay
            )
        }
    }

    var lyricsFocusCascadeDelayIncrease: Double {
        didSet {
            defaults.set(
                lyricsFocusCascadeDelayIncrease,
                forKey: Key.lyricsFocusCascadeDelayIncrease
            )
        }
    }

    var lyricsFocusCascadeBounceEnabled: Bool {
        didSet {
            defaults.set(
                lyricsFocusCascadeBounceEnabled,
                forKey: Key.lyricsFocusCascadeBounceEnabled
            )
        }
    }

    var lyricsFocusCascadeBounce: Double {
        didSet {
            defaults.set(
                lyricsFocusCascadeBounce,
                forKey: Key.lyricsFocusCascadeBounce
            )
        }
    }

    var lyricsFocusScaleBounceEnabled: Bool {
        didSet {
            defaults.set(
                lyricsFocusScaleBounceEnabled,
                forKey: Key.lyricsFocusScaleBounceEnabled
            )
        }
    }

    var lyricsFocusScaleBounce: Double {
        didSet {
            defaults.set(
                lyricsFocusScaleBounce,
                forKey: Key.lyricsFocusScaleBounce
            )
        }
    }

    var lyricsFocusScaleBounceDuration: Double {
        didSet {
            defaults.set(
                lyricsFocusScaleBounceDuration,
                forKey: Key.lyricsFocusScaleBounceDuration
            )
        }
    }

    var lyricsFocusCascadeDuration: Double {
        didSet {
            defaults.set(
                lyricsFocusCascadeDuration,
                forKey: Key.lyricsFocusCascadeDuration
            )
        }
    }

    var lyricsFocusSnapThreshold: Double {
        didSet {
            defaults.set(
                lyricsFocusSnapThreshold,
                forKey: Key.lyricsFocusSnapThreshold
            )
        }
    }

    var lyricsFocusColorLeadTime: Double {
        didSet {
            defaults.set(
                lyricsFocusColorLeadTime,
                forKey: Key.lyricsFocusColorLeadTime
            )
        }
    }

    var lyricsAdvanceTime: Double {
        didSet { defaults.set(lyricsAdvanceTime, forKey: Key.lyricsAdvanceTime) }
    }

    var lyricsRefreshRate: LyricsRefreshRate {
        didSet { defaults.set(lyricsRefreshRate.rawValue, forKey: Key.lyricsRefreshRate) }
    }

    var playerScreenAwakeMode: PlayerScreenAwakeMode {
        didSet {
            defaults.set(
                playerScreenAwakeMode.rawValue,
                forKey: Key.playerScreenAwakeMode
            )
        }
    }

    var rememberNowPlayingPage: Bool {
        didSet {
            defaults.set(rememberNowPlayingPage, forKey: Key.rememberNowPlayingPage)
            if !rememberNowPlayingPage {
                rememberedNowPlayingPage = "artwork"
            }
        }
    }

    var rememberedNowPlayingPage: String {
        didSet { defaults.set(rememberedNowPlayingPage, forKey: Key.rememberedNowPlayingPage) }
    }

    var previousRestartsCurrentSong: Bool {
        didSet { defaults.set(previousRestartsCurrentSong, forKey: Key.previousRestartsCurrentSong) }
    }

    var checksUpdatesOnLaunch: Bool {
        didSet { defaults.set(checksUpdatesOnLaunch, forKey: Key.checksUpdatesOnLaunch) }
    }

    var automaticallyCachesFrequentlyPlayedSongs: Bool {
        didSet {
            defaults.set(
                automaticallyCachesFrequentlyPlayedSongs,
                forKey: Key.automaticallyCachesFrequentlyPlayedSongs
            )
        }
    }

    var automaticCachePlaybackThreshold: Int {
        didSet {
            defaults.set(
                automaticCachePlaybackThreshold,
                forKey: Key.automaticCachePlaybackThreshold
            )
        }
    }

    var automaticCacheQuality: MusicQuality {
        didSet {
            defaults.set(
                automaticCacheQuality.rawValue,
                forKey: Key.automaticCacheQuality
            )
        }
    }

    let skylineLyrics: SkylineLyricsPreferences
    let textPV: TextPVPreferences
    let equalizer: AudioEqualizerPreferences
    let floatingLyrics: FloatingLyricsPreferences

    @ObservationIgnored
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let appliesReferenceCascadeConfiguration = defaults.integer(
            forKey: Key.lyricsFocusCascadeConfigurationVersion
        ) < Self.lyricsFocusCascadeConfigurationVersion
        skylineLyrics = SkylineLyricsPreferences(defaults: defaults)
        textPV = TextPVPreferences(defaults: defaults)
        equalizer = AudioEqualizerPreferences(defaults: defaults)
        floatingLyrics = FloatingLyricsPreferences(defaults: defaults)
        hasCompletedOnboarding = defaults.bool(
            forKey: Key.hasCompletedOnboarding
        )
        cookie = defaults.string(forKey: Key.cookie) ?? ""
        quality = MusicQuality(rawValue: defaults.string(forKey: Key.quality) ?? "") ?? .high
        playerVolumeControlMode = PlayerVolumeControlMode(
            rawValue: defaults.string(forKey: Key.playerVolumeControlMode) ?? ""
        ) ?? Self.defaultPlayerVolumeControlMode
        defaultLaunchTab = AppTab(
            rawValue: defaults.string(forKey: Key.defaultLaunchTab) ?? ""
        ) ?? .home
        restoresLastSelectedTab = defaults.object(
            forKey: Key.restoresLastSelectedTab
        ) as? Bool ?? false
        lastSelectedTab = AppTab(
            rawValue: defaults.string(forKey: Key.lastSelectedTab) ?? ""
        ) ?? .home
        defaultLibraryPage = LibraryPage(
            rawValue: defaults.string(forKey: Key.defaultLibraryPage) ?? ""
        ) ?? .songs
        restoresLastLibraryPage = defaults.object(
            forKey: Key.restoresLastLibraryPage
        ) as? Bool ?? false
        lastLibraryPage = LibraryPage(
            rawValue: defaults.string(forKey: Key.lastLibraryPage) ?? ""
        ) ?? .songs
        musicArea = defaults.string(forKey: Key.area) ?? "ALL"
        showPlayCount = defaults.object(forKey: Key.showPlayCount) as? Bool ?? true
        playerBackgroundBlur = defaults.object(forKey: Key.playerBackgroundBlur) as? Double ?? 90
        playerBackgroundSaturation = defaults.object(forKey: Key.playerBackgroundSaturation) as? Double ?? 0.82
        shrinksPausedArtwork = defaults.object(forKey: Key.shrinksPausedArtwork) as? Bool ?? true
        let storedLyricsStyle = defaults.string(forKey: Key.lyricsStyle) ?? ""
        switch storedLyricsStyle {
        case "spotlight":
            lyricsStyle = .eva
        default:
            lyricsStyle = LyricsStyle(rawValue: storedLyricsStyle) ?? .appleMusic
        }
        let storedLyricsFontSize = defaults.object(
            forKey: Key.lyricsFontSize
        ) as? Double
        lyricsFontSize = Self.referenceLyricsValue(
            storedLyricsFontSize,
            previousDefaults: Self.previousDefaultLyricsFontSizes,
            defaultValue: Self.defaultLyricsFontSize,
            appliesReferenceConfiguration: appliesReferenceCascadeConfiguration
        )
        let storedLyricsFontWeight = LyricsFontWeight(
            rawValue: defaults.string(forKey: Key.lyricsFontWeight) ?? ""
        )
        if appliesReferenceCascadeConfiguration,
           storedLyricsFontWeight == .bold {
            lyricsFontWeight = Self.defaultLyricsFontWeight
        } else {
            lyricsFontWeight =
                storedLyricsFontWeight ?? Self.defaultLyricsFontWeight
        }
        let storedCurrentLineScale = defaults.object(
            forKey: Key.lyricsCurrentLineScale
        ) as? Double
        let migratedCurrentLineScale = Self.referenceLyricsValue(
            storedCurrentLineScale,
            previousDefaults: Self.previousDefaultLyricsCurrentLineScales,
            defaultValue: Self.defaultLyricsCurrentLineScale,
            appliesReferenceConfiguration: appliesReferenceCascadeConfiguration
        )
        lyricsCurrentLineScale = min(
            max(
                migratedCurrentLineScale,
                Self.lyricsCurrentLineScaleRange.lowerBound
            ),
            Self.lyricsCurrentLineScaleRange.upperBound
        )
        let storedLyricsLineSpacing = defaults.object(
            forKey: Key.lyricsLineSpacing
        ) as? Double
        lyricsLineSpacing = Self.referenceLyricsValue(
            storedLyricsLineSpacing,
            previousDefaults: Self.previousDefaultLyricsLineSpacings,
            defaultValue: Self.defaultLyricsLineSpacing,
            appliesReferenceConfiguration: appliesReferenceCascadeConfiguration
        )
        lyricsBlurIntensity = defaults.object(forKey: Key.lyricsBlurIntensity) as? Double
            ?? Self.defaultLyricsBlurIntensity
        let storedLyricsDistanceBlurScale = defaults.object(
            forKey: Key.lyricsDistanceBlurScale
        ) as? Double ?? Self.defaultLyricsDistanceBlurScale
        lyricsDistanceBlurScale = min(
            max(
                storedLyricsDistanceBlurScale,
                Self.lyricsDistanceBlurScaleRange.lowerBound
            ),
            Self.lyricsDistanceBlurScaleRange.upperBound
        )
        let storedLyricsHiddenInterfaceBlurScale = defaults.object(
            forKey: Key.lyricsHiddenInterfaceBlurScale
        ) as? Double ?? Self.defaultLyricsHiddenInterfaceBlurScale
        lyricsHiddenInterfaceBlurScale = min(
            max(
                storedLyricsHiddenInterfaceBlurScale,
                Self.lyricsDistanceBlurScaleRange.lowerBound
            ),
            Self.lyricsDistanceBlurScaleRange.upperBound
        )
        lyricsDimAmount = defaults.object(forKey: Key.lyricsDimAmount) as? Double
            ?? Self.defaultLyricsDimAmount
        lyricsTapToSeek = defaults.object(forKey: Key.lyricsTapToSeek) as? Bool ?? true
        lyricsWordByWord = defaults.object(forKey: Key.lyricsWordByWord) as? Bool ?? true
        lyricsPseudoWordByWord = defaults.object(forKey: Key.lyricsPseudoWordByWord) as? Bool ?? false
        lyricsGlowEnabled = defaults.object(forKey: Key.lyricsGlowEnabled) as? Bool ?? true
        lyricsGlowLongSyllablesOnly = defaults.object(
            forKey: Key.lyricsGlowLongSyllablesOnly
        ) as? Bool ?? Self.defaultLyricsGlowLongSyllablesOnly
        let storedLongSyllableDurationThreshold = defaults.object(
            forKey: Key.lyricsLongSyllableDurationThreshold
        ) as? Double ?? Self.defaultLyricsLongSyllableDurationThreshold
        lyricsLongSyllableDurationThreshold = min(
            max(
                storedLongSyllableDurationThreshold,
                Self.lyricsLongSyllableDurationThresholdRange.lowerBound
            ),
            Self.lyricsLongSyllableDurationThresholdRange.upperBound
        )
        lyricsGlowIntensity = defaults.object(forKey: Key.lyricsGlowIntensity) as? Double ?? 1
        lyricsTranslationEnabled = defaults.object(forKey: Key.lyricsTranslationEnabled) as? Bool ?? true
        lyricsTranslationDisplayMode = LyricsTranslationDisplayMode(
            rawValue: defaults.string(forKey: Key.lyricsTranslationDisplayMode) ?? ""
        ) ?? .focusedLine
        let storedTranslationFontScale = defaults.object(
            forKey: Key.lyricsTranslationFontScale
        ) as? Double
        lyricsTranslationFontScale = Self.referenceLyricsValue(
            storedTranslationFontScale,
            previousDefaults:
                Self.previousDefaultLyricsTranslationFontScales,
            defaultValue: Self.defaultLyricsTranslationFontScale,
            appliesReferenceConfiguration: appliesReferenceCascadeConfiguration
        )
        let storedTranslationOpacity = defaults.object(
            forKey: Key.lyricsTranslationOpacity
        ) as? Double
        lyricsTranslationOpacity = Self.referenceLyricsValue(
            storedTranslationOpacity,
            previousDefaults: Self.previousDefaultLyricsTranslationOpacities,
            defaultValue: Self.defaultLyricsTranslationOpacity,
            appliesReferenceConfiguration: appliesReferenceCascadeConfiguration
        )
        lyricsAutoFollow = defaults.object(forKey: Key.lyricsAutoFollow) as? Bool ?? true
        lyricsFollowDelay = defaults.object(forKey: Key.lyricsFollowDelay) as? Double ?? 3
        let storedLyricsFocusPosition = defaults.object(
            forKey: Key.lyricsFocusPosition
        ) as? Double
        let migratedLyricsFocusPosition = Self.referenceLyricsValue(
            storedLyricsFocusPosition,
            previousDefaults: Self.previousDefaultLyricsFocusPositions,
            defaultValue: Self.defaultLyricsFocusPosition,
            appliesReferenceConfiguration: appliesReferenceCascadeConfiguration
        )
        lyricsFocusPosition = min(
            max(
                migratedLyricsFocusPosition,
                Self.lyricsFocusPositionRange.lowerBound
            ),
            Self.lyricsFocusPositionRange.upperBound
        )
        let storedFocusCascadeDelay = defaults.object(
            forKey: Key.lyricsFocusCascadeDelay
        ) as? Double
        let migratedFocusCascadeDelay = Self.referenceLyricsValue(
            storedFocusCascadeDelay,
            previousDefaults: Self.previousDefaultLyricsFocusCascadeDelays,
            defaultValue: Self.defaultLyricsFocusCascadeDelay,
            appliesReferenceConfiguration: appliesReferenceCascadeConfiguration
        )
        lyricsFocusCascadeDelay = min(
            max(
                migratedFocusCascadeDelay,
                Self.lyricsFocusCascadeDelayRange.lowerBound
            ),
            Self.lyricsFocusCascadeDelayRange.upperBound
        )
        let storedFocusCascadeDelayIncrease = defaults.object(
            forKey: Key.lyricsFocusCascadeDelayIncrease
        ) as? Double
        let migratedFocusCascadeDelayIncrease = Self.referenceLyricsValue(
            storedFocusCascadeDelayIncrease,
            previousDefaults:
                Self.previousDefaultLyricsFocusCascadeDelayIncreases,
            defaultValue: Self.defaultLyricsFocusCascadeDelayIncrease,
            appliesReferenceConfiguration: appliesReferenceCascadeConfiguration
        )
        lyricsFocusCascadeDelayIncrease = min(
            max(
                migratedFocusCascadeDelayIncrease,
                Self.lyricsFocusCascadeDelayIncreaseRange.lowerBound
            ),
            Self.lyricsFocusCascadeDelayIncreaseRange.upperBound
        )
        let storedFocusCascadeBounceEnabled = defaults.object(
            forKey: Key.lyricsFocusCascadeBounceEnabled
        ) as? Bool
        if appliesReferenceCascadeConfiguration,
           storedFocusCascadeBounceEnabled
            == Self.previousDefaultLyricsFocusCascadeBounceEnabled {
            lyricsFocusCascadeBounceEnabled =
                Self.defaultLyricsFocusCascadeBounceEnabled
        } else {
            lyricsFocusCascadeBounceEnabled =
                storedFocusCascadeBounceEnabled
                    ?? Self.defaultLyricsFocusCascadeBounceEnabled
        }
        let storedFocusCascadeBounce = defaults.object(
            forKey: Key.lyricsFocusCascadeBounce
        ) as? Double
        let migratedFocusCascadeBounce = Self.referenceLyricsValue(
            storedFocusCascadeBounce,
            previousDefaults:
                Self.previousDefaultLyricsFocusCascadeBounces,
            defaultValue: Self.defaultLyricsFocusCascadeBounce,
            appliesReferenceConfiguration:
                appliesReferenceCascadeConfiguration
        )
        lyricsFocusCascadeBounce = min(
            max(
                migratedFocusCascadeBounce,
                Self.lyricsFocusCascadeBounceRange.lowerBound
            ),
            Self.lyricsFocusCascadeBounceRange.upperBound
        )
        lyricsFocusScaleBounceEnabled = defaults.object(
            forKey: Key.lyricsFocusScaleBounceEnabled
        ) as? Bool ?? Self.defaultLyricsFocusScaleBounceEnabled
        let storedFocusScaleBounce = defaults.object(
            forKey: Key.lyricsFocusScaleBounce
        ) as? Double
        let migratedFocusScaleBounce = Self.referenceLyricsValue(
            storedFocusScaleBounce,
            previousDefaults: Self.previousDefaultLyricsFocusScaleBounces,
            defaultValue: Self.defaultLyricsFocusScaleBounce,
            appliesReferenceConfiguration: appliesReferenceCascadeConfiguration
        )
        lyricsFocusScaleBounce = min(
            max(
                migratedFocusScaleBounce,
                Self.lyricsFocusScaleBounceRange.lowerBound
            ),
            Self.lyricsFocusScaleBounceRange.upperBound
        )
        let storedFocusScaleBounceDuration = defaults.object(
            forKey: Key.lyricsFocusScaleBounceDuration
        ) as? Double
        let migratedFocusScaleBounceDuration = Self.referenceLyricsValue(
            storedFocusScaleBounceDuration,
            previousDefaults:
                Self.previousDefaultLyricsFocusScaleBounceDurations,
            defaultValue: Self.defaultLyricsFocusScaleBounceDuration,
            appliesReferenceConfiguration: appliesReferenceCascadeConfiguration
        )
        lyricsFocusScaleBounceDuration = min(
            max(
                migratedFocusScaleBounceDuration,
                Self.lyricsFocusScaleBounceDurationRange.lowerBound
            ),
            Self.lyricsFocusScaleBounceDurationRange.upperBound
        )
        let storedFocusCascadeDuration = defaults.object(
            forKey: Key.lyricsFocusCascadeDuration
        ) as? Double
            ?? defaults.object(
                forKey: Key.legacyLyricsFocusCascadeMinimumBounceDuration
            ) as? Double
        let migratedFocusCascadeDuration = Self.referenceLyricsValue(
            storedFocusCascadeDuration,
            previousDefaults: Self.previousDefaultLyricsFocusCascadeDurations,
            defaultValue: Self.defaultLyricsFocusCascadeDuration,
            appliesReferenceConfiguration: appliesReferenceCascadeConfiguration
        )
        lyricsFocusCascadeDuration = min(
            max(
                migratedFocusCascadeDuration,
                Self.lyricsFocusCascadeDurationRange.lowerBound
            ),
            Self.lyricsFocusCascadeDurationRange.upperBound
        )
        let storedFocusSnapThreshold = defaults.object(
            forKey: Key.lyricsFocusSnapThreshold
        ) as? Double
        let migratedFocusSnapThreshold = Self.referenceLyricsValue(
            storedFocusSnapThreshold,
            previousDefaults: Self.previousDefaultLyricsFocusSnapThresholds,
            defaultValue: Self.defaultLyricsFocusSnapThreshold,
            appliesReferenceConfiguration: appliesReferenceCascadeConfiguration
        )
        lyricsFocusSnapThreshold = min(
            max(
                migratedFocusSnapThreshold,
                Self.lyricsFocusSnapThresholdRange.lowerBound
            ),
            Self.lyricsFocusSnapThresholdRange.upperBound
        )
        let storedFocusColorLeadTime = defaults.object(
            forKey: Key.lyricsFocusColorLeadTime
        ) as? Double ?? Self.defaultLyricsFocusColorLeadTime
        lyricsFocusColorLeadTime = min(
            max(
                storedFocusColorLeadTime,
                Self.lyricsFocusColorLeadTimeRange.lowerBound
            ),
            Self.lyricsFocusColorLeadTimeRange.upperBound
        )
        lyricsAdvanceTime = defaults.object(forKey: Key.lyricsAdvanceTime) as? Double ?? 0.2
        lyricsRefreshRate = LyricsRefreshRate(
            rawValue: defaults.object(forKey: Key.lyricsRefreshRate) as? Int ?? 0
        ) ?? .defaultValue
        if let storedScreenAwakeMode = defaults.string(
            forKey: Key.playerScreenAwakeMode
        ), let screenAwakeMode = PlayerScreenAwakeMode(
            rawValue: storedScreenAwakeMode
        ) {
            playerScreenAwakeMode = screenAwakeMode
        } else {
            let legacyLyricsKeepsScreenAwake = defaults.object(
                forKey: Key.legacyLyricsKeepsScreenAwake
            ) as? Bool ?? true
            playerScreenAwakeMode = legacyLyricsKeepsScreenAwake
                ? .lyrics
                : .disabled
        }
        rememberNowPlayingPage = defaults.object(forKey: Key.rememberNowPlayingPage) as? Bool ?? false
        rememberedNowPlayingPage = defaults.string(forKey: Key.rememberedNowPlayingPage) ?? "artwork"
        previousRestartsCurrentSong = defaults.object(forKey: Key.previousRestartsCurrentSong) as? Bool ?? true
        checksUpdatesOnLaunch = defaults.object(forKey: Key.checksUpdatesOnLaunch) as? Bool ?? true
        automaticallyCachesFrequentlyPlayedSongs = defaults.object(
            forKey: Key.automaticallyCachesFrequentlyPlayedSongs
        ) as? Bool ?? false
        let storedAutomaticCacheThreshold = defaults.integer(
            forKey: Key.automaticCachePlaybackThreshold
        )
        automaticCachePlaybackThreshold = Self.automaticCachePlaybackThresholdOptions.contains(
            storedAutomaticCacheThreshold
        ) ? storedAutomaticCacheThreshold : 5
        automaticCacheQuality = MusicQuality(
            rawValue: defaults.string(forKey: Key.automaticCacheQuality) ?? ""
        ) ?? .high
        defaults.set(
            Self.lyricsFocusCascadeConfigurationVersion,
            forKey: Key.lyricsFocusCascadeConfigurationVersion
        )
    }

    private static func referenceLyricsValue(
        _ storedValue: Double?,
        previousDefaults: [Double],
        defaultValue: Double,
        appliesReferenceConfiguration: Bool
    ) -> Double {
        guard let storedValue else { return defaultValue }
        guard appliesReferenceConfiguration else { return storedValue }

        let matchesPreviousDefault = previousDefaults.contains { previousDefault in
            abs(storedValue - previousDefault) < 0.000_1
        }
        return matchesPreviousDefault ? defaultValue : storedValue
    }

    func clearAccount() {
        cookie = ""
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
    }

    func resetPlayerSettings() {
        quality = .high
        playerVolumeControlMode = Self.defaultPlayerVolumeControlMode
        equalizer.reset()
        playerBackgroundBlur = 90
        playerBackgroundSaturation = 0.82
        shrinksPausedArtwork = true
        lyricsStyle = .appleMusic
        lyricsFontSize = Self.defaultLyricsFontSize
        lyricsFontWeight = Self.defaultLyricsFontWeight
        lyricsCurrentLineScale = Self.defaultLyricsCurrentLineScale
        lyricsLineSpacing = Self.defaultLyricsLineSpacing
        lyricsBlurIntensity = Self.defaultLyricsBlurIntensity
        lyricsDistanceBlurScale = Self.defaultLyricsDistanceBlurScale
        lyricsHiddenInterfaceBlurScale = Self.defaultLyricsHiddenInterfaceBlurScale
        lyricsDimAmount = Self.defaultLyricsDimAmount
        lyricsTapToSeek = true
        lyricsWordByWord = true
        lyricsPseudoWordByWord = false
        lyricsGlowEnabled = true
        lyricsGlowLongSyllablesOnly =
            Self.defaultLyricsGlowLongSyllablesOnly
        lyricsLongSyllableDurationThreshold =
            Self.defaultLyricsLongSyllableDurationThreshold
        lyricsGlowIntensity = 1
        lyricsTranslationEnabled = true
        lyricsTranslationDisplayMode = .focusedLine
        lyricsTranslationFontScale = Self.defaultLyricsTranslationFontScale
        lyricsTranslationOpacity = Self.defaultLyricsTranslationOpacity
        lyricsAutoFollow = true
        lyricsFollowDelay = 3
        lyricsFocusPosition = Self.defaultLyricsFocusPosition
        lyricsFocusCascadeDelay = Self.defaultLyricsFocusCascadeDelay
        lyricsFocusCascadeDelayIncrease =
            Self.defaultLyricsFocusCascadeDelayIncrease
        lyricsFocusCascadeBounceEnabled = Self.defaultLyricsFocusCascadeBounceEnabled
        lyricsFocusCascadeBounce = Self.defaultLyricsFocusCascadeBounce
        lyricsFocusScaleBounceEnabled = Self.defaultLyricsFocusScaleBounceEnabled
        lyricsFocusScaleBounce = Self.defaultLyricsFocusScaleBounce
        lyricsFocusScaleBounceDuration =
            Self.defaultLyricsFocusScaleBounceDuration
        lyricsFocusCascadeDuration = Self.defaultLyricsFocusCascadeDuration
        lyricsFocusSnapThreshold = Self.defaultLyricsFocusSnapThreshold
        lyricsFocusColorLeadTime = Self.defaultLyricsFocusColorLeadTime
        lyricsAdvanceTime = 0.2
        lyricsRefreshRate = .defaultValue
        textPV.reset()
        floatingLyrics.reset()
        playerScreenAwakeMode = .lyrics
        rememberNowPlayingPage = false
        rememberedNowPlayingPage = "artwork"
        previousRestartsCurrentSong = true
        skylineLyrics.reset()
    }
}
