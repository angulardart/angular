import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart' show LibraryElement;
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/generated/resolver.dart' show TypeProvider;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/type_system.dart';
import 'package:analyzer_plugin/utilities/completion/inherited_reference_contributor.dart';
import 'package:analyzer_plugin/utilities/completion/type_member_contributor.dart';

/// An angular [ResolvedUnitResult], required by dart completion contributors.
///
/// [TypeMemberContributor] and [InheritedReferenceContributor] require a
/// [ResolvedUnitResult], which the angular driver does not create for template
/// files. This allows us to communicate with those contributors for templates.
class DartResolveResultShell implements ResolvedUnitResult {
  @override
  LibraryElement libraryElement;

  @override
  TypeProvider typeProvider;

  @override
  TypeSystem typeSystem;

  @override
  final String path;

  DartResolveResultShell(this.path,
      {this.libraryElement, this.typeProvider, this.typeSystem});

  @override
  String get content => null;

  @override
  List<AnalysisError> get errors => const [];

  @override
  bool get isPart => false;

  @override
  LineInfo get lineInfo => null;

  @override
  AnalysisSession get session => null;

  @override
  ResultState get state => null;

  @override
  CompilationUnit get unit => null;

  @override
  Uri get uri => null;
}
