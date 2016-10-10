import "package:angular2/src/core/change_detection.dart"
    show ChangeDetectionStrategy;
import "package:angular2/src/core/di/metadata.dart" show InjectableMetadata;
import "package:angular2/src/core/metadata/view.dart" show ViewEncapsulation;

class DirectiveMetadata extends InjectableMetadata {
  /// The CSS selector that triggers the instantiation of a directive.
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
  /// Suppose we have a directive with an `input[type=text]` selector.
  ///
  /// And the following HTML:
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

  /// Enumerates the set of data-bound input properties for a directive
  ///
  /// Angular automatically updates input properties during change detection.
  ///
  /// The [inputs] property defines a set of _directiveProperty_ to
  /// _bindingProperty_ configuration:
  ///
  /// - _directiveProperty_ specifies the component property where the value
  ///   is written.
  /// - _bindingProperty_ specifies the DOM property where the value is read
  ///   from.
  ///
  /// When _bindingProperty_ is not provided, it is assumed to be equal to
  /// _directiveProperty_.
  ///
  /// The following example creates a component with two data-bound properties.
  ///
  /// ```dart
  /// @Component(
  ///   selector: 'bank-account',
  ///   inputs: const ['bankName', 'id: account-id'],
  ///   template: '''
  ///     Bank Name: {{bankName}}
  ///     Account Id: {{id}}
  ///   ''')
  /// class BankAccount {
  ///   String bankName, id;
  ///
  ///   // This property is not bound, and won't be automatically updated by
  ///   // Angular
  ///   String normalizedBankName;
  /// }
  ///
  /// @Component(
  ///   selector: 'app',
  ///   template: '''
  ///     <bank-account bank-name="RBC" account-id="4747"></bank-account>
  ///   ''',
  ///   directives: const [BankAccount])
  /// class App {}
  /// ```
  final List<String> inputs;

  /// Enumerates the set of event-bound output properties.
  ///
  /// When an output property emits an event, an event handler attached to
  /// that event the template is invoked.
  ///
  /// The [outputs] property defines a set of _directiveProperty_ to
  /// _bindingProperty_ configuration:
  ///
  /// - _directiveProperty_ specifies the component property that emits events.
  /// - _bindingProperty_ specifies the DOM property the event handler is
  /// attached to.
  ///
  /// ```dart
  /// @Directive(
  ///   selector: 'interval-dir',
  ///   outputs: const ['everySecond', 'five5Secs: everyFiveSeconds'])
  /// class IntervalDir {
  ///   final everySecond = new EventEmitter<String>();
  ///
  ///   final five5Secs = new EventEmitter<String>();
  ///
  ///   IntervalDir() {
  ///     setInterval(() => everySecond.emit("event"), 1000);
  ///     setInterval(() => five5Secs.emit("event"), 5000);
  ///   }
  /// }
  ///
  /// @Component(
  ///   selector: 'app',
  ///   template: '''
  ///     <interval-dir (everySecond)="everySecond()" (everyFiveSeconds)="everyFiveSeconds()">
  ///     </interval-dir>
  ///   ''',
  ///   directives: const [IntervalDir])
  /// class App {
  ///   everySecond() { print('second'); }
  ///   everyFiveSeconds() { print('five seconds'); }
  /// }
  /// ```
  final List<String> outputs;

  /// Specify the events, actions, properties and attributes related to the host
  /// element.
  ///
  /// ## Host Listeners
  /// Specifies which DOM events a directive listens to via a set of '(_event_)'
  /// to _statement_ key-value pairs:
  ///
  /// - _event_: the DOM event that the directive listens to
  /// - _statement_: the statement to execute when the event occurs
  ///
  /// If the evaluation of the statement returns [false], then [preventDefault]
  /// is applied on the DOM event.
  ///
  /// To listen to global events, a target must be added to the event name.
  /// The target can be `window`, `document` or `body`.
  ///
  /// When writing a directive event binding, you can also refer to the $event
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
  /// ## Host Property Bindings
  /// Specifies which DOM properties a directive updates.
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
  ///       directives: [FORM_DIRECTIVES, NgModelStatus]
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
  final Map<String, String> host;

  /// Defines the set of injectable objects that are visible to a Directive and
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
  final List providers;

  /// Defines the name that can be used in the template to assign this directive
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

