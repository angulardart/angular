import '../app_view_base.dart' show View;

/// View base for both _embedded_ (`<template>`) and _host_ views (standalone).
abstract class ContentView<T> extends View<T> {}
