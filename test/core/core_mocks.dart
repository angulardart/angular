library angular2.test.core.mocks;

import 'package:angular2/core.dart';
import 'package:angular2/src/core/change_detection/change_detection.dart';
import 'package:mockito/mockito.dart';

class MockChangeDetectorRef extends Mock implements ChangeDetectorRef {}

class MockElementRef extends Mock implements ElementRef {}
