import 'package:meta/meta.dart';

import 'change_detection/change_detection.dart';
import 'metadata/view.dart';
import 'metadata/visibility.dart';

export 'di/decorators.dart';
export 'metadata/lifecycle_hooks.dart'
    show
        AfterChanges,
        AfterContentInit,
        AfterContentChecked,
        AfterViewInit,
        AfterViewChecked,
        OnChanges,
        OnDestroy,
        OnInit,
        DoCheck;
export 'metadata/view.dart';
export 'metadata/visibility.dart';

/// An annotation that marks a class as an Angular directive, allowing you to
/// attach behavior to elements in the DOM.
///
/// <?code-excerpt "docs/attribute-directives/lib/src/highlight_directive_1.dart"?>
/// ```dart
/// import 'package:angular/angular.dart';
///
/// @Directive(selector: '[myHighlight]')
/// class HighlightDirective {
///   HighlightDirective(ElementRef el) {
///     el.nativeElement.style.backgroundColor = 'yellow';
///   }
/// }
/// ```
///
/// Use `@Directive` to mark a class as an Angular directive and provide
/// additional metadata that determines how the directive should be processed,
/// instantiated, and used at runtime.
///
/// In addition to the metadata configuration specified via the Directive
/// decorator, directives can control their runtime behavior by implementing
/// various lifecycle hooks.
///
/// See also:
///
/// * [Attribute Directives](https://webdev.dartlang.org/angular/guide/attribute-directives)
/// * [Lifecycle Hooks](https://webdev.dartlang.org/angular/guide/lifecycle-hooks)
///
class Directive {
  /// The CSS selector that triggers the instantiation of the directive.
  ///
  /// Angular only allows directives to trigger on CSS selectors that do not
  /// cross element boundaries.
  ///
  /// The [selector] may be declared as one of the following:
  ///
  /// - `element-name`: select by element name.
  /// - `.class`: select by class name.
  /// - `[attribute]`: select by attribute name.
  /// - `[attribute=value]` : select by attribute name and value.
  /// - `:not(sub_selector)`: select only if the element does not match the
  ///   `sub_selector`.
  /// - `selector1, selector2`: select if either `selector1` or `selector2`
  ///   matches.
  ///
  /// ### Example
  ///
  /// Suppose we have a directive with an `input[type=text]` selector
  /// and the following HTML:
  ///
  /// ```html
  /// <form>
  ///   <input type="text">
  ///   <input type="radio">
  /// <form>
  /// ```
  ///
  /// The directive would only be instantiated on the `<input type="text">`
  /// element.
  final String selector;

  /// Events, actions, properties, and attributes related to the host element.
  ///
  /// ## Host listeners
  /// Specifies which DOM events the directive listens to via a set of
  /// '(_event_)' to _statement_ key-value pairs:
  ///
  /// - _event_: the DOM event that the directive listens to
  /// - _statement_: the statement to execute when the event occurs
  ///
  /// If the evaluation of the statement returns [false], then [preventDefault]
  /// is applied on the DOM event.
  ///
  /// To listen to global events, a target must be added to the event name.
  /// The target can be `window`, `document`, or `body`.
  ///
  /// When writing a directive event binding, you can also refer to the `$event`
  /// local variable.
  ///
  /// The following example declares a directive that attaches a click listener
  /// to the button and counts clicks.
  ///
  /// ```dart
  /// @Directive(
  ///   selector: 'button[counting]',
  ///   host: const {
  ///     '(click)': 'onClick($event.target)'
  ///   })
  /// class CountClicks {
  ///   var numberOfClicks = 0;
  ///
  ///   void onClick(btn) {
  ///     print("Button $btn, number of clicks: ${numberOfClicks++}.");
  ///   }
  /// }
  ///
  /// @Component(
  ///   selector: 'app',
  ///   template: `<button counting>Increment</button>`,
  ///   directives: const [CountClicks])
  /// class App {}
  /// ```
  ///
  /// ## Host property bindings
  /// Specifies which DOM properties the directive updates.
  ///
  /// Angular automatically checks host property bindings during change
  /// detection. If a binding changes, it will update the host element of the
  /// directive.
  ///
  /// The following example creates a directive that sets the `valid` and
  /// `invalid` classes on the DOM element that has ngModel directive on it.
  ///
  ///     @Directive(
  ///       selector: '[ngModel]',
  ///       host: {
  ///         '[class.valid]': 'valid',
  ///         '[class.invalid]': 'invalid'
  ///       }
  ///     )
  ///     class NgModelStatus {
  ///       NgModel control;
  ///
  ///       NgModelStatus(this.control);
  ///       get valid => control.valid;
  ///       get invalid => control.invalid;
  ///     }
  ///
  ///     @Component({
  ///       selector: 'app',
  ///       template: `<input [(ngModel)]="prop">`,
  ///       directives: [formDirectives, NgModelStatus]
  ///     })
  ///     class App {
  ///       prop;
  ///     }
  ///
  ///     bootstrap(App);
  ///
  /// ## Attributes
  ///
  /// Specifies static attributes that should be propagated to a host element.
  ///
  /// ### Example
  ///
  /// In this example using `my-button` directive (ex.: `<div my-button></div>`)
  /// on a host element (here: `<div>` ) will ensure that this element will get
  /// the "button" role.
  ///
  /// ```dart
  /// @Directive(
  ///   selector: '[my-button]',
  ///   host: const {
  ///     'role': 'button'
  ///   })
  /// class MyButton {}
  /// ```
  @Deprecated('Use @HostBinding() on a getter or @HostListener on a method')
  final Map<String, String> host;

