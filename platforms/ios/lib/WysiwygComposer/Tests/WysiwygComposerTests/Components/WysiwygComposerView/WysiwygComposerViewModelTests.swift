//
// Copyright 2024 New Vector Ltd.
// Copyright 2022 The Matrix.org Foundation C.I.C
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE in the repository root for full details.
//

import Combine
@testable import WysiwygComposer
import XCTest

final class WysiwygComposerViewModelTests: XCTestCase {
    var viewModel: WysiwygComposerViewModel!

    override func setUpWithError() throws {
        viewModel = WysiwygComposerViewModel()
        viewModel.clearContent()
    }

    func testIsContentEmpty() throws {
        XCTAssertTrue(viewModel.isContentEmpty)

        let expectFalse = expectContentEmpty(false)
        _ = viewModel.replaceText(range: .zero,
                                  replacementText: "Test")
        viewModel.textView.attributedText = viewModel.attributedContent.text
        waitExpectation(expectation: expectFalse, timeout: 2.0)

        let expectTrue = expectContentEmpty(true)
        _ = viewModel.replaceText(range: .init(location: 0, length: viewModel.attributedContent.text.length),
                                  replacementText: "")
        viewModel.textView.attributedText = viewModel.attributedContent.text
        waitExpectation(expectation: expectTrue, timeout: 2.0)
    }
    
    func testIsContentEmptyAfterDeletingSingleSpace() {
        // When typing a single space.
        _ = viewModel.replaceText(range: .zero, replacementText: " ")
        viewModel.textView.attributedText = NSAttributedString(string: " ")
        viewModel.didUpdateText()
        
        // And then deleting that space.
        _ = viewModel.replaceText(range: .init(location: 0, length: 1), replacementText: "")
        viewModel.textView.attributedText = NSAttributedString(string: "")
        viewModel.didUpdateText()
        
        // Then the content should be empty for the placeholder to be shown.
        XCTAssertTrue(viewModel.isContentEmpty)
    }
    
    func testIsContentEmptyAfterDeletingMultilineContent() {
        // When typing a new line.
        _ = viewModel.replaceText(range: .zero, replacementText: "\n")
        viewModel.textView.attributedText = NSAttributedString(string: "\n")
        viewModel.didUpdateText()
        
        // And then deleting that new line.
        _ = viewModel.replaceText(range: .init(location: 0, length: 1), replacementText: "")
        viewModel.textView.attributedText = NSAttributedString(string: "")
        viewModel.didUpdateText()
        
        // Then the content should be empty for the placeholder to be shown.
        XCTAssertTrue(viewModel.isContentEmpty)
    }

    func testSimpleTextInputIsAccepted() throws {
        let shouldChange = viewModel.replaceText(range: .zero,
                                                 replacementText: "A")
        XCTAssertTrue(shouldChange)
    }

    func testSimpleTextInputIsNotAccepted() throws {
        viewModel.shouldReplaceText = false
        let shouldChange = viewModel.replaceText(range: .zero,
                                                 replacementText: "A")
        XCTAssertFalse(shouldChange)
    }

    func testNewlineIsNotAccepted() throws {
        let shouldChange = viewModel.replaceText(range: .zero,
                                                 replacementText: "\n")
        XCTAssertFalse(shouldChange)
    }

    func testReconciliateModel() {
        _ = viewModel.replaceText(range: .zero,
                                  replacementText: "wa")
        XCTAssertEqual(viewModel.attributedContent.text.string, "wa")
        XCTAssertEqual(viewModel.attributedContent.selection, NSRange(location: 2, length: 0))
        reconciliate(to: "わ", selectedRange: NSRange(location: 1, length: 0))
        XCTAssertEqual(viewModel.attributedContent.text.string, "わ")
        XCTAssertEqual(viewModel.attributedContent.selection, NSRange(location: 1, length: 0))
    }

    func testReconciliateRestoresSelection() {
        _ = viewModel.replaceText(range: .zero, replacementText: "I\'m")
        XCTAssertEqual(viewModel.attributedContent.selection, NSRange(location: 3, length: 0))
        reconciliate(to: "I’m", selectedRange: NSRange(location: 3, length: 0))
        XCTAssertEqual(viewModel.attributedContent.selection, NSRange(location: 3, length: 0))

        viewModel.clearContent()

        _ = viewModel.replaceText(range: .zero, replacementText: "Some text")
        viewModel.select(range: .zero)
        XCTAssertEqual(viewModel.attributedContent.selection, .zero)
        reconciliate(to: "Some test", selectedRange: .zero)
        XCTAssertEqual(viewModel.attributedContent.selection, .zero)
    }

