@TestOn('browser && !js')
library angular2.test.core.compiler.directive_lifecycle_test;

import 'package:angular2/src/compiler/directive_lifecycle_reflector.dart';
import 'package:angular2/src/core/metadata/lifecycle_hooks.dart';
import 'package:angular2/testing_internal.dart';
import 'package:test/test.dart';

void main() {
  group('Directive lifecycle', () {
    setUp(() async {
      await inject([], () {});
    });
    group("ngOnChanges", () {
      test("should be true when the directive has the ngOnChanges method", () {
        expect(
            hasLifecycleHook(
                LifecycleHooks.OnChanges, DirectiveImplementingOnChanges),
            isTrue);
      });

      test("should be false otherwise", () {
        expect(hasLifecycleHook(LifecycleHooks.OnChanges, DirectiveNoHooks),
            isFalse);
      });
    });

    group("ngOnDestroy", () {
      test("should be true when the directive has the ngOnDestroy method", () {
        expect(
            hasLifecycleHook(
                LifecycleHooks.OnDestroy, DirectiveImplementingOnDestroy),
            isTrue);
      });

      test("should be false otherwise", () {
        expect(hasLifecycleHook(LifecycleHooks.OnDestroy, DirectiveNoHooks),
            isFalse);
      });
    });

    group("ngOnInit", () {
      test("should be true when the directive has the ngOnInit method", () {
        expect(
            hasLifecycleHook(
                LifecycleHooks.OnInit, DirectiveImplementingOnInit),
            isTrue);
      });

      test("should be false otherwise", () {
        expect(
            hasLifecycleHook(LifecycleHooks.OnInit, DirectiveNoHooks), isFalse);
      });
    });

    group("ngDoCheck", () {
      test("should be true when the directive has the ngDoCheck method", () {
        expect(
            hasLifecycleHook(
                LifecycleHooks.DoCheck, DirectiveImplementingOnCheck),
            isTrue);
      });

      test("should be false otherwise", () {
        expect(hasLifecycleHook(LifecycleHooks.DoCheck, DirectiveNoHooks),
            isFalse);
      });
    });

    group("ngAfterContentInit", () {
      test(
          "should be true when the directive has the ngAfterContentInit method",
          () {
        expect(
            hasLifecycleHook(LifecycleHooks.AfterContentInit,
                DirectiveImplementingAfterContentInit),
            isTrue);
      });

      test("should be false otherwise", () {
        expect(
            hasLifecycleHook(LifecycleHooks.AfterContentInit, DirectiveNoHooks),
            isFalse);
      });
    });

    group("ngAfterContentChecked", () {
      test(
          "should be true when the directive has the ngAfterContentChecked method",
          () {
        expect(
            hasLifecycleHook(LifecycleHooks.AfterContentChecked,
                DirectiveImplementingAfterContentChecked),
            isTrue);
      });

      test("should be false otherwise", () {
        expect(
            hasLifecycleHook(
                LifecycleHooks.AfterContentChecked, DirectiveNoHooks),
            isFalse);
      });
    });

    group("ngAfterViewInit", () {
      test("should be true when the directive has the ngAfterViewInit method",
          () {
        expect(
            hasLifecycleHook(LifecycleHooks.AfterViewInit,
                DirectiveImplementingAfterViewInit),
            isTrue);
      });

      test("should be false otherwise", () {
        expect(hasLifecycleHook(LifecycleHooks.AfterViewInit, DirectiveNoHooks),
            isFalse);
      });
    });

    group("ngAfterViewChecked", () {
      test(
          "should be true when the directive has the ngAfterViewChecked method",
          () {
        expect(
            hasLifecycleHook(LifecycleHooks.AfterViewChecked,
                DirectiveImplementingAfterViewChecked),
            isTrue);
      });

      test("should be false otherwise", () {
        expect(
            hasLifecycleHook(LifecycleHooks.AfterViewChecked, DirectiveNoHooks),
            isFalse);
      });
    });
  });
}

class DirectiveNoHooks {}

class DirectiveImplementingOnChanges implements OnChanges {
  @override
  ngOnChanges(_) {}
}

class DirectiveImplementingOnCheck implements DoCheck {
  @override
  ngDoCheck() {}
}

class DirectiveImplementingOnInit implements OnInit {
  @override
  ngOnInit() {}
}

class DirectiveImplementingOnDestroy implements OnDestroy {
  @override
  ngOnDestroy() {}
}

class DirectiveImplementingAfterContentInit implements AfterContentInit {
  @override
  ngAfterContentInit() {}
}

class DirectiveImplementingAfterContentChecked implements AfterContentChecked {
  @override
  ngAfterContentChecked() {}
}

class DirectiveImplementingAfterViewInit implements AfterViewInit {
  @override
  ngAfterViewInit() {}
}

class DirectiveImplementingAfterViewChecked implements AfterViewChecked {
  @override
  ngAfterViewChecked() {}
}
