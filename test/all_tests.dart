import 'common/directives/ng_class_test.dart' as test_1;
import 'common/directives/ng_for_test.dart' as test_2;
import 'common/directives/ng_if_test.dart' as test_3;
import 'common/directives/ng_plural_test.dart' as test_4;
import 'common/directives/ng_switch_test.dart' as test_5;
import 'common/directives/ng_template_outlet_test.dart' as test_6;
import 'common/directives/non_bindable_test.dart' as test_7;
import 'common/forms/integration_test.dart' as test_8;
import 'common/pipes/json_pipe_test.dart' as test_9;
import 'common/pipes/slice_pipe_test.dart' as test_10;
import 'compiler/directive_normalizer_test.dart' as test_11;
import 'compiler/offline_compiler_test.dart' as test_12;
import 'compiler/runtime_metadata_test.dart' as test_13;
import 'compiler/template_parser_test.dart' as test_14;
import 'compiler/output/output_emitter_test.dart' as test_15;
import 'core/application_ref_test.dart' as test_16;
import 'core/change_detection/differs/default_iterable_differ_test.dart'
    as test_17;
import 'core/change_detection/differs/iterable_differs_test.dart' as test_18;
import 'core/debug/debug_node_test.dart' as test_19;
import 'core/linker/change_detection_integration_test.dart' as test_20;
import 'core/linker/dynamic_component_loader_test.dart' as test_21;
import 'core/linker/integration_dart_test.dart' as test_22;
import 'core/linker/integration_test.dart' as test_23;
import 'core/linker/projection_integration_test.dart' as test_24;
import 'core/linker/query_integration_test.dart' as test_25;
import 'core/linker/security_integration_test.dart' as test_26;
import 'core/linker/view_injector_integration_test.dart' as test_27;
import 'symbol_inspector/symbol_inspector_test.dart' as test_28;

// Run tests that currently don't run well within Bazel for internal use.
void main() {
  var assertionsEnabled = false;
  assert(() => assertionsEnabled = true);
  if (!assertionsEnabled) {
    throw 'Assertions must be enabled for tests to work.';
  }
  /*
  test_1.main();
  test_2.main();
  test_3.main();
  test_4.main();
  test_5.main();
  test_6.main();
  test_7.main();
  test_8.main();
  test_9.main();
  test_10.main();
  test_11.main();
  test_12.main();
  test_13.main();
  test_14.main();
  test_15.main();
  test_16.main();
  test_17.main();
  test_18.main();
  test_19.main();
  test_20.main();
  test_21.main();
  */
  test_22.main();
  test_23.main();
  /*
  test_24.main();
  test_25.main();
  test_26.main();
  test_27.main();
  test_28.main();
  */
}