  /// Configures the queries that will be injected into the directive.
  ///
  /// Content queries are set before the [ngAfterContentInit] callback is
  /// called. View queries are set before the [ngAfterViewInit] callback is
  /// called.
  ///
  /// ### Example
  ///
  ///     @Component(
  ///       selector: 'someDir',
  ///       queries: const {
  ///         'contentChildren': const ContentChildren(ChildDirective),
  ///         'viewChildren': const ViewChildren(ChildDirective),
  ///         'contentChild': const ContentChild(SingleChildDirective),
  ///         'viewChild': const ViewChild(SingleChildDirective)
  ///       },
  ///       template: '''
  ///         <child-directive></child-directive>
  ///         <single-child-directive></single-child-directive>
  ///         <ng-content></ng-content>
  ///       ''',
  ///       directives: const [ChildDirective, SingleChildDirective])
  ///     class SomeDir {
  ///       QueryList<ChildDirective> contentChildren;
  ///       QueryList<ChildDirective> viewChildren;
  ///       SingleChildDirective contentChild;
  ///       SingleChildDirective viewChild;
  ///
  ///       ngAfterContentInit() {
  ///         // contentChildren is set
  ///         // contentChild is set
  ///       }
  ///
  ///       ngAfterViewInit() {
  ///         // viewChildren is set
  ///         // viewChild is set
  ///       }
  ///     }
  ///
  final Map<String, dynamic> queries;

  const DirectiveMetadata(
      {String selector,
      this.inputs,
      this.outputs,
      Map<String, String> host,
      this.providers,
      String exportAs,
      Map<String, dynamic> queries})
      : selector = selector,
        host = host,
        exportAs = exportAs,
        queries = queries,
        super();
}

class ComponentMetadata extends DirectiveMetadata {
  /// Defines the used change detection strategy.
  ///
  /// When a component is instantiated, Angular creates a change detector, which
  /// is responsible for propagating the component's bindings.
  ///
  /// The [changeDetection] property defines, whether the change detection will
  /// be checked every time or only when the component tells it to do so.
  final ChangeDetectionStrategy changeDetection;

  /// Defines the set of injectable objects that are visible to its view DOM children.
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
  List get viewProviders => (_viewBindings != null && _viewBindings.isNotEmpty)
      ? this._viewBindings
      : this._viewProviders;

  List get viewBindings {
    return this.viewProviders;
  }

  final List _viewProviders;
  final List _viewBindings;

  /// The module id of the module that contains the component.
  /// Needed to be able to resolve relative urls for templates and styles.
  /// In Dart, this can be determined automatically and does not need to be set.
  /// In CommonJS, this can always be set to `module.id`.
  ///
  /// ### Example
  ///
  ///     @Directive(
  ///       selector: 'someDir',
  ///       moduleId: module.id
  ///     })
  ///     class SomeDir {
  ///     }
  ///
  final String moduleId;
  final String templateUrl;
  final String template;
  final bool preserveWhitespace;
  final List<String> styleUrls;
  final List<String> styles;
  final List<dynamic /* Type | List < dynamic > */ > directives;
  final List<dynamic /* Type | List < dynamic > */ > pipes;
  final ViewEncapsulation encapsulation;
  const ComponentMetadata(
      {String selector,
      List<String> inputs,
      List<String> outputs,
      Map<String, String> host,
      String exportAs,
      this.moduleId,
      List providers,
      List viewBindings,
      List viewProviders,
      this.changeDetection: ChangeDetectionStrategy.Default,
      Map<String, dynamic> queries,
      this.templateUrl,
      this.template,
      this.preserveWhitespace: false,
      this.styleUrls,
      this.styles,
      this.directives,
      this.pipes,
      this.encapsulation})
      : _viewProviders = viewProviders,
        _viewBindings = viewBindings,
        super(
            selector: selector,
            inputs: inputs,
            outputs: outputs,
            host: host,
            exportAs: exportAs,
            providers: providers,
            queries: queries);
}

/// Declare reusable pipe function.
///
/// A "pure" pipe is only re-evaluated when either the input or any of the
/// arguments change. When not specified, pipes default to being pure.
///
class PipeMetadata extends InjectableMetadata {
  final String name;
  final bool _pure;
  const PipeMetadata({this.name, bool pure})
      : _pure = pure,
        super();
  bool get pure => _pure ?? true;
}

class InputMetadata {
  final String bindingPropertyName;
  const InputMetadata(
      [

      /// Name used when instantiating a component in the template.
      this.bindingPropertyName]);
}

class OutputMetadata {
  final String bindingPropertyName;
  const OutputMetadata([this.bindingPropertyName]);
}

class HostBindingMetadata {
  final String hostPropertyName;
  const HostBindingMetadata([this.hostPropertyName]);
}

class HostListenerMetadata {
  final String eventName;
  final List<String> args;
  const HostListenerMetadata(this.eventName, [this.args]);
}
