@Skip('see TODO to enable codegen')
library angular2.test.testing.ng_test_bed_test;

import 'dart:async';
import 'dart:html';

import 'package:angular2/angular2.dart';
import 'package:angular2/src/testing/test_bed/ng_dom_stabilizer.dart';
import 'package:angular2/src/testing/test_bed/ng_test_bed.dart';
import 'package:test/test.dart';

// TODO(matanl): Modify pubspec.yaml and our travis script to codegen this.
// 1. Modify pubspec.yaml and run the transformer on this test.
// 2. Make sure pub run test provides --pub-serve=8080 to serve this test.
void main() {
  group('$NgTestBed (typical case)', () {
    NgTestBed<HelloWorldComponent> ngTestBed;
    NgTestRoot<HelloWorldComponent> ngTestRoot;

    setUp(() {
      ngTestBed = new NgTestBed<HelloWorldComponent>();
    });

    tearDown(() => ngTestRoot.dispose());

    test('should load a component into the DOM', () async {
      expect(
        document.body.text,
        isNot(contains('Hello World')),
        reason: 'No element should be in the DOM with text "Hello World".',
      );
      ngTestRoot = await ngTestBed.create();
      expect(
        document.body.text,
        contains('Hello World'),
        reason: 'HelloWorldComponent should be visible in the DOM',
      );
    });
  });

  group('$NgTestBed (async work)', () {
    NgTestBed<AsyncHelloWorldComponent> ngTestBed;
    NgTestRoot<AsyncHelloWorldComponent> ngTestRoot;

    setUp(() {
      ngTestBed = new NgTestBed<AsyncHelloWorldComponent>();
    });

    tearDown(() => ngTestRoot.dispose());

    test('should not process any async work by default', () async {
      expect(
        document.body.text,
        isNot(contains('Hello World')),
        reason: 'No element should be in the DOM with text "Hello World".',
      );
      ngTestRoot = await ngTestBed.create();
      expect(
        document.body.text,
        isNot(contains('Hello World')),
        reason: 'Timer should not have fired yet',
      );
    });

    test('should process async work when NgZoneStabilizer is added', () async {
      expect(
        document.body.text,
        isNot(contains('Hello World')),
        reason: 'No element should be in the DOM with text "Hello World".',
      );
      ngTestRoot = await ngTestBed.addStabilizers([NgZoneStabilizer]).create();
      expect(
        document.body.text,
        contains('Hello World'),
        reason: 'Timer should have elapsed showing "Hello World"',
      );
    });
  });

  group('$NgTestBed (error cases)', () {
    // Since we have error cases that specifically do bad things, we should
    // recover gracefully after each test so we can continue with the next one.
    tearDown(() => disposeActiveTestIfAny());

    test('should throw when a component type parameter is not passed', () {
      expect(() => new NgTestBed(), throwsUnsupportedError);
    });

    test('should throw when another test is still running', () async {
      var ngTestBed = new NgTestBed<HelloWorldComponent>();
      await ngTestBed.create();
      expect(() => ngTestBed.create(), throwsUnsupportedError);
    });

    test('should throw when no test is running', () async {
      var ngTestBed = new NgTestBed<HelloWorldComponent>();
      var ngTestRoot = await ngTestBed.create();
      await ngTestRoot.dispose();
      expect(() => ngTestRoot.dispose(), throwsStateError);
    });

    test('should throw when a provider is not valid', () async {
      var ngTestBed = new NgTestBed<HelloWorldComponent>();
      expect(() => ngTestBed.addProviders([Foo, null, Foo]), throws);
    });
  });
}

@Injectable()
class Foo {}

@Component(selector: 'hello-world', template: 'Hello World')
class HelloWorldComponent {}

@Component(selector: 'hello-world', template: '{{state}}')
class AsyncHelloWorldComponent implements OnInit {
  String state = 'Waiting...';

  AsyncHelloWorldComponent() {
    Timer.run(() {
      state = 'Constructor...';
    });
  }

  @override
  void ngOnInit() {
    Timer.run(() {
      state = 'Hello World';
    });
  }
}