  /// The set of injectable objects that are visible to the directive and
  /// its light DOM children.
  ///
  /// ### Example
  /// Here is an example of a class that can be injected:
  ///
  /// ```dart
  /// class Greeter {
  ///   String greet(String name) => 'Hello ${name}!';
  /// }
  ///
  /// @Directive(
  ///   selector: 'greet',
  ///   providers: const [ Greeter])
  /// class HelloWorld {
  ///   final Greeter greeter;
  ///
  ///   HelloWorld(this.greeter);
  /// }
  /// ```
  final List<Object> providers;

  /// A name that can be used in the template to assign this directive
  /// to a variable.
  ///
  /// ### Example
  ///
  /// ```dart
  /// @Directive(
  ///   selector: 'child-dir',
  ///   exportAs: 'child')
  /// class ChildDir {}
  ///
  /// @Component(
  ///   selector: 'main',
  ///   template: `<child-dir #c="child"></child-dir>`,
  ///   directives: const [ChildDir])
  /// class MainComponent {}
  /// ```
  final String exportAs;

  /// Whether this directive will be provided for injection.
  ///
  /// By default this is [Visibility.local], which prevents injecting the
  /// directive class by default, but provides a code-size and runtime
  /// performance benefit. See [Visibility] for details.
  final Visibility visibility;

  const Directive({
    @required this.selector,
    @Deprecated('Use @HostBinding() on a getter or @HostListener on a method')
        this.host,
    this.providers,
    this.exportAs,
    this.visibility: Visibility.local,
  });
}

/// Declare reusable UI building blocks for an application.
///
/// Each Angular component requires a single `@Component` annotation. The
/// `@Component` annotation specifies when a component is instantiated, and
/// which properties and hostListeners it binds to.
///
/// When a component is instantiated, Angular
///
/// - creates a shadow DOM for the component,
/// - loads the selected template into the shadow DOM and
/// - creates all the injectable objects configured with [providers] and
///   [viewProviders].
///
/// All template expressions and statements are then evaluated against the
/// component instance.
///
/// ### Lifecycle hooks
///
/// When the component class implements some [lifecycle-hooks][LCH]
/// the callbacks are called by the change detection at defined points in time
/// during the life of the component.
///
/// [LCH]: https://webdev.dartlang.org/angular/guide/lifecycle-hooks
class Component extends Directive {
  /// Defines the used change detection strategy.
  ///
  /// When a component is instantiated, Angular creates a change detector, which
  /// is responsible for propagating the component's bindings.
  ///
  /// The [changeDetection] property defines, whether the change detection will
  /// be checked every time or only when the component tells it to do so.
  final int changeDetection;

  /// Defines the set of injectable objects that are visible to its view
  /// DOM children.
  ///
  /// ## Simple Example
  ///
  /// Here is an example of a class that can be injected:
  ///
  ///     class Greeter {
  ///        greet(String name) => 'Hello ${name}!';
  ///     }
  ///
  ///     @Directive(
  ///       selector: 'needs-greeter'
  ///     )
  ///     class NeedsGreeter {
  ///       final Greeter greeter;
  ///
  ///       NeedsGreeter(this.greeter);
  ///     }
  ///
  ///     @Component(
  ///       selector: 'greet',
  ///       viewProviders: [
  ///         Greeter
  ///       ],
  ///       template: '<needs-greeter></needs-greeter>',
  ///       directives: [NeedsGreeter]
  ///     )
  ///     class HelloWorld {
  ///     }
  ///
  final List<Object> viewProviders;

