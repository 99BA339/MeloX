import CoreText
import SwiftUI
import UIKit

enum TimedLyricTextBuilder {
    static func text(
        from syllables: [LyricSyllable],
        constrainedWidth: CGFloat?,
        fontSize: CGFloat,
        fontWeight: LyricsFontWeight = .bold
    ) -> Text {
        let characters = timedCharacters(from: syllables)
        let source = characters.map(\.text).joined()
        let lineBreakOffsets = lineBreakCharacterOffsets(
            in: source,
            constrainedWidth: constrainedWidth,
            fontSize: fontSize,
            fontWeight: fontWeight
        )

        return characters.enumerated().reduce(Text(verbatim: "")) {
            result,
            entry in
            var text = result
            let offset = entry.offset
            if lineBreakOffsets.contains(offset),
               offset > 0,
               !characters[offset - 1].isLineBreak {
                text = Text("\(text)\(Text(verbatim: "\n"))")
            }

            let character = entry.element
            let fragment = Text(verbatim: character.text).customAttribute(
                LyricTimingTextAttribute(
                    startTime: character.startTime,
                    endTime: character.endTime,
                    syllableStartTime: character.syllableStartTime,
                    syllableEndTime: character.syllableEndTime,
                    characterIndex: character.characterIndex,
                    characterCount: character.characterCount
                )
            )
            return Text("\(text)\(fragment)")
        }
    }

    private static func timedCharacters(
        from syllables: [LyricSyllable]
    ) -> [TimedCharacter] {
        syllables.flatMap { syllable -> [TimedCharacter] in
            let characters = Array(syllable.text)
            guard !characters.isEmpty else { return [] }

            let duration = max(
                syllable.endTime - syllable.startTime,
                0
            )
            let characterDuration = duration / Double(characters.count)

            return characters.enumerated().map { entry in
                let startTime = syllable.startTime
                    + Double(entry.offset) * characterDuration
                let endTime = entry.offset == characters.count - 1
                    ? max(syllable.endTime, startTime)
                    : startTime + characterDuration
                return TimedCharacter(
                    text: String(entry.element),
                    startTime: startTime,
                    endTime: endTime,
                    syllableStartTime: syllable.startTime,
                    syllableEndTime: syllable.endTime,
                    characterIndex: entry.offset,
                    characterCount: characters.count
                )
            }
        }
    }

    private static func lineBreakCharacterOffsets(
        in source: String,
        constrainedWidth: CGFloat?,
        fontSize: CGFloat,
        fontWeight: LyricsFontWeight
    ) -> Set<Int> {
        guard !source.isEmpty,
              let constrainedWidth,
              constrainedWidth.isFinite,
              constrainedWidth > 0,
              fontSize.isFinite,
              fontSize > 0 else {
            return []
        }

        let uiFont = UIFont.systemFont(
            ofSize: fontSize,
            weight: fontWeight.uiKitWeight
        )
        let layoutFont = CTFontCreateWithName(
            uiFont.fontName as CFString,
            fontSize,
            nil
        )
        let attributedText = NSMutableAttributedString(
            string: source,
            attributes: [
                NSAttributedString.Key(kCTFontAttributeName as String):
                    layoutFont,
                NSAttributedString.Key(kCTLigatureAttributeName as String):
                    0,
            ]
        )
        addTimedRunBoundaries(to: attributedText, source: source)
        let typesetter = CTTypesetterCreateWithAttributedString(
            attributedText
        )
        let utf16Length = attributedText.length
        var utf16Offset = 0
        var result: Set<Int> = []
        let layoutWidth = effectiveLayoutWidth(
            source: source,
            constrainedWidth: constrainedWidth,
            fontSize: fontSize
        )

        while utf16Offset < utf16Length {
            let suggestedLength = CTTypesetterSuggestLineBreak(
                typesetter,
                utf16Offset,
                Double(layoutWidth)
            )
            let consumedLength = max(
                suggestedLength,
                nextCharacterLength(
                    in: source,
                    atUTF16Offset: utf16Offset
                )
            )
            let nextOffset = min(
                utf16Offset + consumedLength,
                utf16Length
            )
            guard nextOffset > utf16Offset else { break }
            utf16Offset = nextOffset

            if utf16Offset < utf16Length,
               let characterOffset = characterOffset(
                    in: source,
                    utf16Offset: utf16Offset
               ),
               characterOffset > 0 {
                result.insert(characterOffset)
            }
        }
        return result
    }

    private static func effectiveLayoutWidth(
        source: String,
        constrainedWidth: CGFloat,
        fontSize: CGFloat
    ) -> CGFloat {
        let containsLatinText = source.unicodeScalars.contains { scalar in
            (65...90).contains(scalar.value)
                || (97...122).contains(scalar.value)
        }
        let containsWordSpacing = source.contains { $0.isWhitespace }
        let safetyMargin: CGFloat
        if containsLatinText, containsWordSpacing {
            // SwiftUI's individually attributed Latin glyph runs measure
            // wider than Core Text's typesetter near word boundaries.
            safetyMargin = max(
                constrainedWidth * 0.05,
                fontSize * 0.5
            )
        } else {
            safetyMargin = max(fontSize * 0.02, 0.5)
        }
        return max(constrainedWidth - safetyMargin, 1)
    }

    private static func addTimedRunBoundaries(
        to attributedText: NSMutableAttributedString,
        source: String
    ) {
        let runBoundaryAttribute = NSAttributedString.Key(
            "MeloXTimedLyricRunBoundary"
        )
        var utf16Offset = 0
        for (characterOffset, character) in source.enumerated() {
            let utf16Length = String(character).utf16.count
            attributedText.addAttribute(
                runBoundaryAttribute,
                value: characterOffset,
                range: NSRange(
                    location: utf16Offset,
                    length: utf16Length
                )
            )
            utf16Offset += utf16Length
        }
    }

    private static func nextCharacterLength(
        in source: String,
        atUTF16Offset offset: Int
    ) -> Int {
        guard offset < source.utf16.count else { return 0 }
        let range = (source as NSString).rangeOfComposedCharacterSequence(
            at: offset
        )
        return max(range.location + range.length - offset, 1)
    }

    private static func characterOffset(
        in source: String,
        utf16Offset: Int
    ) -> Int? {
        let utf16 = source.utf16
        guard let utf16Index = utf16.index(
            utf16.startIndex,
            offsetBy: utf16Offset,
            limitedBy: utf16.endIndex
        ),
        let stringIndex = String.Index(utf16Index, within: source) else {
            return nil
        }
        return source.distance(from: source.startIndex, to: stringIndex)
    }
}

private extension TimedLyricTextBuilder {
    struct TimedCharacter {
        let text: String
        let startTime: TimeInterval
        let endTime: TimeInterval
        let syllableStartTime: TimeInterval
        let syllableEndTime: TimeInterval
        let characterIndex: Int
        let characterCount: Int

        var isLineBreak: Bool {
            text == "\n" || text == "\r" || text == "\r\n"
        }
    }
}
