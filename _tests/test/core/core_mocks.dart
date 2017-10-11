library angular2.test.core.mocks;

import 'package:mockito/mockito.dart';
import 'package:angular/src/core/change_detection/change_detection.dart';
import 'package:angular/src/core/linker/element_ref.dart';

class MockChangeDetectorRef extends Mock implements ChangeDetectorRef {}

class MockElementRef extends Mock implements ElementRef {}
