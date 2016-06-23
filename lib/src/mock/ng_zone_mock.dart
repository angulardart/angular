library angular2.src.mock.ng_zone_mock;

import "package:angular2/src/core/di.dart" show Injectable;
import "package:angular2/src/core/zone/ng_zone.dart" show NgZone;
import "package:angular2/src/facade/async.dart"
    show EventEmitter, ObservableWrapper;

/**
 * A mock implementation of [NgZone].
 */
@Injectable()
class MockNgZone extends NgZone {
  /** @internal */
  EventEmitter<dynamic> _mockOnStable = new EventEmitter(false);
  MockNgZone() : super(enableLongStackTrace: false) {
    /* super call moved to initializer */;
  }
  get onStable {
    return this._mockOnStable;
  }

  dynamic run(Function fn) {
    return fn();
  }

  dynamic runOutsideAngular(Function fn) {
    return fn();
  }

  void simulateZoneExit() {
    ObservableWrapper.callNext(this.onStable, null);
  }
}
