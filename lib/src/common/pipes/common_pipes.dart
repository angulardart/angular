/**
 * 
 * 
 * This module provides a set of common Pipes.
 */
library angular2.src.common.pipes.common_pipes;

import "async_pipe.dart" show AsyncPipe;
import "uppercase_pipe.dart" show UpperCasePipe;
import "lowercase_pipe.dart" show LowerCasePipe;
import "json_pipe.dart" show JsonPipe;
import "slice_pipe.dart" show SlicePipe;
import "date_pipe.dart" show DatePipe;
import "number_pipe.dart" show DecimalPipe, PercentPipe, CurrencyPipe;
import "replace_pipe.dart" show ReplacePipe;
import "i18n_plural_pipe.dart" show I18nPluralPipe;
import "i18n_select_pipe.dart" show I18nSelectPipe;

/**
 * A collection of Angular core pipes that are likely to be used in each and every
 * application.
 *
 * This collection can be used to quickly enumerate all the built-in pipes in the `pipes`
 * property of the `@Component` decorator.
 */
const COMMON_PIPES = const [
  AsyncPipe,
  UpperCasePipe,
  LowerCasePipe,
  JsonPipe,
  SlicePipe,
  DecimalPipe,
  PercentPipe,
  CurrencyPipe,
  DatePipe,
  ReplacePipe,
  I18nPluralPipe,
  I18nSelectPipe
];