    func testReconciliateRestoresFromModel() {
        _ = viewModel.replaceText(range: .zero, replacementText: "Some text")
        viewModel.textView.attributedText = NSAttributedString(string: "Some text")
        reconciliate(to: "Home test", selectedRange: .zero)
        XCTAssertEqual(viewModel.textView.text, "Some text")
    }

    func testPlainTextMode() {
        _ = viewModel.replaceText(range: .zero,
                                  replacementText: "Some bold text")
        viewModel.textView.attributedText = NSAttributedString(string: "Some bold text")
        viewModel.select(range: .init(location: 10, length: 4))
        viewModel.apply(.bold)

        XCTAssertEqual(viewModel.content.html, "Some bold <strong>text</strong>")

        viewModel.plainTextMode = true
        XCTAssertEqual(viewModel.content.markdown, "Some bold __text__")
        XCTAssertEqual(viewModel.content.html, "Some bold <strong>text</strong>")

        viewModel.plainTextMode = false
        XCTAssertEqual(viewModel.content.html, "Some bold <strong>text</strong>")
    }
    
    func testReplaceTextAfterLinkIsNotAccepted() {
        viewModel.applyLinkOperation(.createLink(urlString: "https://element.io", text: "test"))
        let result = viewModel.replaceText(range: .init(location: 4, length: 0), replacementText: "abc")
        XCTAssertFalse(result)
        XCTAssertEqual(viewModel.content.html, "<a href=\"https://element.io\">test</a>abc")
        XCTAssertTrue(viewModel.textView.attributedText.isEqual(to: viewModel.attributedContent.text) == true)
    }
    
    func testReplaceTextPartiallyInsideAndAfterLinkIsNotAccepted() {
        viewModel.applyLinkOperation(.createLink(urlString: "https://element.io", text: "test"))
        let result = viewModel.replaceText(range: .init(location: 3, length: 1), replacementText: "abc")
        XCTAssertFalse(result)
        XCTAssertEqual(viewModel.content.html, "<a href=\"https://element.io\">tes</a>abc")
        XCTAssertTrue(viewModel.textView.attributedText.isEqual(to: viewModel.attributedContent.text) == true)
    }
    
    func testReplaceTextInsideLinkIsAccepted() {
        viewModel.applyLinkOperation(.createLink(urlString: "https://element.io", text: "test"))
        let result = viewModel.replaceText(range: .init(location: 2, length: 0), replacementText: "abc")
        XCTAssertTrue(result)
        XCTAssertEqual(viewModel.content.html, "<a href=\"https://element.io\">teabcst</a>")
    }

    func testCrashRecoveryUsesLatestPlainText() {
        viewModel.setHtmlContent("<strong>Some <em>text</em></strong>")
        // Force a crash
        viewModel.setHtmlContent("<//strong>")
        XCTAssertEqual(viewModel.content.html, "Some text")
    }

    func testPendingFormatIsReapplied() {
        viewModel.apply(.orderedList)
        viewModel.apply(.bold)
        viewModel.apply(.italic)
        mockTrailingTyping("Formatted")
        // Enter
        mockTrailingTyping("\n")
        mockTrailingTyping("Still formatted")
        XCTAssertTrue(
            viewModel
                .textView
                .attributedText
                .fontSymbolicTraits(at: viewModel.textView.attributedText.length - 1)
                .contains([.traitBold, .traitItalic])
        )
    }

    func testPendingFormatFlagInNewList() {
        viewModel.apply(.bold)
        viewModel.apply(.italic)
        mockTrailingTyping("Text")
        viewModel.enter()
        // After creating a list, pending format flag is on
        viewModel.apply(.orderedList)
        XCTAssertTrue(viewModel.hasPendingFormats)
        // Typing consumes the flag
        mockTrailingTyping("Item")
        XCTAssertFalse(viewModel.hasPendingFormats)
        // Creating a second list item re-enables the flag
        viewModel.enter()
        XCTAssertTrue(viewModel.hasPendingFormats)
    }

