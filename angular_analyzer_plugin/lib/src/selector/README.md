# Selectors

CSS selectors in the angular plugin all extend Selector from
`lib/src/selector/selector.dart`. Through compound selectors like `AndSelector`
and `OrSelector` they form an AST.

You can parse CSS selectors with `SelectorParser` in
`lib/src/selector/parser.dart`, and catch `SelectorParseError`s.

Each selector implements a number of common features, such as checking if they
match an `ElementView`, seeing if they *potentially* will match one (for
suggesting attributes in autocompletion) and managing a constraint-based tag
building system using `HtmlTagForSelector` to suggest whole tags that satisfy
`<ng-content>`s. This is all documented on the base class of `Selector`.

Note that we don't merely match CSS selectors against an `ElementView`, we need
to do a few extra special things: we need to know if we got a tag match or a
non-tag match (to report "unmatched tag" errors correctly), and we also record
offset information about which selectors matched which part of which templates
in order to provide click-through navigation afterwards.

Currently, parsing is done mostly via regex. Unfortunately, the CSS standard
doesn't have particularly simple tokenization. I have looked at, for instance,
the mozilla implementation CSS parser and it is mostly a hand-written state
machine. Regex is just a means of writing state machines as well, however, we're
pushing the limits here of what regex can cleanly do, and it could stand to be
switched to a hand-written state machine which may result in cleaner code. In
the mean time, pay extra care to modifying anything in `regex.dart`, and note
that the token types `ContainsString`, `Value`, and `Operator` are all,
unfortunately, handled a little specially. This is therefore mostly, but not
entirely, decoupled from the parser.
