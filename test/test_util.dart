import 'package:test/test.dart';

Matcher throwsWith(Pattern message) => new _ThrowsWith(message);

class _ThrowsWith extends Matcher {
  // RegExp or String.
  final Pattern expected;

  _ThrowsWith(this.expected) {
    assert(expected is RegExp || expected is String);
  }

  bool matches(item, Map matchState) {
    if (item is! Function) return false;

    try {
      item();
      return false;
    } catch (e, s) {
      var errorString = e.toString();

      if (errorString.indexOf(expected) >= 0) {
        return true;
      } else {
        addStateInfo(matchState, {'exception': errorString, 'stack': s});
        return false;
      }
    }
  }

  Description describe(Description description) {
    if (expected is String) {
      return description
          .add('throws an error with a toString() containing ')
          .addDescriptionOf(expected);
    }

    assert(expected is RegExp);
    return description
        .add('throws an error with a toString() matched with ')
        .addDescriptionOf(expected);
  }

  Description describeMismatch(
      item, Description mismatchDescription, Map matchState, bool verbose) {
    if (item is! Function) {
      return mismatchDescription.add('is not a Function or Future');
    } else if (matchState['exception'] == null) {
      return mismatchDescription.add('did not throw');
    } else {
      if (expected is String) {
        mismatchDescription
            .add('threw an error with a toString() containing ')
            .addDescriptionOf(matchState['exception']);
      } else {
        assert(expected is RegExp);
        mismatchDescription
            .add('threw an error with a toString() matched with ')
            .addDescriptionOf(matchState['exception']);
      }
      if (verbose) {
        mismatchDescription.add(' at ').add(matchState['stack'].toString());
      }
      return mismatchDescription;
    }
  }
}
