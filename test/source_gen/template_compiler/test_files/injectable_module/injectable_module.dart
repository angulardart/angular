import 'package:angular2/angular2.dart';

@InjectorModule(providers: const [])
class EmptyModule {}

@InjectorModule(providers: const [EmptyModule])
class TestModule {}
