import 'package:angular_compiler/v1/src/compiler/selector.dart';

/// CSS selectors that are not required to have a matching element in
/// `directives: [ ... ]`.
///
/// This list represents CSS selectors that would normally issue a compile-time
/// diagnostic, but are commonly used in ACX widgets to represent a form of
/// pseudo-custom elements (e.g. for CSS styling).
/// Most unmatched elements should instead use `@skipSchemaValidationFor`
/// (go/angulardart/dev/syntax#annotations).
const List<String> _selectorAllowlist = [
  // A selector for elevation.scss.
  '[animated]',
  // A selector for material-table element's particle elements.
  '[delegate-events]',
  // A selector for charts_web library.
  '[drawState]',
  // A selector for elevation.scss.
  '[elevation]',
  // A selector used in material-list element's descendant elements.
  '[group]',
  // A selector used in filter-bar element's descendant elements.
  '[inside-filter-bar]',
  // A selector used in filter-bar element's descendant elements.
  '[inside-menu-suggest-input]',
  // A selector used in material-list element's descendant elements.
  '[label]',
  // A selector used in filter-bar element's descendant elements.
  '[popup-inside-filter-bar]',
  // A selector used in scrollable-cards element's descendant elements.
  '[scrollable-card]',
  // Javascript web chart library.
  'aplos-chart',
  'button[dense]',
  'button[disabled]',
  'button[filled]',
  'button[hairline]',
  'button[icon]',
  'button[iconText]',
  'button[raised]',
  'form[ngNoForm]',
  'ess-particle-table',
  'glyph[baseline]',
  'glyph[flip]',
  'glyph[light]',
  'glyph[size]',
  'help-tooltip-icon[baseline]',
  'material-button[clear-size]',
  'material-button[compact]',
  'material-button[dense]',
  'material-button[disabled]',
  'material-button[filled]',
  'material-button[hairline]',
  'material-button[icon]',
  'material-button[iconText]',
  'material-button[no-ink]',
  'material-button[no-separator]',
  'material-button[raised]',
  'material-button[text]',
  'material-checkbox[no-ink]',
  'material-chip[emphasis]',
  'material-chip[gm]',
  'material-chip[m1]',
  'material-chips[gm]',
  'material-chips[m1]',
  'material-content',
  'material-dialog[headered]',
  'material-dialog[info]',
  'material-drawer',
  'material-drawer[end]',
  'material-drawer[overlay]',
  'material-drawer[permanent]',
  'material-expansionpanel[flat]',
  'material-expansionpanel[wide]',
  'material-fab[blue]',
  'material-fab[disabled]',
  'material-fab[extended]',
  'material-fab[lowered]',
  'material-fab[mini]',
  'material-fab[raised]',
  'material-icon[baseline]',
  'material-icon[flip]',
  'material-icon[gm]',
  'material-icon[icon]',
  'material-icon[light]',
  'material-icon[size]',
  'material-input[multiline]',
  'material-list[min-size]',
  'material-list[size]',
  'material-radio[no-ink]',
  'material-ripple[programmatic]',
  'material-tab-panel[centerStrip]',
  'material-yes-no-buttons[dense]',
  'material-yes-no-buttons[reverse]',
  'material-shadow',
  // A scss component in ACX.
  'notification-badge',
  // material_table/lib/src/dom/relative_element_holder.dart
  'relative-elements-container',
  'scrolling-material-tab-strip[primary-tab-style]',
  'tab-button[primary-tab-style]',
];

/// A custom event list in ACX.
///
/// This list represents an Element and an event pair that would normally
/// issue a compile-time diagnostic, but are commonly used in ACX widgets to
/// represent a custom event.
/// The format is `<Element>:<Custom Event>`.
/// Most unmatched events should instead use `@skipSchemaValidationFor`
/// (go/angulardart/dev/syntax#annotations).
const List<String> _customEvents = [
  'expand-header-icon:header-expansion',
  'material-table:row-selection',
];

/// A validator consuming a list of [CssSelector]s that has ability to verify
/// whether an element or an attribute of a specified element exists.
///
/// `_MissingDirectiveValidator` issues a warning when an element or an
/// attribute isn't native, nor matches a bound directive's selector or inputs.
/// Some elements and attributes created in ACX are used for CSS styling, and
/// this validator generates an allowlist for them.
final Iterable<List<CssSelector>> _selectors =
    _selectorAllowlist.map((selector) => CssSelector.parse(selector)).toList();

bool hasElementInAllowlist(String name) =>
    _selectors.any((selectors) => selectors
        .any((selector) => selector.element == name && selector.attrs.isEmpty));

bool hasAttributeInAllowlist(String name, String attr) =>
    _selectors.any((selectors) => selectors.any((selector) =>
        (selector.element == name || selector.element == null) &&
        selector.attrs.any((matcher) => matcher.name == attr)));

bool hasEventInAllowlist(String name, String event) =>
    _customEvents.contains('$name:$event');
