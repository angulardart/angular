import 'package:angular/angular.dart';

/// Mimics the `Intl` class from `package:intl`.
class IntlLike {
  static String message(String name, {String desc}) => '';
}

class Messages {
  static final okMessage = IntlLike.message('ok', desc: 'OK');
  static final cancelMessage = IntlLike.message('cancel', desc: 'Cancel');
}

@Component(
  selector: 'comp-without-final',
  template: r'''
    <button>{{okMessage}}</button>
    <button>{{cancelMessage}}</button>
  ''',
)
class CompWithoutFinal {
  static String _okMessage() => IntlLike.message('ok', desc: 'OK');
  String get okMessage => _okMessage();

  static String _cancelMessage() => IntlLike.message('cancel', desc: 'Cancel');
  String get cancelMessage => _cancelMessage();
}

@Component(
  selector: 'comp-with-final',
  template: r'''
    <button>{{okMessage}}</button>
    <button>{{cancelMessage}}</button>
  ''',
)
class CompWithFinal {
  final okMessage = IntlLike.message('ok', desc: 'OK');
  final cancelMessage = IntlLike.message('cancel', desc: 'Cancel');
}

@Component(
  selector: 'comp-with-final-static',
  template: r'''
    <button>{{CompWithFinalStatic.okMessage}}</button>
    <button>{{CompWithFinalStatic.cancelMessage}}</button>
  ''',
)
class CompWithFinalStatic {
  static final okMessage = IntlLike.message('ok', desc: 'OK');
  static final cancelMessage = IntlLike.message('cancel', desc: 'Cancel');
}

@Component(
  selector: 'comp-with-external-final',
  template: r'''
    <button>{{Messages.okMessage}}</button>
    <button>{{Messages.cancelMessage}}</button>
''',
  exports: [Messages],
)
class CompWithExternalFinal {}
