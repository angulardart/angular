// http://go/migrate-deps-first
// @dart=2.9
const ngSpace = '\uE500';

String replaceNgSpace(String value) {
  return value.replaceAll(ngSpace, ' ');
}
