import "package:angular2/src/core/di.dart" show Injectable;
import "package:angular2/src/core/zone/ng_zone.dart" show NgZone;
import "package:angular2/src/facade/async.dart" show EventEmitter;

/// A mock implementation of [NgZone].
@Injectable()
class MockNgZone extends NgZone {
  final _mockOnStable = new EventEmitter(false);
  MockNgZone() : super(enableLongStackTrace: false);
  EventEmitter get onStable => this._mockOnStable;

  /*=R*/ run/*<R>*/(/*=R*/ fn()) {
    return fn();
  }

  dynamic runOutsideAngular(Function fn) {
    return fn();
  }

  void simulateZoneExit() {
    onStable.add(null);
  }
}
