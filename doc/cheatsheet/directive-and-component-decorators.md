@cheatsheetSection
Class field decorators for directives and components
@cheatsheetIndex 7
@description
`import 'package:angular2/core.dart';`

@cheatsheetItem
syntax:
`@Input() myProperty;`|`@Input()`
description:
Declares an input property that you can update via property binding (example:
`<my-cmp [myProperty]="someExpression">`).

See: [Template Syntax](/angular/guide/template-syntax),
[Input class](/angular/api/angular2.core/Input-class)


@cheatsheetItem
syntax:
`final _myEvent = new StreamController<T>();
!@Output() Stream<T> get myEvent => _myEvent.stream;`|`@Output()`
description:
Declares an output property that fires events that you can subscribe to with an event binding (example: `<my-cmp (myEvent)="doSomething()">`).

See: [Template Syntax](/angular/guide/template-syntax),
[Output class](/angular/api/angular2.core/Output-class)


@cheatsheetItem
syntax:
`@HostBinding('class.valid') isValid;`|`@HostBinding('class.valid')`
description:
Binds a host element property (here, the CSS class `valid`) to a directive/component property (`isValid`).

See: [HostBinding class](/angular/api/angular2.core/HostBinding-class)


@cheatsheetItem
syntax:
`@HostListener('click', ['$event'])
onClick(e) {...}`|`@HostListener('click', ['$event'])`
description:
Subscribes to a host element event (`click`) with a directive/component method (`onClick`), optionally passing an argument (`$event`).

See: [Attribute Directives](/angular/guide/attribute-directives),
[HostListener class](/angular/api/angular2.core/HostListener-class)


@cheatsheetItem
syntax:
`@ContentChild(myPredicate) myChildComponent;`|`@ContentChild(myPredicate)`
description:
Binds the first result of the component content query (`myPredicate`) to a property (`myChildComponent`) of the class.

See: [ContentChild class](/angular/api/angular2.core/ContentChild-class)


@cheatsheetItem
syntax:
`@ContentChildren(myPredicate) myChildComponents;`|`@ContentChildren(myPredicate)`
description:
Binds the results of the component content query (`myPredicate`) to a property (`myChildComponents`) of the class.

See: [ContentChildren class](/angular/api/angular2.core/ContentChildren-class)


@cheatsheetItem
syntax:
`@ViewChild(myPredicate) myChildComponent;`|`@ViewChild(myPredicate)`
description:
Binds the first result of the component view query (`myPredicate`) to a property (`myChildComponent`) of the class. Not available for directives.

See: [ViewChild class](/angular/api/angular2.core/ViewChild-class)


@cheatsheetItem
syntax:
`@ViewChildren(myPredicate) myChildComponents;`|`@ViewChildren(myPredicate)`
description:
Binds the results of the component view query (`myPredicate`) to a property (`myChildComponents`) of the class. Not available for directives.

See: [ViewChildren class](/angular/api/angular2.core/ViewChildren-class)
