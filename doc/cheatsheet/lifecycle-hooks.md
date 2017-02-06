@cheatsheetSection
Directive and component change detection and lifecycle hooks
@cheatsheetIndex 8
@description
(implemented as class methods)

@cheatsheetItem
syntax:
`MyAppComponent(MyService myService, ...) { ... }`|`MyAppComponent(MyService myService, ...)`
description:
Called before any other lifecycle hook. Use it to inject dependencies, but avoid any serious work here.

See: [Lifecycle Hooks](/angular/guide/lifecycle-hooks)


@cheatsheetItem
syntax:
`ngOnChanges(changeRecord) { ... }`|`ngOnChanges(changeRecord)`
description:
Called after every change to input properties and before processing content or child views.

See: [Lifecycle Hooks](/angular/guide/lifecycle-hooks),
[OnChanges class](/angular/api/angular2.core/OnChanges-class)


@cheatsheetItem
syntax:
`ngOnInit() { ... }`|`ngOnInit()`
description:
Called after the constructor, initializing input properties, and the first call to `ngOnChanges`.

See: [Lifecycle Hooks](/angular/guide/lifecycle-hooks),
[OnInit class](/angular/api/angular2.core/OnInit-class)


@cheatsheetItem
syntax:
`ngDoCheck() { ... }`|`ngDoCheck()`
description:
Called every time that the input properties of a component or a directive are checked. Use it to extend change detection by performing a custom check.

See: [Lifecycle Hooks](/angular/guide/lifecycle-hooks),
[DoCheck class](/angular/api/angular2.core/DoCheck-class)


@cheatsheetItem
syntax:
`ngAfterContentInit() { ... }`|`ngAfterContentInit()`
description:
Called after ngOnInit when the component's or directive's content has been initialized.

See: [Lifecycle Hooks](/angular/guide/lifecycle-hooks),
[AfterContentInit class](/angular/api/angular2.core/AfterContentInit-class)


@cheatsheetItem
syntax:
`ngAfterContentChecked() { ... }`|`ngAfterContentChecked()`
description:
Called after every check of the component's or directive's content.

See: [Lifecycle Hooks](/angular/guide/lifecycle-hooks),
[AfterContentChecked class](/angular/api/angular2.core/AfterContentChecked-class)


@cheatsheetItem
syntax:
`ngAfterViewInit() { ... }`|`ngAfterViewInit()`
description:
Called after `ngAfterContentInit` when the component's view has been initialized. Applies to components only.

See: [Lifecycle Hooks](/angular/guide/lifecycle-hooks),
[AfterViewInit class](/angular/api/angular2.core/AfterViewInit-class)


@cheatsheetItem
syntax:
`ngAfterViewChecked() { ... }`|`ngAfterViewChecked()`
description:
Called after every check of the component's view. Applies to components only.

See: [Lifecycle Hooks](/angular/guide/lifecycle-hooks),
[AfterViewChecked class](/angular/api/angular2.core/AfterViewChecked-class)


@cheatsheetItem
syntax:
`ngOnDestroy() { ... }`|`ngOnDestroy()`
description:
Called once, before the instance is destroyed.

See: [Lifecycle Hooks](/angular/guide/lifecycle-hooks),
[OnDestroy class](/angular/api/angular2.core/OnDestroy-class)
