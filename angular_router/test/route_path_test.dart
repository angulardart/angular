import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';

import 'route_path_test.template.dart' as ng;

void main() {
  group('$RoutePath', () {
    test('should set all properties', () {
      var parent = RoutePath(path: '');
      var routePath = RoutePath(
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
        var routePath = RoutePath.fromRoutes([
          RouteDefinition(
            path: 'path',
            useAsDefault: true,
            additionalData: 'data',
            component: ng.createTestComponentFactory(),
          )
        ]);
        expect(routePath.path, 'path');
        expect(routePath.useAsDefault, true);
        expect(routePath.additionalData, 'data');
        expect(routePath.parent, isNull);
      });

      test('should take properties from last route', () {
        var routePath = RoutePath.fromRoutes([
          RouteDefinition(
            path: '',
            component: ng.createTestComponentFactory(),
          ),
          RouteDefinition(
            path: 'path',
            useAsDefault: true,
            additionalData: 'data',
            component: ng.createTestComponentFactory(),
          )
        ]);
        expect(routePath.path, 'path');
        expect(routePath.useAsDefault, true);
        expect(routePath.additionalData, 'data');
        expect(routePath.parent, isNotNull);
      });

      test('should construct with an empty list', () {
        var routePath = RoutePath.fromRoutes([]);
        expect(routePath.path, '');
        expect(routePath.useAsDefault, false);
        expect(routePath.additionalData, isNull);
        expect(routePath.parent, isNull);
      });

      test('should chain libraries', () {
        var routePath = RoutePath.fromRoutes([
          RouteDefinition(
            path: 'path1',
            component: ng.createTestComponentFactory(),
          ),
          RouteDefinition(
            path: 'path2',
            component: ng.createTestComponentFactory(),
          ),
          RouteDefinition(
            path: 'path3',
            component: ng.createTestComponentFactory(),
          )
        ]);
        expect(routePath.path, 'path3');
        expect(routePath.parent!.path, 'path2');
        expect(routePath.parent!.parent!.path, 'path1');
        expect(routePath.parent!.parent!.parent, isNull);
      });
    });

    group('path', () {
      test('should return a slash-trimmed version of the path', () {
        var routePath = RoutePath(path: '/path/');
        expect(routePath.path, 'path');
        routePath = RoutePath.fromRoutes([
          RouteDefinition(
            path: '/path/',
            component: ng.createTestComponentFactory(),
          ),
        ]);
        expect(routePath.path, 'path');
      });
    });

    group('toUrl()', () {
      late RoutePath routePath;

      setUpAll(() {
        var parentParentPath = RoutePath(path: 'path1/:param1');
        var parentPath =
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

@Component(
  selector: 'test',
  template: '',
)
class TestComponent {}
