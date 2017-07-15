import 'package:mockito/mockito.dart';
import 'package:angular/angular.dart';

@proxy
class MockNgControl extends Mock implements NgControl {}

@proxy
class MockValueAccessor extends Mock implements ControlValueAccessor {}

@proxy
class MockChangeDetectorRef extends Mock implements ChangeDetectorRef {}
