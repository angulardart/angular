const String myConst = 'hello';

const List<int> myList = [1, 2, 3];

enum MyEnum { a, b, c }

String myFunc(String x) => '$x!!!';

void staticClickHandler() {
  clickHandled = true;
}

bool clickHandled = false;

class MyClass {
  static final String staticField = 'static field';
  static bool clickHandled = false;
  static String staticFunc(String x) => '$x???';
}
