import 'package:angular2/angular2.dart';
import 'package:mockito/mockito.dart';

@proxy
class MockNgControl extends Mock implements NgControl {}

@proxy
class MockValueAccessor extends Mock implements ControlValueAccessor {}

@proxy
class MockChangeDetectorRef extends Mock implements ChangeDetectorRef {}
