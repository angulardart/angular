import 'package:test/test.dart';

throwsWith(String s) => throwsA(predicate((e) => e.toString().contains(s)));

final Matcher throwsATypeError = throwsA(TypeMatcher<TypeError>());
