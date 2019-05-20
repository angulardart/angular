class AngularInfoGenerator {
  static final componentMatcher =
      RegExp(r'// View for component.*$', multiLine: true);

  Iterable<Future<String>> inputFileContents;
  AngularInfoGenerator(this.inputFileContents);

  Future<String> generateTextReport() async {
    // TODO: Implement the report.

    Iterable<int> numComponents = await Future.wait(inputFileContents.map(
        (futureInput) => futureInput.then(
            (String input) => componentMatcher.allMatches(input).length)));
    return "Found ${numComponents.fold(0, (a, b) => a + b)} components";
  }
}
