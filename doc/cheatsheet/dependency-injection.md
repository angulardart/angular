@cheatsheetSection
Dependency injection configuration
@cheatsheetIndex 9
@description
`import 'package:angular2/core.dart';`

@cheatsheetItem
syntax:
`const Provider(MyService, useClass: MyMockService)`|`Provider`|`useClass`
description:
Sets or overrides the provider for `MyService` to the `MyMockService` class.

See:
[Dependency Injection](/angular/guide/dependency-injection),
[provide function](/angular/api/angular2.core/provide),
[Provider class](/angular/api/angular2.core/Provider-class)


@cheatsheetItem
syntax:
`const Provider(MyService, useFactory: myFactory)`|`Provider`|`useFactory`
description:
Sets or overrides the provider for `MyService` to the `myFactory` factory function.

See:
[Dependency Injection](/angular/guide/dependency-injection),
[provide function](/angular/api/angular2.core/provide),
[Provider class](/angular/api/angular2.core/Provider-class)


@cheatsheetItem
syntax:
`const Provider(MyValue, useValue: 41)`|`Provider`|`useValue`
description:
Sets or overrides the provider for `MyValue` to the value `41`.

See:
[Dependency Injection](/angular/guide/dependency-injection),
[provide function](/angular/api/angular2.core/provide),
[Provider class](/angular/api/angular2.core/Provider-class)
