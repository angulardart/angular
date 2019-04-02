/// Whether a selector matched, and whether it matched the tag.
///
/// This is important because we need to know when a selector matched a tag
/// in the general sense, but also if that tag's name was matched, so that we
/// can provide "unknown tag name" errors.
///
/// Note that we don't currently show any "unknown attribute name" errors, so
/// this is sufficient for now.
enum SelectorMatch { NoMatch, NonTagMatch, TagMatch }
