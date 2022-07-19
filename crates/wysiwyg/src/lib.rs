// Copyright 2022 The Matrix.org Foundation C.I.C.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

mod bytelocation;
mod codepoint_delta;
mod codepoint_location;
mod composer_action;
mod composer_model;
mod composer_update;
mod menu_state;
mod text_update;
mod utf16_codeunit_location;

pub use crate::bytelocation::ByteLocation;
pub use crate::codepoint_delta::CodepointDelta;
pub use crate::codepoint_location::CodepointLocation;
pub use crate::composer_action::ActionRequest;
pub use crate::composer_action::ActionResponse;
pub use crate::composer_action::ComposerAction;
pub use crate::composer_model::ComposerModel;
pub use crate::composer_update::ComposerUpdate;
pub use crate::menu_state::MenuState;
pub use crate::text_update::ReplaceAll;
pub use crate::text_update::TextUpdate;
pub use crate::utf16_codeunit_location::Utf16CodeunitLocation;
