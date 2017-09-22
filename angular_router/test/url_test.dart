// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
import 'package:test/test.dart';
import 'package:angular_router/src/url.dart';

void main() {
  group('$Url', () {
    group('parse', () {
      Url url;

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

    test('should be equivalent to another $Url', () {
      var url1 = new Url('/1', fragment: '2', queryParameters: {'3': 'true'});
      var url2 = new Url('/1', fragment: '2', queryParameters: {'3': 'true'});
      expect(url1, url2);
    });

    test('toUrl should return a Url string', () {
      var url1 = new Url('/1', fragment: '2', queryParameters: {'3': 'true'});
      expect(url1.toUrl(), '/1?3=true#2');
    });
  });
}
