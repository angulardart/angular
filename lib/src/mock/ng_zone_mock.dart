import "package:angular2/src/core/di.dart" show Injectable;
import "package:angular2/src/core/zone/ng_zone.dart" show NgZone;
import "package:angular2/src/facade/async.dart" show EventEmitter;

@Injectable()
class MockNgZone extends NgZone {
  EventEmitter<dynamic> _mockOnStable = new EventEmitter(false);
  MockNgZone() : super(enableLongStackTrace: false);
  EventEmitter get onStable => this._mockOnStable;

  dynamic/*=R*/ run/*<R>*/(/*=R*/ fn()) {
    return fn();
  }

  dynamic runOutsideAngular(Function fn) {
    return fn();
  }

  void simulateZoneExit() {
    onStable.add(null);
  }
}
