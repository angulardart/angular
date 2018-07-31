import 'async_pipe.dart' show AsyncPipe;
import 'date_pipe.dart' show DatePipe;
import 'json_pipe.dart' show JsonPipe;
import 'lowercase_pipe.dart' show LowerCasePipe;
import 'number_pipe.dart' show DecimalPipe, PercentPipe, CurrencyPipe;
import 'replace_pipe.dart' show ReplacePipe;
import 'slice_pipe.dart' show SlicePipe;
import 'uppercase_pipe.dart' show UpperCasePipe;

/// A collection of built-in AngularDart core pipes.
///
/// This collection can be used to quickly enumerate all the built-in pipes in
/// the `pipes` property of the `@Component` annotation. For most applications
/// it's recommended to only reference the _exact_ pipes you use, however.
const commonPipes = [
  AsyncPipe,
  UpperCasePipe,
  LowerCasePipe,
  JsonPipe,
  SlicePipe,
  DecimalPipe,
  PercentPipe,
  CurrencyPipe,
  DatePipe,
  ReplacePipe
];
