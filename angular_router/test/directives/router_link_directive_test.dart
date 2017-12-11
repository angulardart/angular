// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('browser')
import 'dart:async';
import 'dart:html' hide Location;
import 'dart:js';

import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:angular_test/angular_test.dart';

import 'router_link_directive_test.template.dart' as ng_generated;

void main() {
  ng_generated.initReflector();

  FakeRouter fakeRouter;

  setUp(() {
    fakeRouter = new FakeRouter();
  });

  tearDown(disposeAnyRunningTest);

  test('should attempt to navigate to the provided link', () async {
    final fixture = await new NgTestBed<TestRouterLink>().addProviders([
      provide(Location, useValue: const FakeLocation()),
      provide(Router, useValue: fakeRouter),
    ]).create();
    final anchor = fixture.rootElement.querySelector('a') as AnchorElement;
    expect(anchor.pathname, isEmpty);
    await fixture.update((comp) {
      comp.routerLink = '/users/bob';
    });
    expect(anchor.pathname, '/users/bob');
    expect(fakeRouter.lastNavigatedPath, isNull);
    await fixture.update((_) => anchor.click());
    expect(fakeRouter.lastNavigatedPath, '/users/bob');
  });

  test('should attempt to navigate on Enter key press', () async {
    final testBed = new NgTestBed<TestRouterLinkKeyPress>().addProviders([
      provide(Location, useValue: const FakeLocation()),
      provide(Router, useValue: fakeRouter),
    ]);
    final testFixture = await testBed.create();
    final div = testFixture.rootElement.querySelector('div');
    final keyboardEvent = createKeyboardEvent('keypress', KeyCode.ENTER);
    expect(fakeRouter.lastNavigatedPath, isNull);
    await testFixture.update((_) => div.dispatchEvent(keyboardEvent));
    expect(fakeRouter.lastNavigatedPath, '/foo/bar');
  });

  test('should parse out query params and fragment', () async {
    final fixture = await new NgTestBed<TestRouterLink>().addProviders([
      provide(Location, useValue: const FakeLocation()),
      provide(Router, useValue: fakeRouter),
    ]).create(beforeChangeDetection: (comp) {
      comp.routerLink = '/users/bob?param1=one&param2=2#frag';
    });
    final anchor = fixture.rootElement.querySelector('a') as AnchorElement;
    expect(anchor.pathname, '/users/bob');
    await fixture.update((_) => anchor.click());
    expect(fakeRouter.lastNavigatedPath, '/users/bob');
    expect(fakeRouter.lastNavigatedParams.queryParameters, {
      'param1': 'one',
      'param2': '2',
    });
    expect(fakeRouter.lastNavigatedParams.fragment, 'frag');
  });

  test('should not use the router when the target is not _self', () async {
    final fixture =
        await new NgTestBed<TestRouterLinkWithTarget>().addProviders([
      provide(Location, useValue: const FakeLocation()),
      provide(Router, useValue: fakeRouter),
    ]).create(beforeChangeDetection: (comp) {
      comp.routerLink = '/users/bob';
    });
    final anchor = fixture.rootElement.querySelector('a') as AnchorElement;
    expect(anchor.pathname, '/users/bob');
    expect(anchor.target, '_parent');
    await fixture.update((_) => anchor.click());
    expect(fakeRouter.lastNavigatedPath, isNull);
  });
}

@Component(
  selector: 'test-router-link',
  directives: const [
    RouterLink,
  ],
  template: r'''
    <a [routerLink]="routerLink"></a>
  ''',
)
class TestRouterLink {
  String routerLink;
}

@Component(
  selector: 'test-router-link-keypress',
  template: '<div [routerLink]="routerLink"></div>',
  directives: const [RouterLink],
)
class TestRouterLinkKeyPress {
  String routerLink = '/foo/bar';
}

@Component(
  selector: 'test-router-link',
  directives: const [
    RouterLink,
  ],
  template: r'''
    <a (click)="onClick($event)" [routerLink]="routerLink" target="_parent"></a>
  ''',
)
class TestRouterLinkWithTarget {
  String routerLink;

  void onClick(MouseEvent event) {
    // Prevent navigating away from test page.
    event.preventDefault();
  }
}

class FakeRouter implements Router {
  String lastNavigatedPath;
  NavigationParams lastNavigatedParams;

  @override
  Future<NavigationResult> navigate(
    String routerLink, [
    NavigationParams navigationParams,
    bool _,
  ]) async {
    lastNavigatedPath = routerLink;
    lastNavigatedParams = navigationParams;
    return null;
  }

  @override
  noSuchMethod(i) => super.noSuchMethod(i);
}

class FakeLocation implements Location {
  const FakeLocation();

  @override
  String prepareExternalUrl(String url) => url;

  @override
  noSuchMethod(i) => null;
}

const _createKeyboardEventName = '__dart_createKeyboardEvent';
const _createKeyboardEventScript = '''
window['$_createKeyboardEventName'] = function(
    type, keyCode, ctrlKey, altKey, shiftKey, metaKey) {
  var event = document.createEvent('KeyboardEvent');

  // Chromium hack.
  Object.defineProperty(event, 'keyCode', {
    get: function() { return keyCode; }
  });

  // Creating keyboard events programmatically isn't supported and relies on
  // these deprecated APIs.
  if (event.initKeyboardEvent) {
    event.initKeyboardEvent(type, true, true, document.defaultView, keyCode,
        keyCode, ctrlKey, altKey, shiftKey, metaKey);
  } else {
    event.initKeyEvent(type, true, true, document.defaultView, ctrlKey, altKey,
        shiftKey, metaKey, keyCode, keyCode);
  }

  return event;
}
''';

Event createKeyboardEvent(
  String type,
  int keyCode, {
  bool ctrlKey: false,
  bool altKey: false,
  bool shiftKey: false,
  bool metaKey: false,
}) {
  if (!context.hasProperty(_createKeyboardEventName)) {
    final script = document.createElement('script')
      ..setAttribute('type', 'text/javascript')
      ..text = _createKeyboardEventScript;
    document.body.append(script);
  }
  return context.callMethod(_createKeyboardEventName,
      [type, keyCode, ctrlKey, altKey, shiftKey, metaKey]);
}
