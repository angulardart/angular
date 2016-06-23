library angular2.src.core.profile.profile;

export "wtf_impl.dart" show WtfScopeFn;
import "wtf_impl.dart" as impl;
// Change exports to const once https://github.com/angular/ts2dart/issues/150

/**
 * True if WTF is enabled.
 */
var wtfEnabled = impl.detectWTF();
dynamic noopScope([dynamic arg0, dynamic arg1]) {
  return null;
}

/**
 * Create trace scope.
 *
 * Scopes must be strictly nested and are analogous to stack frames, but
 * do not have to follow the stack frames. Instead it is recommended that they follow logical
 * nesting. You may want to use
 * [Event
 * Signatures](http://google.github.io/tracing-framework/instrumenting-code.html#custom-events)
 * as they are defined in WTF.
 *
 * Used to mark scope entry. The return value is used to leave the scope.
 *
 *     var myScope = wtfCreateScope('MyClass#myMethod(ascii someVal)');
 *
 *     someMethod() {
 *        var s = myScope('Foo'); // 'Foo' gets stored in tracing UI
 *        // DO SOME WORK HERE
 *        return wtfLeave(s, 123); // Return value 123
 *     }
 *
 * Note, adding try-finally block around the work to ensure that `wtfLeave` gets called can
 * negatively impact the performance of your application. For this reason we recommend that
 * you don't add them to ensure that `wtfLeave` gets called. In production `wtfLeave` is a noop and
 * so try-finally block has no value. When debugging perf issues, skipping `wtfLeave`, do to
 * exception, will produce incorrect trace, but presence of exception signifies logic error which
 * needs to be fixed before the app should be profiled. Add try-finally only when you expect that
 * an exception is expected during normal execution while profiling.
 *
 */
dynamic /* (signature: string, flags?: any) => impl.WtfScopeFn */ wtfCreateScope =
    wtfEnabled
        ? impl.createScope
        : (String signature, [dynamic flags]) => noopScope;
/**
 * Used to mark end of Scope.
 *
 * - `scope` to end.
 * - `returnValue` (optional) to be passed to the WTF.
 *
 * Returns the `returnValue for easy chaining.
 */
dynamic /* <T>(scope: any, returnValue?: T) => T */ wtfLeave =
    wtfEnabled ? impl.leave : (dynamic s, [dynamic r]) => r;
/**
 * Used to mark Async start. Async are similar to scope but they don't have to be strictly nested.
 * The return value is used in the call to [endAsync]. Async ranges only work if WTF has been
 * enabled.
 *
 *     someMethod() {
 *        var s = wtfStartTimeRange('HTTP:GET', 'some.url');
 *        var future = new Future.delay(5).then((_) {
 *          wtfEndTimeRange(s);
 *        });
 *     }
 */
dynamic /* (rangeType: string, action: string) => any */ wtfStartTimeRange =
    wtfEnabled
        ? impl.startTimeRange
        : (String rangeType, String action) => null;
/**
 * Ends a async time range operation.
 * [range] is the return value from [wtfStartTimeRange] Async ranges only work if WTF has been
 * enabled.
 */
dynamic /* (range: any) => void */ wtfEndTimeRange =
    wtfEnabled ? impl.endTimeRange : (dynamic r) => null;
