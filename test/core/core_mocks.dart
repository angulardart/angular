library angular2.test.core.mocks;

import 'package:angular2/core.dart';
import 'package:angular2/src/core/change_detection/change_detection.dart';
import 'package:angular2/src/platform/dom/dom_adapter.dart';
import 'package:mockito/mockito.dart';

class MockChangeDetectorRef extends Mock implements ChangeDetectorRef {}

class MockIterableDifferFactory extends Mock implements IterableDifferFactory {}

class MockElementRef extends Mock implements ElementRef {}

class MockDomAdapter extends Mock implements DomAdapter {}
