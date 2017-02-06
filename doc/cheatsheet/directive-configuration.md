@cheatsheetSection
Directive configuration
@cheatsheetIndex 5
@description
`@Directive(property1: value1, ...)`

@cheatsheetItem
syntax:
`selector: '.cool-button:not(a)'`|`selector:`
description:
Specifies a CSS selector that identifies this directive within a template. Supported selectors include `element`,
`[attribute]`, `.class`, and `:not()`.

Does not support parent-child relationship selectors.

See: [Structural Directives](/angular/guide/structural-directives),
[selector property](/angular/api/angular2.core/Directive/selector)


@cheatsheetItem
syntax:
`providers: [MyService, provide(...)]`|`providers:`
description:
List of dependency injection providers for this directive and its children.

See:
[Attribute Directives](/angular/guide/attribute-directives),
[Structural Directives](/angular/guide/structural-directives),
[providers property](/angular/api/angular2.core/Directive/providers)
