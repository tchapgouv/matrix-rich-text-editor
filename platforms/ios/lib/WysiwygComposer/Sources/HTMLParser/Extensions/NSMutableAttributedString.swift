//
// Copyright 2024 New Vector Ltd.
// Copyright 2023 The Matrix.org Foundation C.I.C
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE in the repository root for full details.
//

import DTCoreText
import UIKit

extension NSMutableAttributedString {
    /// Apply all custom attributes expected by the composer's `UITextView` on self.
    ///
    /// - Parameters:
    ///   - style: Style for HTML parsing.
    func applyPostParsingCustomAttributes(style: HTMLParserStyle) {
        addAttributes(
            [.foregroundColor: style.textColor], range: NSRange(location: 0, length: length)
        )

        // This fixes an iOS bug where if some text is typed after a link, and then a whitespace is added the link color is overridden.
        enumerateTypedAttribute(.link) { (_: URL, range: NSRange, _) in
            removeAttribute(.underlineStyle, range: range)
            removeAttribute(.underlineColor, range: range)
            addAttributes([.foregroundColor: style.linkColor], range: range)
        }

        removeParagraphVerticalSpacing()
        applyBackgroundStyles(style: style)
        applyInlineCodeBackgroundStyle(codeBackgroundColor: style.codeBlockStyle.backgroundColor)
        replacePlaceholderTexts()
        applyDiscardableToListPrefixes()
    }

    /// Replace parts of the attributed string that represents mentions by
    /// a new attributed string part provided by the hosting app `MentionReplacer`.
    ///
    /// - Parameter mentionReplacer: The mention replacer providing new attributed strings.
    func replaceMentions(with mentionReplacer: HTMLMentionReplacer?) {
        enumerateTypedAttribute(.mention) { (originalContent: MentionContent, range: NSRange, _) in
            if let replacement = mentionReplacer?.replacementForMention(
                originalContent.url,
                text: self.mutableString.substring(with: range)
            ) {
                self.replaceCharacters(in: range, with: replacement)
                // TODO: find a way to avoid re-applying the attribute (make the replacement mutable ?)
                self.addAttribute(.mention,
                                  value: originalContent,
                                  range: NSRange(location: range.location, length: replacement.length))
            }
        }
    }
}

private extension NSMutableAttributedString {
    /// Remove the vertical spacing for paragraphs in the entire attributed string.
    func removeParagraphVerticalSpacing() {
        enumerateTypedAttribute(.paragraphStyle) { (style: NSParagraphStyle, range: NSRange, _) in
            let mutableStyle = style.mut()
            mutableStyle.paragraphSpacing = 0
            mutableStyle.paragraphSpacingBefore = 0
            addAttribute(.paragraphStyle, value: mutableStyle as Any, range: range)
        }
    }

    /// Sets the background style for detected quote & code blocks within the attributed string.
    ///
    /// - Parameters:
    ///   - style: Style for HTML parsing.
    func applyBackgroundStyles(style: HTMLParserStyle) {
        enumerateTypedAttribute(.DTTextBlocks) { (value: NSArray, range: NSRange, _) in
            guard let textBlock = value.firstObject as? DTTextBlock else { return }
            switch textBlock.backgroundColor {
            case TempColor.codeBlock:
                addAttributes(style.codeBlockStyle.attributes, range: range)
                mutableString.replaceOccurrences(of: String.carriageReturn, with: String.lineSeparator, range: range.excludingLast)
                // Remove inline code background color, if it exists.
                removeAttribute(.backgroundColor, range: range)
            case TempColor.quote:
                addAttributes(style.quoteBlockStyle.attributes, range: range)
                mutableString.replaceOccurrences(of: String.lineFeed, with: String.lineSeparator, range: range.excludingLast)
            default:
                break
            }
        }
    }

    /// Sets the background style for detected inline code within the attributed string.
    ///
    /// - Parameters:
    ///   - codeBackgroundColor: the background color that should be applied to inline code
    func applyInlineCodeBackgroundStyle(codeBackgroundColor: UIColor) {
        enumerateTypedAttribute(.backgroundColor) { (color: UIColor, range: NSRange, _) in
            guard color == TempColor.inlineCode else { return }

            // Note: for now inline code just uses standard NSAttributedString background color
            // to avoid issues where it spans accross multiple lines.
            addAttribute(.backgroundColor, value: codeBackgroundColor, range: range)
        }
    }

    /// Finds any text that has been marked as discardable and replaces it with ZWSP
    func replacePlaceholderTexts() {
        enumerateTypedAttribute(.discardableText) { (discardable: Bool, range: NSRange, _) in
            guard discardable == true else { return }
            self.replaceCharacters(in: range, with: String.zwsp)
        }
    }

    /// Finds any list prefix field inside the string and mark them as discardable text.
    func applyDiscardableToListPrefixes() {
        enumerateTypedAttribute(.DTField) { (_: String, range: NSRange, _) in
            addAttribute(.discardableText, value: true, range: range)
        }
    }
}
