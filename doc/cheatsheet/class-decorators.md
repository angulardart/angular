@cheatsheetSection
Class decorators
@cheatsheetIndex 4
@description
`import 'package:angular2/core.dart';`

@cheatsheetItem
syntax:
`@Component(...)
class MyComponent() {}`|`@Component(...)`
description:
Declares that a class is a component and provides metadata about the component.

See: [Architecture Overview](/angular/guide/architecture),
[Component class](/angular/api/angular2.core/Component-class)


@cheatsheetItem
syntax:
`@Directive(...)
class MyDirective() {}`|`@Directive(...)`
description:
Declares that a class is a directive and provides metadata about the directive.

See: [Architecture Overview](/angular/guide/architecture),
[Directive class](/angular/api/angular2.core/Directive-class)


@cheatsheetItem
syntax:
`@Pipe(...)
class MyPipe() {}`|`@Pipe(...)`
description:
Declares that a class is a pipe and provides metadata about the pipe.

See: [Pipes](/angular/guide/pipes),
[Pipe class](/angular/api/angular2.core/Pipe-class)


@cheatsheetItem
syntax:
`@Injectable()
class MyService() {}`|`@Injectable()`
description:
Declares that a class has dependencies that should be injected into the constructor when the dependency injector is creating an instance of this class.

See: [Dependency Injection](/angular/guide/dependency-injection),
[Injectable class](/angular/api/angular2.core/Injectable-class)