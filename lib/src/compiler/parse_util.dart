import "package:angular2/src/facade/lang.dart" show isPresent;

class ParseLocation {
  ParseSourceFile file;
  num offset;
  num line;
  num col;
  ParseLocation(this.file, this.offset, this.line, this.col) {}
  String toString() {
    return isPresent(this.offset)
        ? '''${ this . file . url}@${ this . line}:${ this . col}'''
        : this.file.url;
  }
}

class ParseSourceFile {
  String content;
  String url;
  ParseSourceFile(this.content, this.url) {}
}

class ParseSourceSpan {
  ParseLocation start;
  ParseLocation end;
  ParseSourceSpan(this.start, this.end) {}
  String toString() {
    return this
        .start
        .file
        .content
        .substring(this.start.offset, this.end.offset);
  }
}

enum ParseErrorLevel { WARNING, FATAL }

abstract class ParseError {
  ParseSourceSpan span;
  String msg;
  ParseErrorLevel level;
  ParseError(this.span, this.msg, [this.level = ParseErrorLevel.FATAL]) {}
  String toString() {
    var source = this.span.start.file.content;
    var ctxStart = this.span.start.offset;
    var contextStr = "";
    if (isPresent(ctxStart)) {
      if (ctxStart > source.length - 1) {
        ctxStart = source.length - 1;
      }
      var ctxEnd = ctxStart;
      var ctxLen = 0;
      var ctxLines = 0;
      while (ctxLen < 100 && ctxStart > 0) {
        ctxStart--;
        ctxLen++;
        if (source[ctxStart] == "\n") {
          if (++ctxLines == 3) {
            break;
          }
        }
      }
      ctxLen = 0;
      ctxLines = 0;
      while (ctxLen < 100 && ctxEnd < source.length - 1) {
        ctxEnd++;
        ctxLen++;
        if (source[ctxEnd] == "\n") {
          if (++ctxLines == 3) {
            break;
          }
        }
      }
      var context = source.substring(ctxStart, this.span.start.offset) +
          "[ERROR ->]" +
          source.substring(this.span.start.offset, ctxEnd + 1);
      contextStr = ''' ("${ context}")''';
    }
    return '''${ this . msg}${ contextStr}: ${ this . span . start}''';
  }
}
