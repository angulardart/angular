import 'package:test/test.dart';
import 'package:angular_router/src/url.dart';

void main() {
  group('$Url', () {
    group('parse', () {
      late Url url;

      setUpAll(() {
        url = Url.parse('/foo?bar=true&path/param/key=uri?param#baz');
      });

      test('should parse the path', () {
        expect(url.path, '/foo');
      });

      test('should parse the fragment', () {
        expect(url.fragment, 'baz');
      });

      test('should parse the queryParameters', () {
        expect(url.queryParameters,
            {'bar': 'true', 'path/param/key': 'uri?param'});
      });
    });

    test('toUrl should return a Url string', () {
      var url1 = Url('/1', fragment: '2', queryParameters: {'3': 'true'});
      expect(url1.toUrl(), '/1?3=true#2');
    });
  });
}
