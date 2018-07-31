// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('browser')
import 'package:test/test.dart';
import 'package:angular_router/angular_router.dart';

void main() {
  group('$RoutePath', () {
    test('should set all properties', () {
      RoutePath parent = RoutePath();
      RoutePath routePath = RoutePath(
          path: 'path',
          useAsDefault: true,
          additionalData: 'data',
          parent: parent);
      expect(routePath.path, 'path');
      expect(routePath.useAsDefault, true);
      expect(routePath.additionalData, 'data');
      expect(routePath.parent, parent);
    });

    group('fromRoutes', () {
      test('should set all properties from routes', () {
        RoutePath routePath = RoutePath.fromRoutes([
          RouteDefinition(
              path: 'path', useAsDefault: true, additionalData: 'data')
        ]);
        expect(routePath.path, 'path');
        expect(routePath.useAsDefault, true);
        expect(routePath.additionalData, 'data');
        expect(routePath.parent, isNull);
      });

      test('should take properties from last route', () {
        RoutePath routePath = RoutePath.fromRoutes([
          RouteDefinition(),
          RouteDefinition(
              path: 'path', useAsDefault: true, additionalData: 'data')
        ]);
        expect(routePath.path, 'path');
        expect(routePath.useAsDefault, true);
        expect(routePath.additionalData, 'data');
        expect(routePath.parent, isNotNull);
      });

      test('should construct with an empty list', () {
        RoutePath routePath = RoutePath.fromRoutes([]);
        expect(routePath.path, '');
        expect(routePath.useAsDefault, false);
        expect(routePath.additionalData, isNull);
        expect(routePath.parent, isNull);
      });

      test('should chain libraries', () {
        RoutePath routePath = RoutePath.fromRoutes([
          RouteDefinition(path: 'path1'),
          RouteDefinition(path: 'path2'),
          RouteDefinition(path: 'path3')
        ]);
        expect(routePath.path, 'path3');
        expect(routePath.parent.path, 'path2');
        expect(routePath.parent.parent.path, 'path1');
        expect(routePath.parent.parent.parent, isNull);
      });
    });

    group('path', () {
      test('should return a slash-trimmed version of the path', () {
        RoutePath routePath = RoutePath(path: '/path/');
        expect(routePath.path, 'path');
        routePath = RoutePath.fromRoutes([RouteDefinition(path: '/path/')]);
        expect(routePath.path, 'path');
      });
    });

    group('toUrl()', () {
      RoutePath routePath;

      setUpAll(() {
        RoutePath parentParentPath = RoutePath(path: 'path1/:param1');
        RoutePath parentPath =
            RoutePath(path: 'path2/:param2', parent: parentParentPath);
        routePath = RoutePath(path: 'path3/:param3', parent: parentPath);
      });

      test('should join the parent paths and the last path', () {
        expect(routePath.toUrl(), '/path1/:param1/path2/:param2/path3/:param3');
      });

      test('should replace parameters', () {
        expect(
            routePath.toUrl(parameters: {
              'param1': 'one',
              'param2': 'two',
              'param3': 'three',
              'ignored': 'something',
            }),
            '/path1/one/path2/two/path3/three');
      });

      test('should append queryParameters and fragment', () {
        expect(
            routePath.toUrl(queryParameters: {
              'param': 'one',
            }, fragment: 'frag'),
            '/path1/:param1/path2/:param2/path3/:param3?param=one#frag');
      });

      test('should url encode parameters', () {
        expect(routePath.toUrl(parameters: {'param1': 'one two'}),
            '/path1/one%20two/path2/:param2/path3/:param3');
      });

      test('should url encode queryParameters', () {
        expect(
            routePath.toUrl(queryParameters: {
              'param 1': 'one',
            }),
            '/path1/:param1/path2/:param2/path3/:param3?param%201=one');
      });
    });

    test('toUrl() should handle empty parent path', () {
      final a = RoutePath(path: '');
      final b = RoutePath(path: 'foo', parent: a);
      final c = RoutePath(path: '', parent: b);
      final d = RoutePath(path: 'bar', parent: c);
      expect(d.toUrl(), '/foo/bar');
    });
  });
}
