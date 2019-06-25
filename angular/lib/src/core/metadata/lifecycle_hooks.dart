/// Lifecycle hooks are guaranteed to be called in the following order:
/// - `afterChanges` (if any bindings have been changed by the Angular framework),
/// - `onInit` (after the first check only),
/// - `doCheck`,
/// - `afterContentInit`,
/// - `afterContentChecked`,
/// - `afterViewInit`,
/// - `afterViewChecked`,
/// - `onDestroy` (at the very end before destruction)
library lifecycle_hooks;

/// Implement this interface to get notified when any data-bound property of
/// your directive is changed by the Angular framework.
///
/// [ngAfterChanges] is called right after the data-bound properties have been
/// checked and before view and content children are checked if at least one of
/// them has changed.
///
abstract class AfterChanges {
  void ngAfterChanges();
}

/// Implement to execute [ngOnInit] after the first change-detection completed.
///
/// [ngOnInit] is called right after the component or directive's data-bound
/// properties have been checked for the first time, and before any of its
/// children have been checked. It is normally only invoked once when the
/// directive is instantiated:
///
/// ```dart
/// @Component(
///   selector: 'user-panel',
///   directives: const [NgFor],
///   template: r'''
///     <li *ngFor="let user of users">
///       {{user}}
///     </li>
///   ''',
/// )
/// class UserPanel implements OnInit {
///   final RpcService _rpcService;
///
///   List<String> users = const [];
///
///   UserPanel(this._rpcService);
///
///   @override
///   void ngOnInit() async {
///     users = await _rpcService.getUsers();
///   }
/// }
/// ```
///
/// **Warning:** As part of [crash detection][] AngularDart may execute
/// [ngOnInit] a second time if part of the application threw an exception
/// during change detection.
///
/// [crash detection]: https://github.com/dart-lang/angular/blob/master/doc/crash_detection.md#crash-safety-for-angulardart
///
abstract class OnInit {
  /// Executed after the first change detection run for a directive.
  ///
  /// _See [OnInit] for a full description._
  void ngOnInit();
}

/// Implement to execute [ngOnDestroy] before your component is destroyed.
///
/// [ngOnDestroy] is invoked as AngularDart is removing the component or
/// directive from the DOM, as either it has been destroyed as a result of
/// a structural directive's request (`*ngIf` becoming `false`), or a parent
/// component is being destroyed. [ngOnDestroy] may be used to cleanup resources
/// such as [StreamSubscription]s:
///
/// ```dart
/// @Component(
///   selector: 'user-panel',
///   template: 'Online users: {{count}}',
/// )
/// class UserPanel implements OnInit, OnDestroy {
///   StreamSubscription _onlineUserSub;
///
///   int count = 0;
///
///   @override
///   void ngOnInit() {
///     _onlineUserSub = onlineUsers.listen((count) => this.count = count);
///   }
///
///   @override
///   void ngOnDestroy() {
///     _onlineUserSub.cancel();
///   }
/// }
/// ```
///
/// **Warning:** As part of [crash detection][] AngularDart may execute
/// [ngOnDestroy] a second time if part of the application threw an exception
/// during change detection. It is _not recommended_ to set values to `null`
/// as a result.
///
/// [crash detection]: https://github.com/dart-lang/angular/blob/master/doc/crash_detection.md#crash-safety-for-angulardart
///
abstract class OnDestroy {
  /// Executed before the directive is removed from the DOM and destroyed.
  ///
  /// _See [OnDestroy] for a full description._
  void ngOnDestroy();
}

