library angular2.test.common.forms.control_mocks;

import 'package:angular2/src/common.dart';
import 'package:angular2/src/core/change_detection/change_detection.dart';
import 'package:mockito/mockito_package_test.dart';

@proxy
class MockNgControl extends Mock implements NgControl {}

@proxy
class MockValueAccessor extends Mock implements ControlValueAccessor {}

@proxy
class MockChangeDetectorRef extends Mock implements ChangeDetectorRef {}