  /// A list of identifiers that may be referenced in the template.
  ///
  /// ## Small Example
  ///
  /// Suppose you want to use an enum value in your template:
  ///
  ///     enum MyEnum { foo, bar, baz }
  ///
  ///     @Component(
  ///       selector: 'example',
  ///       exports: const [MyEnum],
  ///       template: '<p>{{MyEnum.bar}}</p>',
  ///     )
  ///     class Example {}
  ///
  final List<Object> exports;

  final String templateUrl;
  final String template;

  /// Removes all whitespace except `&ngsp;` and `&nbsp;` from template if set
  /// to false.
  ///
  /// &ngsp; (Angular space) can be used to insert regular space character into
  /// a template.
  /// &nbsp; represents the standard non-breaking space entity in html markup.
  final bool preserveWhitespace;
  final List<String> styleUrls;
  final List<String> styles;
  final List<Object> directives;
  final List<Object> pipes;
  final ViewEncapsulation encapsulation;

  const Component({
    String selector,
    @Deprecated('Use @HostBinding() on a getter or @HostListener on a method')
        Map<String, String> host,
    String exportAs,
    List providers,
    Visibility visibility: Visibility.local,
    this.viewProviders,
    this.exports,
    this.changeDetection: ChangeDetectionStrategy.Default,
    this.templateUrl,
    this.template,
    this.preserveWhitespace: false,
    this.styleUrls,
    this.styles,
    this.directives,
    this.pipes,
    this.encapsulation,
  }) : super(
          selector: selector,
          host: host,
          exportAs: exportAs,
          providers: providers,
          visibility: visibility,
        );
}

/// Declare reusable pipe function.
///
/// A "pure" pipe is only re-evaluated when either the input or any of the
/// arguments change. When not specified, pipes default to being pure.
///
class Pipe {
  final String name;
  final bool pure;

  const Pipe(this.name, {this.pure: true});
}

/// An annotation to specify that a constant attribute value should be injected.
///
/// The directive can inject constant string literals of host element
/// attributes.
///
/// ### Example
///
/// Suppose we have an `<input>` element and want to know its `type`.
///
/// ```html
/// <input type="text">
/// ```
///
/// A decorator can inject string literal `text` like so:
///
/// ```dart
/// @Directive(selector: 'input')
/// class InputAttrDirective {
///   InputAttrDirective(@Attribute('type') String type) {
///     // type would be 'text' in this example
///   }
/// }
/// ```
class Attribute {
  final String attributeName;

  const Attribute(this.attributeName);
}

abstract class _Query {
  /// Either the class [Type] or selector [String].
  final Object selector;

  /// Whether to query only direct children (`false`) or all children (`true`).
  final bool descendants;

  /// Whether to only query the first child.
  final bool first;

  /// The DI token to read from an element that matches the selector.
  final Object read;

  const _Query(
    this.selector, {
    this.descendants: false,
    this.first: false,
    this.read,
  });
}

/// Configures a content query.
///
/// Content queries are set before the `ngAfterContentInit` callback is called.
///
/// ### Example
///
/// ```dart
/// @Directive(selector: 'someDir')
/// class SomeDir implements AfterContentInit {
///   @ContentChildren(ChildDirective)
///   QueryList<ChildDirective> contentChildren;
///
///   @override
///   ngAfterContentInit() {
///     // contentChildren is set
///   }
/// }
/// ```
class ContentChildren extends _Query {
  const ContentChildren(
    Object selector, {
    bool descendants: true,
    Object read,
  }) : super(
          selector,
          descendants: descendants,
          read: read,
        );
}

/// Configures a content query.
///
/// Content queries are set before the `ngAfterContentInit` callback is called.
///
/// ### Example
///
/// ```dart
/// @Directive(selector: 'someDir')
/// class SomeDir implements AfterContentInit {
///   @ContentChild(ChildDirective)
///   Query<ChildDirective> contentChild;
///
///   @override
///   ngAfterContentInit() {
///     // contentChild is set
///   }
/// }
/// ```
class ContentChild extends _Query {
  const ContentChild(
    Object selector, {
    Object read,
  }) : super(
          selector,
          descendants: true,
          first: true,
          read: read,
        );
}

abstract class _ViewQuery extends _Query {
  const _ViewQuery(
    Object selector, {
    bool descendants: false,
    bool first: false,
    Object read,
  }) : super(
          selector,
          descendants: descendants,
          first: first,
          read: read,
        );
}

