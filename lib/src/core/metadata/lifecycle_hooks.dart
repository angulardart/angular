import "package:angular2/src/core/change_detection/change_detection_util.dart"
    show SimpleChange;

enum LifecycleHooks {
  OnInit,
  OnDestroy,
  DoCheck,
  OnChanges,
  AfterContentInit,
  AfterContentChecked,
  AfterViewInit,
  AfterViewChecked
}

/// Lifecycle hooks are guaranteed to be called in the following order:
/// - `OnChanges` (if any bindings have changed),
/// - `OnInit` (after the first check only),
/// - `DoCheck`,
/// - `AfterContentInit`,
/// - `AfterContentChecked`,
/// - `AfterViewInit`,
/// - `AfterViewChecked`,
/// - `OnDestroy` (at the very end before destruction)
var LIFECYCLE_HOOKS_VALUES = [
  LifecycleHooks.OnInit,
  LifecycleHooks.OnDestroy,
  LifecycleHooks.DoCheck,
  LifecycleHooks.OnChanges,
  LifecycleHooks.AfterContentInit,
  LifecycleHooks.AfterContentChecked,
  LifecycleHooks.AfterViewInit,
  LifecycleHooks.AfterViewChecked
];

/// Implement this interface to get notified when any data-bound property of
/// your directive changes.
///
/// [ngOnChanges] is called right after the data-bound properties have been
/// checked and before view and content children are checked if at least one of
/// them has changed.
///
/// The [changes] parameter contains an entry for each changed data-bound
/// property. The key is the property name and the value is an instance of
/// [SimpleChange].
///
/// ### Examples
///
/// Try this [live example][ex] from the [Lifecycle Hooks][docs] page:
///
/// {@example docs/lifecycle-hooks/lib/on_changes_component.dart region=ng-on-changes}
///
/// [docs]: docs/guide/lifecycle-hooks.html#onchanges
/// [ex]: examples/lifecycle-hooks#onchanges
abstract class OnChanges {
  ngOnChanges(Map<String, SimpleChange> changes);
}

/// Implement this interface to execute custom initialization logic after your
/// directive's data-bound properties have been initialized.
///
/// [ngOnInit] is called right after the directive's data-bound properties have
/// been checked for the first time, and before any of its children have been
/// checked. It is invoked only once when the directive is instantiated.
///
/// ### Examples
///
/// Try this [live example][ex] from the [Lifecycle Hooks][docs] page:
///
/// {@example docs/lifecycle-hooks/lib/spy_directive.dart region=spy-directive}
///
/// [docs]: docs/guide/lifecycle-hooks.html#oninit
/// [ex]: examples/lifecycle-hooks#spy
abstract class OnInit {
  ngOnInit();
}

/// Implement this interface to override the default change detection algorithm
/// for your directive.
///
/// `ngDoCheck` gets called to check the changes in the directives instead of
/// the default algorithm.
///
/// The default change detection algorithm looks for differences by comparing
/// bound-property values by reference across change detection runs. When
/// `DoCheck` is implemented, the default algorithm is disabled and `ngDoCheck`
/// is responsible for checking for changes.
///
/// Implementing this interface allows improving performance by using insights
/// about the component, its implementation and data types of its properties.
///
/// Note that a directive should not implement both `DoCheck` and [OnChanges] at
/// the same time.  `ngOnChanges` would not be called when a directive
/// implements `DoCheck`. Reaction to the changes have to be handled from within
/// the `ngDoCheck` callback.
///
/// Use [KeyValueDiffers] and [IterableDiffers] to add your custom check
/// mechanisms.
///
/// ## Example
///
/// In the following example `ngDoCheck` uses an [IterableDiffers] to detect the
/// updates to the array `list`:
///
/// ```dart
/// @Component(
///   selector: 'custom-check',
///   template: '''
///     <p>Changes:</p>
///     <ul>
///       <li *ngFor="let line of logs">{{line}}</li>
///     </ul>
///   ''',
///   directives: const [NgFor]
/// )
/// class CustomCheckComponent implements DoCheck {
///   final IterableDiffer differ;
///   final List<String> logs = [];
///
///   @Input()
///   List list;
///
///   CustomCheckComponent(IterableDiffers differs) :
///     differ = differs.find([]).create(null);
///
///   @override
///   ngDoCheck() {
///     var changes = differ.diff(list);
///
///     if (changes is DefaultIterableDiffer) {
///       changes.forEachAddedItem(r => logs.add('added ${r.item}'));
///       changes.forEachRemovedItem(r => logs.push('removed ${r.item}'))
///     }
///   }
/// }
///
/// @Component({
///   selector: 'app',
///   template: '''
///     <button (click)="list.push(list.length)">Push</button>
///     <button (click)="list.pop()">Pop</button>
///     <custom-check [list]="list"></custom-check>
///   ''',
///   directives: const [CustomCheckComponent]
/// })
/// class App {
///   List list = [];
/// }
/// ```
abstract class DoCheck {
  ngDoCheck();
}

/// Implement this interface to get notified when your directive is destroyed.
///
/// [ngOnDestroy] callback is typically used for any custom cleanup that needs
/// to occur when the instance is destroyed
///
/// ### Examples
///
/// Try this [live example][ex] from the [Lifecycle Hooks][docs] page:
///
/// {@example docs/lifecycle-hooks/lib/spy_directive.dart region=spy-directive}
///
/// [docs]: docs/guide/lifecycle-hooks.html#ondestroy
/// [ex]: examples/lifecycle-hooks#spy
abstract class OnDestroy {
  ngOnDestroy();
}

