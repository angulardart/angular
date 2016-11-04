import 'package:angular2_template_parser/template_parser.dart';
import 'package:benchmark_harness/benchmark_harness.dart';

import 'shared/html.dart';

void main() {
  const PkgHtmlParserBenchmark().report();
}

/// Runs the `package:html_parser` benchmark.
class PkgHtmlParserBenchmark extends BenchmarkBase {
  /// Create the benchmark.
  const PkgHtmlParserBenchmark() : super('New Ng2');

  @override
  void run() {
    const NgTemplateParser().parse(html).toList();
  }
}
