library angular.symbol_inspector.symbol_inspector;

import 'dart:collection';
import 'dart:mirrors';

import 'package:angular/angular.dart' as ng2;
import 'package:angular/compiler.dart' as ng2compiler;
import 'package:angular/core.dart' as ng2core;
import 'package:angular/di.dart' as di;
import 'package:angular/common.dart' as ng2platform_common;
import 'package:angular/platform/testing/browser.dart'
    as ng2platform_browser_testing;

// HACK: This list is here only to make the corresponding libraries used. The
// imports are only needed to reflect on them using mirrors.
final _ng2libSymbols = [
  ng2core.Component,
  ng2compiler.COMPILER_PROVIDERS,
  ng2.NgIf,
  ng2platform_browser_testing.TEST_BROWSER_PLATFORM_PROVIDERS,
  ng2platform_common.COMMON_DIRECTIVES,
  ng2.APP_ID,
  di.Inject
];

LibraryMirror getLibrary(String uriString) {
  // HACK: this is here only to make _ng2libSymbols used.
  _ng2libSymbols.forEach((_) {});

  var uri = Uri.parse('package:angular/$uriString');

  var lib = currentMirrorSystem().libraries[uri];
  if (lib == null) {
    throw 'Failed to load library $uri';
  }
  return lib;
}

Set<String> getSymbolsFromLibrary(LibraryMirror lib) {
  var names = new SplayTreeSet<String>();
  extractSymbols(lib).addTo(names);
  return names;
}

class ExportedSymbol {
  final Symbol symbol;
  final DeclarationMirror declaration;
  final LibraryMirror library;

  ExportedSymbol(this.symbol, this.declaration, this.library);

  void addTo(Set<String> names) {
    var name = unwrapSymbol(symbol);
    if (declaration is MethodMirror) {
      names.add(name);
    } else if (declaration is ClassMirror) {
      var classMirror = declaration as ClassMirror;
      if (classMirror.isAbstract) name = '$name';
      names.add(name);
    } else if (declaration is TypedefMirror) {
      names.add(name);
    } else if (declaration is VariableMirror) {
      names.add(name);
    } else {
      throw 'UNEXPECTED: $declaration';
    }
  }

  String toString() => unwrapSymbol(symbol);
}

class LibraryInfo {
  final List<ExportedSymbol> names;
  final Map<Symbol, List<Symbol>> symbolsUsedForName;

  LibraryInfo(this.names, this.symbolsUsedForName);

  void addTo(Set<String> names) {
    this.names.forEach((ExportedSymbol es) => es.addTo(names));
  }
}

Iterable<Symbol> _getUsedSymbols(
    DeclarationMirror decl, seenDecls, path, onlyType) {
  if (seenDecls.containsKey(decl.qualifiedName)) return [];
  seenDecls[decl.qualifiedName] = true;

  if (decl.isPrivate) return [];

  path = "$path -> $decl";

  var used = <Symbol>[];

  if (decl is TypedefMirror) {
    TypedefMirror tddecl = decl;
    used.addAll(_getUsedSymbols(tddecl.referent, seenDecls, path, onlyType));
  }
  if (decl is FunctionTypeMirror) {
    FunctionTypeMirror ftdecl = decl;

    ftdecl.parameters.forEach((ParameterMirror p) {
      used.addAll(_getUsedSymbols(p.type, seenDecls, path, onlyType));
    });
    used.addAll(_getUsedSymbols(ftdecl.returnType, seenDecls, path, onlyType));
  } else if (decl is TypeMirror) {
    var tdecl = decl;
    used.add(tdecl.qualifiedName);
  }

  if (!onlyType) {
    if (decl is ClassMirror) {
      ClassMirror cdecl = decl;
      cdecl.declarations.forEach((s, d) {
        try {
          used.addAll(_getUsedSymbols(d, seenDecls, path, false));
        } catch (e, s) {
          print("Got error [$e] when visiting $d\n$s");
        }
      });
    }
  }

  // Strip out type variables.
  if (decl is TypeMirror) {
    TypeMirror tdecl = decl;
    var typeVariables = tdecl.typeVariables.map((tv) => tv.qualifiedName);
    used = used.where((x) => !typeVariables.contains(x));
  }

  return used;
}

LibraryInfo extractSymbols(LibraryMirror lib, [String printPrefix = ""]) {
  List<ExportedSymbol> exportedSymbols = [];
  Map<Symbol, List<Symbol>> used = {};

  printPrefix += "  ";
  lib.declarations.forEach((Symbol symbol, DeclarationMirror decl) {
    if (decl.isPrivate) return;

    exportedSymbols.add(new ExportedSymbol(symbol, decl, lib));
    used[decl.qualifiedName] = _getUsedSymbols(decl, {}, "", false);
  });

  lib.libraryDependencies.forEach((LibraryDependencyMirror libDep) {
    LibraryMirror target = libDep.targetLibrary;
    if (!libDep.isExport) return;

    var childInfo = extractSymbols(target, printPrefix);
    var childNames = childInfo.names;

    // If there was a "show" or "hide" on the exported library, filter the results.
    // This API needs love :-(
    var showSymbols = [], hideSymbols = [];
    libDep.combinators.forEach((CombinatorMirror c) {
      if (c.isShow) {
        showSymbols.addAll(c.identifiers);
      }
      if (c.isHide) {
        hideSymbols.addAll(c.identifiers);
      }
    });

    // I don't think you can show and hide from the same library
    assert(showSymbols.isEmpty || hideSymbols.isEmpty);
    if (showSymbols.isNotEmpty) {
      childNames = childNames.where((symAndLib) {
        return showSymbols.contains(symAndLib.symbol);
      });
    }
    if (hideSymbols.isNotEmpty) {
      childNames = childNames.where((symAndLib) {
        return !hideSymbols.contains(symAndLib.symbol);
      });
    }

    exportedSymbols.addAll(childNames);
    used.addAll(childInfo.symbolsUsedForName);
  });
  return new LibraryInfo(exportedSymbols, used);
}

final _SYMBOL_NAME = new RegExp('"(.*)"');
String unwrapSymbol(sym) => _SYMBOL_NAME.firstMatch(sym.toString()).group(1);
