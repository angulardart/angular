import 'package:angular2/src/core/change_detection/differs/map_differ.dart';
import 'package:test/test.dart';

void main() {
  group('MapDiffer', () {
    test('should not report changes if there are none', () {
      var differ = new MapDiffer<String, int>();
      var map = {'a': 1, 'b': 2};
      expect(differ.diff(map), isTrue);
      expect(differ.diff(map), isFalse);
      expect(differenceAsString(differ), '');
    });

    test('should detect additions', () {
      var differ = new MapDiffer<String, int>();
      var map = {'a': 1};
      expect(differ.diff(map), isTrue);
      expect(differenceAsString(differ), 'changes: a[1]');
      map['b'] = 2;
      expect(differ.diff(map), isTrue);
      expect(differenceAsString(differ), 'changes: b[2]');
    });

    test('should detect changes', () {
      var differ = new MapDiffer<int, int>();
      var map = {1: 10, 2: 20};
      differ.diff(map);
      expect(differenceAsString(differ), 'changes: 1[10], 2[20]');
      map[2] = 10;
      map[1] = 20;
      expect(differ.diff(map), isTrue);
      expect(differenceAsString(differ), 'changes: 2[10], 1[20]');
    });

    test('should do basic map watching', () {
      var differ = new MapDiffer<String, String>();
      var map = {'a': 'A'};
      expect(differ.diff(map), isTrue);
      expect(differenceAsString(differ), 'changes: a[A]');

      map['b'] = 'B';
      expect(differ.diff(map), isTrue);
      expect(differenceAsString(differ), 'changes: b[B]');

      map['b'] = 'BB';
      map['d'] = 'D';
      expect(differ.diff(map), isTrue);
      expect(differenceAsString(differ), 'changes: d[D], b[BB]');

      map.remove('b');
      expect(differ.diff(map), isTrue);
      expect(differenceAsString(differ), 'removals: b');

      map.clear();
      expect(differ.diff(map), isTrue);
      expect(differenceAsString(differ), 'removals: a, d');
    });

    test('should compare string by value rather than by reference', () {
      var differ = new MapDiffer<String, String>();
      var map = {'foo': 'bar'};
      expect(differ.diff(map), isTrue);
      var f = 'f';
      var oo = 'oo';
      var b = 'b';
      var ar = 'ar';
      map[f + oo] = b + ar;
      expect(differ.diff(map), isFalse);
    });

    test('should not see a subsequent NaN values as a change', () {
      var differ = new MapDiffer<String, double>();
      var map = {'foo': double.NAN};
      expect(differ.diff(map), isTrue);
      expect(differ.diff(map), isFalse);
    }, tags: ['known_ff_failure']);

    test('should detect removals when first item is moved', () {
      var differ = new MapDiffer<String, int>();
      expect(differ.diff({'a': 1, 'b': 2}), isTrue);
      expect(differ.diff({'c': 3, 'a': 1}), isTrue);
      expect(differenceAsString(differ), 'changes: c[3]\nremovals: b');
    });
  });
}

String differenceAsString<K, V>(MapDiffer<K, V> differ) {
  var changes = <String>[];
  var removals = <String>[];
  var sb = new StringBuffer();

  differ.forEachChange((key, value) {
    changes.add('$key[$value]');
  });

  differ.forEachRemoval((key) {
    removals.add('$key');
  });

  if (changes.isNotEmpty) {
    sb.write('changes: ');
    sb.write(changes.join(', '));
  }

  if (removals.isNotEmpty) {
    if (sb.isNotEmpty) sb.writeln();
    sb.write('removals: ');
    sb.write(removals.join(', '));
  }

  return sb.toString();
}
