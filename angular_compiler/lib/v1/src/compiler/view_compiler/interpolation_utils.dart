// http://go/migrate-deps-first
// @dart=2.9
import 'package:angular_compiler/v1/src/compiler/expression_parser/ast.dart'
    as ast;
import 'package:angular_compiler/v1/src/compiler/ir/model.dart' as ir;

bool isInterpolation(ir.BindingSource source) =>
    source is ir.BoundExpression && source.expression.ast is ast.Interpolation;
