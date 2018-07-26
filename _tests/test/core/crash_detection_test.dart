@TestOn('browser')
import 'dart:async';

import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';
import 'package:angular/angular.dart';

import 'crash_detection_test.template.dart' as ng_generated;

void main() {
  ng_generated.initReflector();

  tearDown(disposeAnyRunningTest);

  test('Should normally run change detection', () async {
    final valueService = ValueService()..value = 'Hello';
    final testBed = NgTestBed<NoCrash>().addProviders([
      provide(ValueService, useValue: valueService),
    ]);
    final fixture = await testBed.create();
    expect(
      fixture.text,
      contains('Hello'),
    );
    await fixture.update((_) => valueService.value = 'Goodbye');
    expect(
      fixture.text,
      contains('Goodbye'),
    );
  });

  test('Should disable change detection on components that throw', () async {
    final valueService = ValueService()..value = '1';
    final testBed = NgTestBed<Crash>().addProviders([
      provide(ValueService, useValue: valueService),
    ]);

    // Initially create with the crashing component disabled.
    final fixture = await testBed.create();
    expect(
      fixture.text,
      contains('Value: 1'),
    );

    // Enable the crashing component. We have to be very careful here to catch
    // the exception (so package:test doesn't report a failure) but also that
    // Angular continues to run.
    try {
      await fixture.update((crash) => crash.startCrashing = true);
    } catch (e) {
      expect(e, isNoSuchMethodError);
    }

    // Make sure the rest of the CD still works.
    await fixture.update((_) => valueService.value = '2');
    expect(
      fixture.text,
      contains('Value: 2'),
    );
  });

  test('Should disable change detection to avoid infinite ngOnInit', () async {
    final valueService = ValueService()..value = '1';
    final rpcService = RpcService();
    final testBed = NgTestBed<CrashOnInit>().addProviders([
      provide(ValueService, useValue: valueService),
      provide(RpcService, useValue: rpcService),
    ]);

    // Initially create with the crashing component disabled.
    final fixture = await testBed.create();
    expect(
      fixture.text,
      contains('Value: 1'),
    );

    // Initially create with the crashing and ngOnInit component disabled.
    try {
      await fixture.update((crash) => crash.startCrashing = true);
    } catch (e) {
      expect(e, isNoSuchMethodError);
    }

    // Verify a single RPC was made.
    expect(rpcService.calls, hasLength(1));

    // Make sure the rest of the CD still works.
    await fixture.update((_) => valueService.value = '2');
    expect(
      fixture.text,
      contains('Value: 2'),
    );

    // Verify no more RPCs were made.
    expect(rpcService.calls, hasLength(1));
  });
}

/// A top-level service that provides a global value to components.
///
/// Used in this test suite to determine when change detection is shut off.
@Injectable()
class ValueService {
  String value = '';
}

/// A top-level component that does not contain any crashing components.
@Component(
  selector: 'no-crash',
  template: '<child></child>',
  directives: [ChildComponent],
)
class NoCrash {}

/// A child component that renders [ValueService.value].
@Component(
  selector: 'child',
  template: 'Value: {{service.value}}',
)
class ChildComponent {
  final ValueService service;

  ChildComponent(this.service);
}

@Component(
  selector: 'crash',
  template: r'''
    <child></child>
    <error *ngIf="startCrashing"></error>
  ''',
  directives: [
    ChildComponent,
    ErrorComponent,
    NgIf,
  ],
)
class Crash {
  bool startCrashing = false;
}

@Component(
  selector: 'error',
  template: 'Error({{first}})',
)
class ErrorComponent {
  List<int> listThatWillNPE;

  int get first => listThatWillNPE.first;
}

@Injectable()
class RpcService {
  final calls = <String>[];

  void callRpc(String data) {
    scheduleMicrotask(() {
      calls.add(data);
    });
  }
}

@Component(
  selector: 'crash-on-init',
  directives: [
    ChildComponent,
    ErrorComponent,
    NgIf,
    OnInitComponent,
  ],
  template: r'''
    <child></child>
    <oninit *ngIf="startCrashing"></oninit>
    <error *ngIf="startCrashing"></error>
  ''',
)
class CrashOnInit {
  bool startCrashing = false;
}

@Component(
  selector: 'oninit',
  template: '',
)
class OnInitComponent implements OnInit {
  final RpcService _rpc;

  int _counter = 0;

  OnInitComponent(this._rpc);

  @override
  void ngOnInit() {
    _rpc.callRpc('Call #${++_counter}');
  }
}