/// Implement to execute [ngDoCheck] and implement your own change detection.
///
/// By default, AngularDart does an _identity_ based change detection of all
/// input bindings (`@Input()`). That is, for an `@Input() Object a`, if the
/// expression `identical(oldA, newA)` is `false`, AngularDart will invoke
/// `comp.a = newA`.
///
/// When [DoCheck] is implemented, AngularDart will _always_ invoke `comp.a = `,
/// meaning that the field (or setter) may get called multiple times with the
/// exact same object. This is used by `NgFor`, `NgStyle` and `NgClass`, for
/// example, in order to update when the _contents_ of the passed in collection
/// (either `Iterable` or `Map`) changes, not necessarily just if the identity
/// changes.
///
/// **WARNING**: It is invalid to trigger any asynchronous event in `ngDoCheck`.
/// Doing so may cause an infinite loop, as [DoCheck] will continue to be called
/// and the asynchronous events will invalidate the state.
///
/// **WARNING**: It is invalid to implement both [DoCheck] _and_ [OnChanges]
/// or [AfterChanges]. `ngOnChanges` and `ngAfterChanges` will never be called,
/// as `ngDoCheck` is used instead of the default change detector.
///
/// ### Examples
///
/// Try this [live example][ex] from the [Lifecycle Hooks][docs] page:
///
/// <?code-excerpt "docs/lifecycle-hooks/lib/src/do_check_component.dart (ng-do-check)"?>
/// ```dart
/// void ngDoCheck() {
///   if (hero.name != oldHeroName) {
///     changeDetected = true;
///     changeLog.add(
///         'DoCheck: Hero name changed to "${hero.name}" from "$oldHeroName"');
///     oldHeroName = hero.name;
///   }
///
///   if (power != oldPower) {
///     changeDetected = true;
///     changeLog.add('DoCheck: Power changed to "$power" from "$oldPower"');
///     oldPower = power;
///   }
///
///   if (changeDetected) {
///     noChangeCount = 0;
///   } else {
///     // log that hook was called when there was no relevant change.
///     var count = noChangeCount += 1;
///     var noChangeMsg =
///         'DoCheck called ${count}x when no change to hero or power';
///     if (count == 1) {
///       // add new "no change" message
///       changeLog.add(noChangeMsg);
///     } else {
///       // update last "no change" message
///       changeLog[changeLog.length - 1] = noChangeMsg;
///     }
///   }
///
///   changeDetected = false;
/// }
/// ```
///
/// [docs]: https://webdev.dartlang.org/angular/guide/lifecycle-hooks.html#docheck
/// [ex]: https://webdev.dartlang.org/examples/lifecycle-hooks#onchangeslifecycle-hooks#docheck
abstract class DoCheck {
  void ngDoCheck();
}

/// Implement this interface to get notified when your directive's content has
/// been fully initialized.
///
/// ### Examples
///
/// Try this [live example][ex] from the [Lifecycle Hooks][docs] page:
///
/// <?code-excerpt "docs/lifecycle-hooks/lib/src/after_content_component.dart (template)"?>
/// ```dart
/// template: '''
///   <div>-- projected content begins --</div>
///     <ng-content></ng-content>
///   <div>-- projected content ends --</div>
///   <p *ngIf="comment.isNotEmpty" class="comment">{{comment}}</p>
///   ''',
/// ```
///
/// <?code-excerpt "docs/lifecycle-hooks/lib/src/after_content_component.dart (hooks)"?>
/// ```dart
/// class AfterContentComponent implements AfterContentChecked, AfterContentInit {
///   String _prevHero = '';
///   String comment = '';
///
///   // Query for a CONTENT child of type `ChildComponent`
///   @ContentChild(ChildComponent)
///   ChildComponent contentChild;
///
///   @override
///   void ngAfterContentInit() {
///     // contentChild is set after the content has been initialized
///     _logIt('AfterContentInit');
///     _doSomething();
///   }
///
///   @override
///   void ngAfterContentChecked() {
///     // contentChild is updated after the content has been checked
///     if (_prevHero == contentChild?.hero) {
///       _logIt('AfterContentChecked (no change)');
///     } else {
///       _prevHero = contentChild?.hero;
///       _logIt('AfterContentChecked');
///       _doSomething();
///     }
///   }
///
///   // ...
/// }
/// ```
///
/// [docs]: https://webdev.dartlang.org/angular/guide/lifecycle-hooks.html#aftercontent
/// [ex]: https://webdev.dartlang.org/examples/lifecycle-hooks#after-content
abstract class AfterContentInit {
  void ngAfterContentInit();
}

/// Implement this interface to get notified after every check of your
/// directive's content.
///
/// ### Examples
///
/// Try this [live example][ex] from the [Lifecycle Hooks][docs] page:
///
/// <?code-excerpt "docs/lifecycle-hooks/lib/src/after_content_component.dart (template)"?>
/// ```dart
/// template: '''
///   <div>-- projected content begins --</div>
///     <ng-content></ng-content>
///   <div>-- projected content ends --</div>
///   <p *ngIf="comment.isNotEmpty" class="comment">{{comment}}</p>
///   ''',
/// ```
///
/// <?code-excerpt "docs/lifecycle-hooks/lib/src/after_content_component.dart (hooks)"?>
/// ```dart
/// class AfterContentComponent implements AfterContentChecked, AfterContentInit {
///   String _prevHero = '';
///   String comment = '';
///
///   // Query for a CONTENT child of type `ChildComponent`
///   @ContentChild(ChildComponent)
///   ChildComponent contentChild;
///
///   @override
///   void ngAfterContentInit() {
///     // contentChild is set after the content has been initialized
///     _logIt('AfterContentInit');
///     _doSomething();
///   }
///
///   @override
///   void ngAfterContentChecked() {
///     // contentChild is updated after the content has been checked
///     if (_prevHero == contentChild?.hero) {
///       _logIt('AfterContentChecked (no change)');
///     } else {
///       _prevHero = contentChild?.hero;
///       _logIt('AfterContentChecked');
///       _doSomething();
///     }
///   }
///
///   // ...
/// }
/// ```
///
/// [docs]: https://webdev.dartlang.org/angular/guide/lifecycle-hooks.html#aftercontent
/// [ex]: https://webdev.dartlang.org/examples/lifecycle-hooks#after-content
abstract class AfterContentChecked {
  void ngAfterContentChecked();
}