/// Implement this interface to get notified when your directive's content has
/// been fully initialized.
///
/// ## Example
///
/// ```dart
/// @Component(
///   selector: 'child-cmp',
///   template: '{{where}} child'
/// )
/// class ChildComponent {
///   @Input()
///   String where;
/// }
///
/// @Component(
///   selector: 'parent-cmp',
///   template: '<ng-content></ng-content>'
/// )
/// class ParentComponent implements AfterContentInit {
///   @ContentChild(ChildComponent)
///   ChildComponent contentChild;;
///
///   ParentComponent() {
///     // contentChild is not initialized yet
///     print(_message(contentChild));
///   }
///
///   @override
///   ngAfterContentInit() {
///     // contentChild is updated after the content has been checked
///     console.log('AfterContentInit: ' + _message(contentChild));
///   }
///
///   String _message(ChildComponent cmp) =>
///       cmp == null ? 'no child' : '${cmp.where} child';
/// }
///
/// @Component(
///   selector: 'app',
///   template: '''
///     <parent-cmp>
///       <child-cmp where="content"></child-cmp>
///     </parent-cmp>
///   ''',
///   directives: const [ParentComponent, ChildComponent]
/// )
/// export class App {}
///
/// bootstrap(App);
/// ```
abstract class AfterContentInit {
  ngAfterContentInit();
}

/// Implement this interface to get notified after every check of your
/// directive's content.
///
/// ## Example
///
/// ```dart
/// @Component(selector: 'child-cmp', template: '{{where}} child')
/// class ChildComponent {
///   @Input()
///   String where;
/// }
///
/// @Component(selector: 'parent-cmp', template: '<ng-content></ng-content>')
/// class ParentComponent implements AfterContentChecked {
///   @ContentChild(ChildComponent)
///   ChildComponent contentChild;
///
///   ParentComponent() {
///     // contentChild is not initialized yet
///     print(_message(contentChild));
///   }
///
///   @override
///   ngAfterContentChecked() {
///     // contentChild is updated after the content has been checked
///     print('AfterContentChecked: ${_message(contentChild)}');
///   }
///
///   String _message(cmp: ChildComponent) =>
///       cmp  == null ? 'no child' : '${cmp.where} child';
/// }
///
/// @Component(
///   selector: 'app',
///   template: '''
///     <parent-cmp>
///       <button (click)="hasContent = !hasContent">
///         Toggle content child
///       </button>
///       <child-cmp *ngIf="hasContent" where="content"></child-cmp>
///     </parent-cmp>
///   ''',
///   directives: const [NgIf, ParentComponent, ChildComponent]
/// )
/// export class App {
///   bool hasContent = true;
/// }
///
/// bootstrap(App);
/// ```
abstract class AfterContentChecked {
  ngAfterContentChecked();
}

/// Implement this interface to get notified when your component's view has been
/// fully initialized.
///
/// ## Example
///
/// ```dart
/// @Component(selector: 'child-cmp', template: '{{where}} child')
/// class ChildComponent {
///   @Input()
///   String where;
/// }
///
/// @Component(
///   selector: 'parent-cmp',
///   template: '<child-cmp where="view"></child-cmp>',
///   directives: const [ChildComponent]
/// )
/// class ParentComponent implements AfterViewInit {
///   @ViewChild(ChildComponent)
///   ChildComponentviewChild;
///
///   ParentComponent() {
///     // viewChild is not initialized yet
///     print(_message(viewChild));
///   }
///
///   @override
///   ngAfterViewInit() {
///     // viewChild is updated after the view has been initialized
///     console.log('ngAfterViewInit: ' + _message(viewChild));
///   }
///
///   String _message(cmp: ChildComponent) =>
///       cmp  == null ? 'no child' : '${cmp.where} child';
/// }
///
/// @Component(
///   selector: 'app',
///   template: '<parent-cmp></parent-cmp>',
///   directives: const [ParentComponent]
/// )
/// export class App {
/// }
///
/// bootstrap(App);
/// ```
abstract class AfterViewInit {
  ngAfterViewInit();
}

/// Implement this interface to get notified after every check of your
/// component's view.
///
/// ## Example
///
/// ```dart
/// @Component(selector: 'child-cmp', template: '{{where}} child')
/// class ChildComponent {
///   @Input()
///   String where;
/// }
///
/// @Component(
///   selector: 'parent-cmp',
///   template: '''
///     <button (click)="showView = !showView">Toggle view child</button>
///     <child-cmp *ngIf="showView" where="view"></child-cmp>
///   ''',
///   directives: const [NgIf, ChildComponent]
/// )
/// class ParentComponent implements AfterViewChecked {
///   @ViewChild(ChildComponent)
///   ChildComponent viewChild;
///
///   bool showView = true;
///
///   ParentComponent() {
///     // viewChild is not initialized yet
///     print(_message(viewChild));
///   }
///
///   @override
///   ngAfterViewChecked() {
///     // viewChild is updated after the view has been checked
///     print('AfterViewChecked: ${_message(viewChild)}');
///   }
///
///   String _message(cmp: ChildComponent) =>
///       cmp  == null ? 'no child' : '${cmp.where} child';
/// }
///
/// @Component(
///   selector: 'app',
///   template: '<parent-cmp></parent-cmp>',
///   directives: const [ParentComponent]
/// )
/// export class App {}
///
/// bootstrap(App);
/// ```
abstract class AfterViewChecked {
  ngAfterViewChecked();
}