/// Declares a reference to multiple child elements.
///
/// The list is automatically updated when the DOM is updated.
///
/// The `ViewChildren` annotation takes an argument that specifies the elements
/// to be selected.
///
/// - If the argument is a [Type], directives or components with the type will
///   be bound.
/// - If the argument is a [String], the string is interpreted as a list of
///   comma-separated selectors.  For each selector, an element containing the
///   matching template variable (e.g. `#child`) will be bound.
///
/// View children are set before the `ngAfterViewInit` callback is called.
///
/// ### Example
///
/// With type selector:
///
/// ```dart
/// @Component(
///   selector: 'child-cmp',
///   template: '<p>child</p>'
/// )
/// class ChildCmp {
///   doSomething() {}
/// }
///
/// @Component(
///   selector: 'some-cmp',
///   template: '''
///     <child-cmp></child-cmp>
///     <child-cmp></child-cmp>
///     <child-cmp></child-cmp>
///   ''',
///   directives: const [ChildCmp]
/// )
/// class SomeCmp implements AfterViewInit {
///   @ViewChildren(ChildCmp)
///   QueryList<ChildCmp> children;
///
///   @override
///   ngAfterViewInit() {
///     // children are set
///     for ( var child in children ) {
///       child.doSomething();
///     }
///   }
/// }
/// ```
///
/// With string selector:
///
/// ```dart
/// @Component(
///   selector: 'child-cmp',
///   template: '<p>child</p>')
/// class ChildCmp {
///   doSomething() {}
/// }
///
/// @Component(
///   selector: 'some-cmp',
///   template: '''
///     <child-cmp #child1></child-cmp>
///     <child-cmp #child2></child-cmp>
///     <child-cmp #child3></child-cmp>
///   ''',
///   directives: const [ChildCmp])
/// class SomeCmp implements AfterViewInit {
///   @ViewChildren('child1, child2, child3')
///   List<ChildCmp> children;
///
///   @override
///   ngAfterViewInit() {
///     // children are set
///     for ( var child in children ) {
///       child.doSomething();
///     }
///   }
/// }
/// ```
class ViewChildren extends _ViewQuery {
  const ViewChildren(
    Object selector, {
    Object read,
  }) : super(
          selector,
          descendants: true,
          read: read,
        );
}

/// Declares a reference to a single child element.
///
/// The `ViewChild` annotation takes an argument to select elements.
///
/// - If the argument is a [Type], a directive or a component with the type will
///   be bound.
/// - If the argument is a [String], the string is interpreted as a selector. An
///   element containing the matching template variable (e.g. `#child`) will be
///   bound.
///
/// In either case, `@ViewChild()` assigns the first (looking from above)
/// element if there are multiple matches.
///
/// View child is set before the `ngAfterViewInit` callback is called.
///
/// ### Example
///
/// With type selector:
///
/// ```dart
/// @Component(
///   selector: 'child-cmp',
///   template: '<p>child</p>'
/// )
/// class ChildCmp {
///   doSomething() {}
/// }
///
/// @Component(
///   selector: 'some-cmp',
///   template: '<child-cmp></child-cmp>',
///   directives: const [ChildCmp]
/// )
/// class SomeCmp implements AfterViewInit {
///   @ViewChild(ChildCmp)
///   ChildCmp child;
///
///   @override
///   ngAfterViewInit() {
///     // child is set
///     child.doSomething();
///   }
/// }
/// ```
///
/// With string selector:
///
/// ```dart
/// @Component(
///   selector: 'child-cmp',
///   template: '<p>child</p>'
/// )
/// class ChildCmp {
///   doSomething() {}
/// }
///
/// @Component(
///   selector: 'some-cmp',
///   template: '<child-cmp #child></child-cmp>',
///   directives: const [ChildCmp]
/// )
/// class SomeCmp implements AfterViewInit {
///   @ViewChild('child')
///   ChildCmp child;
///
///   @override
///   ngAfterViewInit() {
///     // child is set
///     child.doSomething();
///   }
/// }
/// ```
class ViewChild extends _ViewQuery {
  const ViewChild(
    Object selector, {
    Object read,
  }) : super(
          selector,
          descendants: true,
          first: true,
          read: read,
        );
}

/// Declares a data-bound input property.
///
/// Data-bound properties are automatically updated during change detection.
///
/// The [Input] annotation takes an optional parameter that specifies
/// the name used when instantiating a component in the template. When not
/// provided, the name of the decorated property is used.
///
/// ### Example
///
/// The following example creates a component with two input properties.
///
/// ```dart
/// @Component(
///    selector: 'bank-account',
///    template: '''
///      Bank Name: {{bankName}}
///      Account Id: {{id}}
///    ''')
///  class BankAccount {
///    @Input()
///    String bankName;
///
///    @Input('account-id')
///    String id;
///
///    // this property is not bound, and won't be automatically updated
///    String normalizedBankName;
///  }
///
///  @Component(
///    selector: 'app',
///    template: '''
///      <bank-account bank-name="RBC" account-id="4747"></bank-account>
///    ''',
///    directives: const [BankAccount])
///  class App {}
///  ```
class Input {
  /// Name used when instantiating a component in the template.
  final String bindingPropertyName;
  const Input([this.bindingPropertyName]);
}

