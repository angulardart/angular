// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:angular_router/angular_router.dart';

void main() {
  group('$RouteLibrary', () {
    test('should set all properties', () {
      RouteLibrary parent = new RouteLibrary();
      RouteLibrary library = new RouteLibrary(
          path: 'path',
          useAsDefault: true,
          additionalData: 'data',
          parent: parent);
      expect(library.path, 'path');
      expect(library.useAsDefault, true);
      expect(library.additionalData, 'data');
      expect(library.parent, parent);
    });

    group('fromRoutes', () {
      test('should set all properties from routes', () {
        RouteLibrary library = new RouteLibrary.fromRoutes([
          new RouteDefinition(
              path: 'path', useAsDefault: true, additionalData: 'data')
        ]);
        expect(library.path, 'path');
        expect(library.useAsDefault, true);
        expect(library.additionalData, 'data');
        expect(library.parent, isNull);
      });

      test('should take properties from last route', () {
        RouteLibrary library = new RouteLibrary.fromRoutes([
          new RouteDefinition(),
          new RouteDefinition(
              path: 'path', useAsDefault: true, additionalData: 'data')
        ]);
        expect(library.path, 'path');
        expect(library.useAsDefault, true);
        expect(library.additionalData, 'data');
        expect(library.parent, isNotNull);
      });

      test('should construct with an empty list', () {
        RouteLibrary library = new RouteLibrary.fromRoutes([]);
        expect(library.path, '');
        expect(library.useAsDefault, false);
        expect(library.additionalData, isNull);
        expect(library.parent, isNull);
      });

      test('should chain libraries', () {
        RouteLibrary library = new RouteLibrary.fromRoutes([
          new RouteDefinition(path: 'path1'),
          new RouteDefinition(path: 'path2'),
          new RouteDefinition(path: 'path3')
        ]);
        expect(library.path, 'path3');
        expect(library.parent.path, 'path2');
        expect(library.parent.parent.path, 'path1');
        expect(library.parent.parent.parent, isNull);
      });
    });

    group('path', () {
      test('path should return a slash-trimmed version of the path', () {
        RouteLibrary library = new RouteLibrary(path: '/path/');
        expect(library.path, 'path');
        library =
            new RouteLibrary.fromRoutes([new RouteDefinition(path: '/path/')]);
        expect(library.path, 'path');
      });
    });

    group('toUrl', () {
      RouteLibrary library;

      setUpAll(() {
        RouteLibrary parentParentLibrary =
            new RouteLibrary(path: 'path1/:param1');
        RouteLibrary parentLibrary = new RouteLibrary(
            path: 'path2/:param2', parent: parentParentLibrary);
        library =
            new RouteLibrary(path: 'path3/:param3', parent: parentLibrary);
      });

      test('should join the parent paths and the last path', () {
        expect(library.toUrl(), '/path1/:param1/path2/:param2/path3/:param3');
      });

      test('should replace parameters', () {
        expect(
            library.toUrl(parameters: {
              'param1': 'one',
              'param2': 'two',
              'param3': 'three',
              'ignored': 'something',
            }),
            '/path1/one/path2/two/path3/three');
      });

      test('should append queryParameters and fragment', () {
        expect(
            library.toUrl(queryParameters: {
              'param': 'one',
            }, fragment: 'frag'),
            '/path1/:param1/path2/:param2/path3/:param3?param=one#frag');
      });

      test('should url encode parameters', () {
        expect(library.toUrl(parameters: {'param1': 'one two'}),
            '/path1/one%20two/path2/:param2/path3/:param3');
      });

      test('should url encode queryParameters', () {
        expect(
            library.toUrl(queryParameters: {
              'param 1': 'one',
            }),
            '/path1/:param1/path2/:param2/path3/:param3?param%201=one');
      });
    });
  });
}
