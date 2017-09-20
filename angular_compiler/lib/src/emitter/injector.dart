import 'package:meta/meta.dart';

import '../analyzer/di/dependencies.dart';
import '../analyzer/di/providers.dart';
import '../analyzer/di/tokens.dart';

/// Generates `.dart` source code given a list of providers to bind.
class InjectorEmitter {
  static const _package = 'package:angular';
  static const _prefix = '_injector';

  /// What file to import in order to access symbols for `Injector`.
  @protected
  final String importSource;

  /// What providers to generate named injectors for.
  final Map<String, List<ProviderElement>> _providers;

  const InjectorEmitter(
    this._providers, {
    this.importSource: '$_package/src/di/injector.dart',
  });

  /// Writes `import` statements needed for [emitInjectors].
  ///
  /// Prefixed in such a way that will not conflict with others.
  String emitImports() {
    if (_providers.isEmpty) {
      return '';
    }
    return "import '$importSource' as $_prefix;";
  }

  String emitInjector() {
    const $GeneratedInjector = '$_prefix.GeneratedInjector';
    const $Injector = '$_prefix.Injector';
    const $OrElseInject = '$_prefix.OrElseInject';
    const $throwsNotFound = '$_prefix.throwsNotFound';
    return _providers.keys.map((name) {
      final methods = new StringBuffer();
      final output = new StringBuffer()
        ..writeln('class $name\$Generated extends ${$GeneratedInjector} {')
        ..writeln('  $name\$Generated([${$Injector} parent]) : super(parent);')
        ..writeln('  @override')
        ..writeln('  T injectFromSelf<T>(')
        ..writeln('    Object token, {')
        ..writeln('    ${$OrElseInject}<T> orElse: ${$throwsNotFound},')
        ..writeln('  }) {')
        ..writeln('    switch (token) {');
      var index = 0;
      for (final provider in _providers[name]) {
        _emitProvider(output, provider, index++, methods);
      }
      output
        ..writeln('      default:')
        ..writeln('        return orElse(this, token);')
        ..writeln('    }')
        ..writeln('  }')
        ..writeln('$methods')
        ..writeln('}');
      return output.toString();
    }).join('\n');
  }

  void _emitProvider(
    StringSink caseStatements,
    ProviderElement element,
    int index,
    StringSink classMethods,
  ) {
    caseStatements
      ..writeln('      case ${_tokenToString(element.token)}:')
      ..writeln('        return _provide$index();');
    classMethods
      ..writeln('  ${_returnTypeOf(element.token)} _field$index;')
      ..writeln('  ${_returnTypeOf(element.token)} _provide$index() {')
      ..writeln('    return _field$index ??= ${_createA(element)};')
      ..writeln('  }');
  }

  static String _tokenToString(TokenElement token) {
    const $OpaqueToken = '$_prefix.OpaqueToken';
    if (token is OpaqueTokenElement) {
      return "const ${$OpaqueToken}('${token.identifier}')";
    }
    if (token is TypeTokenElement) {
      if (token.prefix != null) {
        return '${token.prefix}.${token.url.fragment}';
      }
      return token.url.fragment;
    }
    if (token is LiteralTokenElement) {
      return '${token.literal}';
    }
    throw new ArgumentError('Unsupported type: ${token.runtimeType}.');
  }

  static String _returnTypeOf(TokenElement token) {
    if (token is TypeTokenElement) {
      return _tokenToString(token);
    }
    return 'dynamic';
  }

  static String _createA(ProviderElement element) {
    if (element is UseValueProviderElement) {
      return '${element.useValue}';
    }
    String function;
    final arguments = <String>[];
    void computeArguments(List<DependencyElement> positional) {
      // TODO(matanl): Support annotations (@self, @skipSelf, @optional, etc.).
      for (final dependency in positional) {
        arguments.add('inject(${_tokenToString(dependency.token)})');
      }
    }

    if (element is UseFactoryProviderElement) {
      function = element.useFactory.fragment;
      computeArguments(element.dependencies.positional);
    } else if (element is UseClassProviderElement) {
      function = 'new ${element.useClass.fragment}';
      if (!element.dependencies.bound.isDefaultConstructor) {
        function += '.${element.dependencies.bound.name}';
      }
      computeArguments(element.dependencies.positional);
    }
    if (function == null) {
      throw new ArgumentError('Unsupported type: ${element.runtimeType}.');
    }
    return '$function(${arguments.join(', ')})';
  }
}
