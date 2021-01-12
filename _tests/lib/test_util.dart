import 'package:test/test.dart';

Matcher throwsWith(String s) =>
    throwsA(predicate((e) => e.toString().contains(s)));

final throwsATypeError = throwsA(TypeMatcher<TypeError>());
