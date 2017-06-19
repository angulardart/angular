library angular2.test.core.mocks;

import 'package:mockito/mockito.dart';
import 'package:angular/core.dart';
import 'package:angular/src/core/change_detection/change_detection.dart';

class MockChangeDetectorRef extends Mock implements ChangeDetectorRef {}

class MockElementRef extends Mock implements ElementRef {}
