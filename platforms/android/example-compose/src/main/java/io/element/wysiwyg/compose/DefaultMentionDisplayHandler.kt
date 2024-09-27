/*
 * Copyright 2024 New Vector Ltd.
 * Copyright 2024 The Matrix.org Foundation C.I.C.
 *
 * SPDX-License-Identifier: AGPL-3.0-only
 * Please see LICENSE in the repository root for full details.
 */

package io.element.wysiwyg.compose

import io.element.android.wysiwyg.display.MentionDisplayHandler
import io.element.android.wysiwyg.display.TextDisplay

class DefaultMentionDisplayHandler : MentionDisplayHandler {

    override fun resolveMentionDisplay(
        text: String, url: String
    ): TextDisplay {
        return TextDisplay.Pill
    }

    override fun resolveAtRoomMentionDisplay(): TextDisplay {
        return TextDisplay.Pill
    }
}
