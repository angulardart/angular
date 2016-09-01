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


@cheatsheetItem
syntax:
`@Output() myEvent = new EventEmitter();`|`@Output()`
description:
Declares an output property that fires events that you can subscribe to with an event binding (example: `<my-cmp (myEvent)="doSomething()">`).


@cheatsheetItem
syntax:
`@HostBinding('[class.valid]') isValid;`|`@HostBinding('[class.valid]')`
description:
Binds a host element property (here, the CSS class `valid`) to a directive/component property (`isValid`).


@cheatsheetItem
syntax:
`@HostListener('click', ['$event']) onClick(e) {...}`|`@HostListener('click', ['$event'])`
description:
Subscribes to a host element event (`click`) with a directive/component method (`onClick`), optionally passing an argument (`$event`).


@cheatsheetItem
syntax:
`@ContentChild(myPredicate) myChildComponent;`|`@ContentChild(myPredicate)`
description:
Binds the first result of the component content query (`myPredicate`) to a property (`myChildComponent`) of the class.


@cheatsheetItem
syntax:
`@ContentChildren(myPredicate) myChildComponents;`|`@ContentChildren(myPredicate)`
description:
Binds the results of the component content query (`myPredicate`) to a property (`myChildComponents`) of the class.


@cheatsheetItem
syntax:
`@ViewChild(myPredicate) myChildComponent;`|`@ViewChild(myPredicate)`
description:
Binds the first result of the component view query (`myPredicate`) to a property (`myChildComponent`) of the class. Not available for directives.


@cheatsheetItem
syntax:
`@ViewChildren(myPredicate) myChildComponents;`|`@ViewChildren(myPredicate)`
description:
Binds the results of the component view query (`myPredicate`) to a property (`myChildComponents`) of the class. Not available for directives.
