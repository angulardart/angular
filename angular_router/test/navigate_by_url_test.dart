@TestOn('browser')
import 'dart:async';

import 'package:angular_router/angular_router.dart';
import 'package:angular_router/src/router/router_impl.dart';
import 'package:angular_router/testing.dart';
import 'package:angular_test/angular_test.dart';
import 'package:collection/collection.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

void main() {
  tearDown(disposeAnyRunningTest);

  group('navigateByUrl', () {
    Router mockRouter;
    Router router;

    setUp(() {
      mockRouter = MockRouter();
      router = DelegatingRouter(mockRouter);
    });

    test('invokes navigate', () {
      router.navigateByUrl('/to/path');
      expect(
        verify(mockRouter.navigate(
          captureAny,
          captureAny,
        )).captured,
        ['/to/path', navigationParams()],
      );
    });

    test('invokes navigate with query parameters', () {
      router.navigateByUrl('/to/path?q=hello%20world');
      expect(
        verify(mockRouter.navigate(
          captureAny,
          captureAny,
        )).captured,
        [
          '/to/path',
          navigationParams(queryParameters: {'q': 'hello world'}),
        ],
      );
    });

    test('invokes navigate with fragment identifier', () {
      router.navigateByUrl('/to/path#with-fragment');
      expect(
        verify(mockRouter.navigate(
          captureAny,
          captureAny,
        )).captured,
        [
          '/to/path',
          navigationParams(fragment: 'with-fragment'),
        ],
      );
    });

    test('invokes navigate with reload', () {
      router.navigateByUrl('/to/path', reload: true);
      expect(
        verify(mockRouter.navigate(
          captureAny,
          captureAny,
        )).captured,
        [
          '/to/path',
          navigationParams(reload: true),
        ],
      );
    });

    test('invokes navigate with replace', () {
      router.navigateByUrl('/to/path', replace: true);
      expect(
        verify(mockRouter.navigate(
          captureAny,
          captureAny,
        )).captured,
        [
          '/to/path',
          navigationParams(replace: true),
        ],
      );
    });
  });
}

class MockRouter extends Mock implements Router {}

class DelegatingRouter extends RouterImpl {
  final Router _delegate;

  DelegatingRouter(this._delegate)
      : super(Location(MockLocationStrategy()), null);

  @override
  Future<NavigationResult> navigate(
    String path, [
    NavigationParams navigationParams,
  ]) =>
      _delegate.navigate(path, navigationParams);
}

Matcher navigationParams({
  Map<String, String> queryParameters = const {},
  String fragment = '',
  bool reload = false,
  bool replace = false,
}) =>
    NavigationParamsMatcher(NavigationParams(
      queryParameters: queryParameters,
      fragment: fragment,
      reload: reload,
      replace: replace,
    ));

class NavigationParamsMatcher extends Matcher {
  final NavigationParams navigationParams;

  NavigationParamsMatcher(this.navigationParams);

  @override
  bool matches(item, Map matchState) {
    return item is NavigationParams &&
        const MapEquality()
            .equals(item.queryParameters, navigationParams.queryParameters) &&
        item.fragment == navigationParams.fragment &&
        item.reload == navigationParams.reload &&
        item.replace == navigationParams.replace &&
        item.updateUrl == navigationParams.updateUrl;
  }

  @override
  Description describe(Description description) {
    return _describeNavigationParams(
        description.add('NavigationParams with '), navigationParams);
  }

  @override
  Description describeMismatch(
      item, Description mismatchDescription, Map matchState, bool verbose) {
    if (item is NavigationParams) {
      return _describeNavigationParams(mismatchDescription.add('has '), item);
    }
    return super
        .describeMismatch(item, mismatchDescription, matchState, verbose);
  }

  Description _describeNavigationParams(
    Description description,
    NavigationParams navigationParams,
  ) {
    return description
        .add('{ queryParameters: ')
        .addDescriptionOf(navigationParams.queryParameters)
        .add(', fragment: ')
        .addDescriptionOf(navigationParams.fragment)
        .add(', reload: ')
        .addDescriptionOf(navigationParams.reload)
        .add(', replace: ')
        .addDescriptionOf(navigationParams.replace)
        .add(', updateUrl: ')
        .addDescriptionOf(navigationParams.updateUrl)
        .add('}');
  }
}
