@cheatsheetSection
Component configuration
@cheatsheetIndex 6
@description
`@Component` extends `@Directive`,
so the `@Directive` configuration applies to components as well

@cheatsheetItem
syntax:
`viewProviders: [MyService, provide(...)]`|`viewProviders:`
description:
List of dependency injection providers scoped to this component's view.

See: [viewProviders property](/angular/api/angular2.core/Component/viewProviders)


@cheatsheetItem
syntax:
`template: 'Hello {{name}}'
templateUrl: 'my-component.html'`|`template:`|`templateUrl:`
description:
Inline template or external template URL of the component's view.

See: [Architecture Overview](/angular/guide/architecture)


@cheatsheetItem
syntax:
`styles: ['.primary {color: red}']
styleUrls: ['my-component.css']`|`styles:`|`styleUrls:`
description:
List of inline CSS styles or external stylesheet URLs for styling the component’s view.

See: [Component Styles](/angular/guide/component-styles)


@cheatsheetItem
syntax:
`directives: [MyDirective, MyComponent]`|`directives:`
description:
List of directives used in the component's template.

See: [Architecture Overview](/angular/guide/architecture)


@cheatsheetItem
syntax:
`pipes: [MyPipe, OtherPipe]`|`pipes:`
description:
List of pipes used in the component's template.

See: [Pipes](/angular/guide/pipes)