/// Declares an event-bound output property.
///
/// When an output property emits an event, an event handler attached to that
/// event the template is invoked.
///
/// The [Output] annotation takes an optional parameter that specifies
/// the name used when instantiating a component in the template. When not
/// provided, the name of the decorated property is used.
///
/// ### Example
///
/// ```dart
/// @Directive(selector: 'interval-dir')
/// class IntervalDir {
///   final _everySecond = new StreamController<String>();
///   @Output()
///   final get everySecond => _everySecond.stream;
///
///   final _every5Secs = new StreamController<Null>();
///   @Output('everyFiveSeconds')
///   final get every5Secs => _every5Secs.stream;
///
///   IntervalDir() {
///     setInterval(() => _everySecond.add("event"), 1000);
///     setInterval(() => _every5Secs.add(null), 5000);
///   }
/// }
///
/// @Component(
///   selector: 'app',
///   template: '''
///     <interval-dir
///         (everySecond)="everySecond()"
///         (everyFiveSeconds)="everyFiveSeconds()">
///     </interval-dir>
///   ''',
///   directives: const [IntervalDir])
/// class App {
///   void everySecond() {
///     print('second');
///   }
///
///   everyFiveSeconds() {
///     print('five seconds');
///   }
/// }
/// ```
class Output {
  final String bindingPropertyName;
  const Output([this.bindingPropertyName]);
}

/// Declares a host property binding.
///
/// Host property bindings are automatically checked during change detection. If
/// a binding changes, the host element of the directive is updated.
///
/// The [HostBinding] annotation takes an optional parameter that
/// specifies the property name of the host element that will be updated. When
/// not provided, the property name is used.
///
/// ### Example
///
/// With class bindings:
///
/// The following example creates a directive that sets the `valid` and
/// `invalid` classes on the DOM element that has ngModel directive on it.
///
/// ```dart
/// @Directive(selector: '[ngModel]')
/// class NgModelStatus {
///   NgModel control;
///
///   NgModelStatus(this.control);
///
///   @HostBinding('class.valid')
///   bool get valid => return control.valid;
///
///   @HostBinding('class.invalid')
///   bool get invalid => control.invalid;
/// }
///
/// @Component(
///   selector: 'app',
///   template: '<input [(ngModel)]="prop">',
///   directives: const [formDirectives, NgModelStatus])
/// class App {
///   var prop;
///  }
/// ```
///
/// With attribute bindings:
///
/// The following example creates a checkbox component which reflects its state
/// as attributes on the host element.  When the checkbox is disabled, it sets
/// the tabindex to -1 to move it out of tab order. When the checkbox is checked
/// the host element will add a "checked" boolean attribute.
///
/// ```dart
/// @Component(selector: 'ng-checkbox', template: '...')
/// class NgCheckboxComponent {
///    bool disabled;
///    bool isChecked;
///
///   @HostBinding('attr.tabindex')
///   String get tabIndex => disabled ? '-1' : '1';
///
///   @HostBinding('attr.checked')
///   String get checked => isChecked ? '' : null;
/// }
///```
class HostBinding {
  final String hostPropertyName;
  const HostBinding([this.hostPropertyName]);
}

/// Declares a host listener.
///
/// The decorated method is invoked when the host element emits the specified
/// event.
///
/// If the decorated method returns [false], then [preventDefault] is applied
/// on the DOM event.
///
/// ### Example
///
/// The following example declares a directive that attaches a click listener to
/// the button and counts clicks.
///
/// ```dart
/// @Directive(selector: 'button[counting]'')
/// class CountClicks {
///   int numberOfClicks = 0;
///
///   @HostListener('click', const [r'$event.target'])
///   void onClick(btn) {
///     print("Button $btn, number of clicks: ${numberOfClicks++}.");
///   }
/// }
///
/// @Component(
///   selector: 'app',
///   template: '<button counting>Increment</button>',
///   directives: const [CountClicks])
/// class App {}
/// ```
class HostListener {
  final String eventName;
  final List<String> args;
  const HostListener(this.eventName, [this.args]);
}
