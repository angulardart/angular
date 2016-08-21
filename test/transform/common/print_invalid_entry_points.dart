import 'package:angular2/src/transform/common/options_reader.dart';
import 'package:barback/barback.dart';

void main() {
  var settings = new BarbackSettings({
    'entry_points': [
      'non_existing',
      './test/transform/common/print_invalid_entry_points.dart'
    ]
  }, BarbackMode.DEBUG);
  parseBarbackSettings(settings);
}
