/// A pattern that recognizes a commonly useful subset of URLs that are safe.
///
/// This regular expression matches a subset of URLs that will not cause script
/// execution if used in URL context within a HTML document. Specifically, this
/// regular expression matches if (comment from here on and regex copied from
/// Soy's EscapingConventions):
/// (1) Either a protocol in a whitelist (http, https, mailto or ftp).
/// (2) or no protocol.  A protocol must be followed by a colon. The below
///     allows that by allowing colons only after one of the characters [/?#].
///     A colon after a hash (#) must be in the fragment.
///     Otherwise, a colon after a (?) must be in a query.
///     Otherwise, a colon after a single solidus (/) must be in a path.
///     Otherwise, a colon after a double solidus (//) must be in the authority
///     (before port).
///
/// The pattern disallows &, used in HTML entity declarations before
/// one of the characters in [/?#]. This disallows HTML entities used in the
/// protocol name, which should never happen, e.g. "h&#116;tp" for "http".
/// It also disallows HTML entities in the first path part of a relative path,
/// e.g. "foo&lt;bar/baz".  Our existing escaping functions should not produce
/// that. More importantly, it disallows masking of a colon,
/// e.g. "javascript&#58;...".
///
/// RegExp Source: Closure sanitization library.
final RegExp SAFE_URL_PATTERN = new RegExp(
    '^(?:(?:https?|mailto|ftp|tel|file):|[^&:/?#]*(?:[/?#]|\$))',
    caseSensitive: false);

final RegExp SAFE_SRCSET_PATTERN = new RegExp(
    '^(?:(?:https?|file):|[^&:/?#]*(?:[/?#]|\$))',
    caseSensitive: false);

final RegExp DATA_URL_PATTERN = new RegExp(
    '^data:(?:image\/(?:bmp|gif|'
    'jpeg|jpg|png|tiff|webp)|video\/(?:mpeg|mp4|ogg|webm));'
    'base64,[a-z0-9+\/]+=*\$',
    caseSensitive: false);

String internalSanitizeUrl(String url) {
  if (url.isEmpty) return url;
  return (SAFE_URL_PATTERN.hasMatch(url) || DATA_URL_PATTERN.hasMatch(url))
      ? url
      : 'unsafe:$url';
}

String internalSanitizeSrcset(String srcset) {
  return srcset
      .split(',')
      .map((String s) => internalSanitizeUrl(s.trim()))
      .join(', ');
}