    func testPendingFormatFlagAfterReselectingListItem() {
        viewModel.apply(.bold)
        viewModel.apply(.italic)
        mockTrailingTyping("Text1")
        viewModel.enter()
        viewModel.apply(.orderedList)
        let inListSelection = viewModel.attributedContent.selection
        let insertedText = "Text2"
        mockTyping(insertedText, at: 0)
        // After re-selecting the empty list item, pending format flag is still on
        viewModel.select(range: NSRange(location: inListSelection.location + insertedText.utf16Length,
                                        length: inListSelection.length))
        XCTAssertTrue(viewModel.hasPendingFormats)
    }
}

// MARK: - WysiwygTestExpectation

extension WysiwygComposerViewModelTests {
    /// Defines a test expectation.
    struct WysiwygTestExpectation {
        let value: XCTestExpectation
        let cancellable: AnyCancellable
    }

    /// Wait for an expectation to be fulfilled.
    ///
    /// - Parameters:
    ///   - expectation: Expectation to fulfill.
    ///   - timeout: Timeout for failure.
    func waitExpectation(expectation: WysiwygTestExpectation, timeout: TimeInterval) {
        wait(for: [expectation.value], timeout: timeout)
        expectation.cancellable.cancel()
    }

    /// Create an expectation for empty content status to be published by the view model.
    ///
    /// - Parameters:
    ///   - expectedIsContentEmpty: Expected `isContentEmpty` value.
    ///   - description: Description for expectation.
    /// - Returns: Expectation to be fulfilled. Can be used with `waitExpectation`.
    func expectContentEmpty(_ expectedIsContentEmpty: Bool,
                            description: String = "Await isContentEmpty") -> WysiwygTestExpectation {
        let expectation = expectation(description: description)
        let cancellable = viewModel.$isContentEmpty
            // Ignore on subscribe publish.
            .removeDuplicates()
            .dropFirst()
            .sink(receiveValue: { isContentEmpty in
                // Assert the plain text,
                XCTAssertEqual(
                    isContentEmpty,
                    expectedIsContentEmpty
                )
                expectation.fulfill()
            })
        return WysiwygTestExpectation(value: expectation, cancellable: cancellable)
    }
}

// MARK: - Helpers

extension WysiwygComposerViewModelTests {
    /// Mock typing at given location.
    ///
    /// - Parameters:
    ///   - text: text to type
    ///   - location: index in text view's attributed string
    func mockTyping(_ text: String, at location: Int) {
        guard location <= viewModel.textView.attributedText.length else {
            fatalError("Invalid location index")
        }

        let range = NSRange(location: location, length: 0)
        let shouldAcceptChange = viewModel.replaceText(range: range, replacementText: text)
        if shouldAcceptChange {
            // Force apply since the text view should've updated by itself
            viewModel.applyAtributedContent()
            viewModel.didUpdateText()
        }
    }

    /// Mock typing trailing text.
    ///
    /// - Parameter text: text to type
    func mockTrailingTyping(_ text: String) {
        mockTyping(text, at: viewModel.textView.attributedText.length)
    }

    /// Mock backspacing at given location.
    ///
    /// - Parameter location: index in text view's attributed string
    func mockBackspace(at location: Int) {
        guard location <= viewModel.textView.attributedText.length else {
            fatalError("Invalid location index")
        }

        let range: NSRange = location == 0 ? .zero : NSRange(location: location - 1, length: 1)
        let shouldAcceptChange = viewModel.replaceText(range: range, replacementText: "")
        if shouldAcceptChange {
            // Force apply since the text view should've updated by itself
            viewModel.applyAtributedContent()
            viewModel.didUpdateText()
        }
    }

    /// Mock backspacing from trailing position.
    func mockTrailingBackspace() {
        mockBackspace(at: viewModel.textView.attributedText.length)
    }
}

private extension WysiwygComposerViewModelTests {
    /// Fakes a trigger of the reconciliate mechanism of the view model.
    ///
    /// - Parameters:
    ///   - newText: New text to apply.
    ///   - selectedRange: Simulated selection in the text view.
    func reconciliate(to newText: String, selectedRange: NSRange) {
        viewModel.textView.attributedText = NSAttributedString(string: newText)
        // Set selection where we want it, as setting the content automatically moves cursor to the end.
        viewModel.textView.selectedRange = selectedRange
        viewModel.didUpdateText()
    }
}