/// Implement this interface to get notified when your component's view has been
/// fully initialized.
///
/// ### Examples
///
/// Try this [live example][ex] from the [Lifecycle Hooks][docs] page:
///
/// <?code-excerpt "docs/lifecycle-hooks/lib/src/after_view_component.dart (template)"?>
/// ```dart
/// template: '''
///   <div>-- child view begins --</div>
///     <my-child-view></my-child-view>
///   <div>-- child view ends --</div>
///   <p *ngIf="comment.isNotEmpty" class="comment">{{comment}}</p>''',
/// ```
///
/// <?code-excerpt "docs/lifecycle-hooks/lib/src/after_view_component.dart (hooks)"?>
/// ```dart
/// class AfterViewComponent implements AfterViewChecked, AfterViewInit {
///   var _prevHero = '';
///
///   // Query for a VIEW child of type `ChildViewComponent`
///   @ViewChild(ChildViewComponent)
///   ChildViewComponent viewChild;
///
///   @override
///   void ngAfterViewInit() {
///     // viewChild is set after the view has been initialized
///     _logIt('AfterViewInit');
///     _doSomething();
///   }
///
///   @override
///   void ngAfterViewChecked() {
///     // viewChild is updated after the view has been checked
///     if (_prevHero == viewChild.hero) {
///       _logIt('AfterViewChecked (no change)');
///     } else {
///       _prevHero = viewChild.hero;
///       _logIt('AfterViewChecked');
///       _doSomething();
///     }
///   }
///   // ...
/// }
/// ```
///
/// [docs]: https://webdev.dartlang.org/angular/guide/lifecycle-hooks.html#afterview
/// [ex]: https://webdev.dartlang.org/examples/lifecycle-hooks#after-view
abstract class AfterViewInit {
  void ngAfterViewInit();
}

/// Implement this interface to get notified after every check of your
/// component's view.
///
/// ### Examples
///
/// Try this [live example][ex] from the [Lifecycle Hooks][docs] page:
///
/// <?code-excerpt "docs/lifecycle-hooks/lib/src/after_view_component.dart (template)"?>
/// ```dart
/// template: '''
///   <div>-- child view begins --</div>
///     <my-child-view></my-child-view>
///   <div>-- child view ends --</div>
///   <p *ngIf="comment.isNotEmpty" class="comment">{{comment}}</p>''',
/// ```
///
/// <?code-excerpt "docs/lifecycle-hooks/lib/src/after_view_component.dart (hooks)"?>
/// ```dart
/// class AfterViewComponent implements AfterViewChecked, AfterViewInit {
///   var _prevHero = '';
///
///   // Query for a VIEW child of type `ChildViewComponent`
///   @ViewChild(ChildViewComponent)
///   ChildViewComponent viewChild;
///
///   @override
///   void ngAfterViewInit() {
///     // viewChild is set after the view has been initialized
///     _logIt('AfterViewInit');
///     _doSomething();
///   }
///
///   @override
///   void ngAfterViewChecked() {
///     // viewChild is updated after the view has been checked
///     if (_prevHero == viewChild.hero) {
///       _logIt('AfterViewChecked (no change)');
///     } else {
///       _prevHero = viewChild.hero;
///       _logIt('AfterViewChecked');
///       _doSomething();
///     }
///   }
///   // ...
/// }
/// ```
///
/// [docs]: https://webdev.dartlang.org/angular/guide/lifecycle-hooks.html#afterview
/// [ex]: https://webdev.dartlang.org/examples/lifecycle-hooks#after-view
abstract class AfterViewChecked {
  void ngAfterViewChecked();
}
