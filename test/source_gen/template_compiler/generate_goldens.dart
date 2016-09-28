import 'package:build/build.dart';

import 'component_extractor_generator.dart';

main() async {
  var phase = new PhaseGroup.singleAction(
      testComponentExtractor(extension: '.golden'),
      new InputSet('angular2', ['$testFiles/*.dart', '$testFiles/**/*.dart']));

  await build(phase);
}
