void main() {
  ClassWithNullableFields()
    ..initLateFields()
    ..accessLateFields();
  ClassWithLateFields()
    ..initLateFields()
    ..accessLateFields();
  ClassWithLateFinalFields()
    ..initLateFields()
    ..accessLateFields();

  ClassWithNullableInitializer().accessLateField();
  ClassWithLateFinalInitializer().accessLateField();

  var queue = <Foo>[];
  funcWithNullableLocal(queue);
  funcWithLateFinalLocal(queue);
  for (final e in queue) {
    e.run();
  }
}

class ClassWithNullableFields {
  String? x;
  String? y;
  String? z;

  @pragma('dart2js:noInline')
  void initLateFields() {
    x = 'x';
    y = 'y';
    z = 'z';
  }

  @pragma('dart2js:noInline')
  void accessLateFields() {
    print(x!.toUpperCase());
    print(y!.toUpperCase());
    print(z!.toUpperCase());
  }
}

class ClassWithLateFields {
  late String x;
  late String y;
  late String z;

  @pragma('dart2js:noInline')
  void initLateFields() {
    x = 'x';
    y = 'y';
    z = 'z';
  }

  @pragma('dart2js:noInline')
  void accessLateFields() {
    print(x.toUpperCase());
    print(y.toUpperCase());
    print(z.toUpperCase());
  }
}

class ClassWithLateFinalFields {
  late final String x;
  late final String y;
  late final String z;

  @pragma('dart2js:noInline')
  void initLateFields() {
    x = 'x';
    y = 'y';
    z = 'z';
  }

  @pragma('dart2js:noInline')
  void accessLateFields() {
    print(x.toUpperCase());
    print(y.toUpperCase());
    print(z.toUpperCase());
  }
}

class ClassWithNullableInitializer {
  int? someValue;

  ClassWithNullableInitializer() {
    someValue = _computeSomeValue();
  }

  @pragma('dart2js:noInline')
  int _computeSomeValue() => 5;

  @pragma('dart2js:noInline')
  void accessLateField() {
    print(someValue!.round());
  }
}

class ClassWithLateFinalInitializer {
  late final someValue = _computeSomeValue();

  @pragma('dart2js:noInline')
  int _computeSomeValue() => 5;

  @pragma('dart2js:noInline')
  void accessLateField() {
    print(someValue.round());
  }
}

class Foo {
  final void Function() run;

  Foo(this.run);
}

void funcWithNullableLocal(List<Foo> queue) {
  Foo? foo;

  void onCallback() {
    queue.remove(foo);
  }

  foo = Foo(onCallback);
  queue.add(foo);
}

void funcWithLateFinalLocal(List<Foo> queue) {
  late final Foo foo;

  void onCallback() {
    queue.remove(foo);
  }

  foo = Foo(onCallback);
  queue.add(foo);
}
