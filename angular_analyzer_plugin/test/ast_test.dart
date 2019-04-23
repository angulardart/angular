import 'package:angular_analyzer_plugin/ast.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(StatementsBoundAttrTest);
  });
}

@reflectiveTest
class StatementsBoundAttrTest {
  // ignore: non_constant_identifier_names
  void test_reductionOffsetMultipleReductions() {
    final attr = StatementsBoundAttribute(
        'name',
        '('.length, // nameOffset
        'value',
        '(name.reductions.here)="'.length, //valueOffset
        '(name)',
        0, // originalNameOffset
        ['reductions', 'here'], // reductions
        [] // statements
        );
    expect(attr.reductionsOffset, '(name'.length);
    expect(attr.reductionsLength, '.reductions.here'.length);
  }

  // ignore: non_constant_identifier_names
  void test_reductionOffsetNoReductions() {
    final attr = StatementsBoundAttribute(
        'name',
        '('.length, // nameOffset
        'value',
        '(name)="'.length, //valueOffset
        '(name)',
        0, // originalNameOffset
        [], // reductions
        [] // statements
        );
    expect(attr.reductionsOffset, null);
    expect(attr.reductionsLength, null);
  }

  // ignore: non_constant_identifier_names
  void test_reductionOffsetOneReduction() {
    final attr = StatementsBoundAttribute(
        'name',
        '('.length, // nameOffset
        'value',
        '(name.reduction)="'.length, //valueOffset
        '(name)',
        0, // originalNameOffset
        ['reduction'], // reductions
        [] // statements
        );
    expect(attr.reductionsOffset, '(name'.length);
    expect(attr.reductionsLength, '.reduction'.length);
  }
}
