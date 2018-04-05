const ngSpace = '\uE500';

String replaceNgSpace(String value) {
  return value.replaceAll(ngSpace, ' ');
}
