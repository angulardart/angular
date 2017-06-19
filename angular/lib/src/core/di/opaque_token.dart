/// Creates a token that can be used in a DI Provider.
///
/// ### Example ([live demo](http://plnkr.co/edit/Ys9ezXpj2Mnoy3Uc8KBp?p=preview))
///
/// var t = new OpaqueToken("value");
///
/// var injector = Injector.resolveAndCreate([
///   provide(t, {useValue: "bindingValue"})
/// ]);
///
/// expect(injector.get(t)).toEqual("bindingValue");
///
/// Using an `OpaqueToken` is preferable to using strings as tokens because of
/// possible collisions caused by multiple providers using the same string as
/// two different tokens.
///
/// Using an `OpaqueToken` is preferable to using an `Object` as tokens because
/// it provides better error messages.
class OpaqueToken {
  final String _desc;

  const OpaqueToken(this._desc);

  @override
  bool operator ==(other) => other is OpaqueToken && _desc == other._desc;

  @override
  int get hashCode => _desc.hashCode;

  // Temporary: We are using this to canonical-ize OpaqueTokens in source_gen.
  toJson() => toString();

  String toString() {
    return "const OpaqueToken('$_desc')";
  }
}
