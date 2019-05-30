// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This file has been automatically generated.  Please do not edit it manually.
// To regenerate the file, use the SDK script
// "pkg/analyzer/tool/summary/generate.dart $IDL_FILE_PATH",
// or "pkg/analyzer/tool/generate_files" for the analyzer package IDL/sources.

library analyzer.src.summary.format;

import 'dart:convert' as convert;

import 'package:analyzer/src/summary/api_signature.dart' as api_sig;
import 'package:analyzer/src/summary/flat_buffers.dart' as fb;

import 'idl.dart' as idl;

class LinkedDartSummaryBuilder extends Object
    with _LinkedDartSummaryMixin
    implements idl.LinkedDartSummary {
  List<SummarizedAnalysisErrorBuilder> _errors;
  bool _hasDartTemplates;
  List<String> _referencedDartFiles;
  List<String> _referencedHtmlFiles;

  @override
  List<SummarizedAnalysisErrorBuilder> get errors =>
      _errors ??= <SummarizedAnalysisErrorBuilder>[];

  set errors(List<SummarizedAnalysisErrorBuilder> value) {
    this._errors = value;
  }

  @override
  bool get hasDartTemplates => _hasDartTemplates ??= false;

  set hasDartTemplates(bool value) {
    this._hasDartTemplates = value;
  }

  @override
  List<String> get referencedDartFiles => _referencedDartFiles ??= <String>[];

  set referencedDartFiles(List<String> value) {
    this._referencedDartFiles = value;
  }

  @override
  List<String> get referencedHtmlFiles => _referencedHtmlFiles ??= <String>[];

  set referencedHtmlFiles(List<String> value) {
    this._referencedHtmlFiles = value;
  }

  LinkedDartSummaryBuilder(
      {List<SummarizedAnalysisErrorBuilder> errors,
      bool hasDartTemplates,
      List<String> referencedDartFiles,
      List<String> referencedHtmlFiles})
      : _errors = errors,
        _hasDartTemplates = hasDartTemplates,
        _referencedDartFiles = referencedDartFiles,
        _referencedHtmlFiles = referencedHtmlFiles;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _errors?.forEach((b) => b.flushInformative());
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    if (this._errors == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._errors.length);
      for (var x in this._errors) {
        x?.collectApiSignature(signature);
      }
    }
    if (this._referencedHtmlFiles == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._referencedHtmlFiles.length);
      for (var x in this._referencedHtmlFiles) {
        signature.addString(x);
      }
    }
    if (this._referencedDartFiles == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._referencedDartFiles.length);
      for (var x in this._referencedDartFiles) {
        signature.addString(x);
      }
    }
    signature.addBool(this._hasDartTemplates == true);
  }

  List<int> toBuffer() {
    fb.Builder fbBuilder = fb.Builder();
    return fbBuilder.finish(finish(fbBuilder), "APLD");
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_errors;
    fb.Offset offset_referencedDartFiles;
    fb.Offset offset_referencedHtmlFiles;
    if (!(_errors == null || _errors.isEmpty)) {
      offset_errors =
          fbBuilder.writeList(_errors.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_referencedDartFiles == null || _referencedDartFiles.isEmpty)) {
      offset_referencedDartFiles = fbBuilder.writeList(
          _referencedDartFiles.map((b) => fbBuilder.writeString(b)).toList());
    }
    if (!(_referencedHtmlFiles == null || _referencedHtmlFiles.isEmpty)) {
      offset_referencedHtmlFiles = fbBuilder.writeList(
          _referencedHtmlFiles.map((b) => fbBuilder.writeString(b)).toList());
    }
    fbBuilder.startTable();
    if (offset_errors != null) {
      fbBuilder.addOffset(0, offset_errors);
    }
    if (_hasDartTemplates == true) {
      fbBuilder.addBool(3, true);
    }
    if (offset_referencedDartFiles != null) {
      fbBuilder.addOffset(2, offset_referencedDartFiles);
    }
    if (offset_referencedHtmlFiles != null) {
      fbBuilder.addOffset(1, offset_referencedHtmlFiles);
    }
    return fbBuilder.endTable();
  }
}

idl.LinkedDartSummary readLinkedDartSummary(List<int> buffer) {
  fb.BufferContext rootRef = fb.BufferContext.fromBytes(buffer);
  return const _LinkedDartSummaryReader().read(rootRef, 0);
}

class _LinkedDartSummaryReader extends fb.TableReader<_LinkedDartSummaryImpl> {
  const _LinkedDartSummaryReader();

  @override
  _LinkedDartSummaryImpl createObject(fb.BufferContext bc, int offset) =>
      _LinkedDartSummaryImpl(bc, offset);
}

class _LinkedDartSummaryImpl extends Object
    with _LinkedDartSummaryMixin
    implements idl.LinkedDartSummary {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _LinkedDartSummaryImpl(this._bc, this._bcOffset);

  List<idl.SummarizedAnalysisError> _errors;
  bool _hasDartTemplates;
  List<String> _referencedDartFiles;
  List<String> _referencedHtmlFiles;

  @override
  List<idl.SummarizedAnalysisError> get errors {
    _errors ??= const fb.ListReader<idl.SummarizedAnalysisError>(
            _SummarizedAnalysisErrorReader())
        .vTableGet(_bc, _bcOffset, 0, const <idl.SummarizedAnalysisError>[]);
    return _errors;
  }

  @override
  bool get hasDartTemplates {
    _hasDartTemplates ??=
        const fb.BoolReader().vTableGet(_bc, _bcOffset, 3, false);
    return _hasDartTemplates;
  }

  @override
  List<String> get referencedDartFiles {
    _referencedDartFiles ??= const fb.ListReader<String>(fb.StringReader())
        .vTableGet(_bc, _bcOffset, 2, const <String>[]);
    return _referencedDartFiles;
  }

  @override
  List<String> get referencedHtmlFiles {
    _referencedHtmlFiles ??= const fb.ListReader<String>(fb.StringReader())
        .vTableGet(_bc, _bcOffset, 1, const <String>[]);
    return _referencedHtmlFiles;
  }
}

abstract class _LinkedDartSummaryMixin implements idl.LinkedDartSummary {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (errors.isNotEmpty) {
      _result["errors"] = errors.map((_value) => _value.toJson()).toList();
    }
    if (hasDartTemplates != false) {
      _result["hasDartTemplates"] = hasDartTemplates;
    }
    if (referencedDartFiles.isNotEmpty) {
      _result["referencedDartFiles"] = referencedDartFiles;
    }
    if (referencedHtmlFiles.isNotEmpty) {
      _result["referencedHtmlFiles"] = referencedHtmlFiles;
    }
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "errors": errors,
        "hasDartTemplates": hasDartTemplates,
        "referencedDartFiles": referencedDartFiles,
        "referencedHtmlFiles": referencedHtmlFiles,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class LinkedHtmlSummaryBuilder extends Object
    with _LinkedHtmlSummaryMixin
    implements idl.LinkedHtmlSummary {
  List<SummarizedAnalysisErrorBuilder> _errors;
  List<SummarizedAnalysisErrorFromPathBuilder> _errorsFromPath;

  @override
  List<SummarizedAnalysisErrorBuilder> get errors =>
      _errors ??= <SummarizedAnalysisErrorBuilder>[];

  set errors(List<SummarizedAnalysisErrorBuilder> value) {
    this._errors = value;
  }

  @override
  List<SummarizedAnalysisErrorFromPathBuilder> get errorsFromPath =>
      _errorsFromPath ??= <SummarizedAnalysisErrorFromPathBuilder>[];

  set errorsFromPath(List<SummarizedAnalysisErrorFromPathBuilder> value) {
    this._errorsFromPath = value;
  }

  LinkedHtmlSummaryBuilder(
      {List<SummarizedAnalysisErrorBuilder> errors,
      List<SummarizedAnalysisErrorFromPathBuilder> errorsFromPath})
      : _errors = errors,
        _errorsFromPath = errorsFromPath;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _errors?.forEach((b) => b.flushInformative());
    _errorsFromPath?.forEach((b) => b.flushInformative());
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    if (this._errors == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._errors.length);
      for (var x in this._errors) {
        x?.collectApiSignature(signature);
      }
    }
    if (this._errorsFromPath == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._errorsFromPath.length);
      for (var x in this._errorsFromPath) {
        x?.collectApiSignature(signature);
      }
    }
  }

  List<int> toBuffer() {
    fb.Builder fbBuilder = fb.Builder();
    return fbBuilder.finish(finish(fbBuilder), "APLH");
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_errors;
    fb.Offset offset_errorsFromPath;
    if (!(_errors == null || _errors.isEmpty)) {
      offset_errors =
          fbBuilder.writeList(_errors.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_errorsFromPath == null || _errorsFromPath.isEmpty)) {
      offset_errorsFromPath = fbBuilder
          .writeList(_errorsFromPath.map((b) => b.finish(fbBuilder)).toList());
    }
    fbBuilder.startTable();
    if (offset_errors != null) {
      fbBuilder.addOffset(0, offset_errors);
    }
    if (offset_errorsFromPath != null) {
      fbBuilder.addOffset(1, offset_errorsFromPath);
    }
    return fbBuilder.endTable();
  }
}

idl.LinkedHtmlSummary readLinkedHtmlSummary(List<int> buffer) {
  fb.BufferContext rootRef = fb.BufferContext.fromBytes(buffer);
  return const _LinkedHtmlSummaryReader().read(rootRef, 0);
}

class _LinkedHtmlSummaryReader extends fb.TableReader<_LinkedHtmlSummaryImpl> {
  const _LinkedHtmlSummaryReader();

  @override
  _LinkedHtmlSummaryImpl createObject(fb.BufferContext bc, int offset) =>
      _LinkedHtmlSummaryImpl(bc, offset);
}

class _LinkedHtmlSummaryImpl extends Object
    with _LinkedHtmlSummaryMixin
    implements idl.LinkedHtmlSummary {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _LinkedHtmlSummaryImpl(this._bc, this._bcOffset);

  List<idl.SummarizedAnalysisError> _errors;
  List<idl.SummarizedAnalysisErrorFromPath> _errorsFromPath;

  @override
  List<idl.SummarizedAnalysisError> get errors {
    _errors ??= const fb.ListReader<idl.SummarizedAnalysisError>(
            _SummarizedAnalysisErrorReader())
        .vTableGet(_bc, _bcOffset, 0, const <idl.SummarizedAnalysisError>[]);
    return _errors;
  }

  @override
  List<idl.SummarizedAnalysisErrorFromPath> get errorsFromPath {
    _errorsFromPath ??=
        const fb.ListReader<idl.SummarizedAnalysisErrorFromPath>(
                _SummarizedAnalysisErrorFromPathReader())
            .vTableGet(_bc, _bcOffset, 1,
                const <idl.SummarizedAnalysisErrorFromPath>[]);
    return _errorsFromPath;
  }
}

abstract class _LinkedHtmlSummaryMixin implements idl.LinkedHtmlSummary {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (errors.isNotEmpty) {
      _result["errors"] = errors.map((_value) => _value.toJson()).toList();
    }
    if (errorsFromPath.isNotEmpty) {
      _result["errorsFromPath"] =
          errorsFromPath.map((_value) => _value.toJson()).toList();
    }
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "errors": errors,
        "errorsFromPath": errorsFromPath,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class PackageBundleBuilder extends Object
    with _PackageBundleMixin
    implements idl.PackageBundle {
  List<UnlinkedDartSummaryBuilder> _unlinkedDartSummary;

  @override
  List<UnlinkedDartSummaryBuilder> get unlinkedDartSummary =>
      _unlinkedDartSummary ??= <UnlinkedDartSummaryBuilder>[];

  set unlinkedDartSummary(List<UnlinkedDartSummaryBuilder> value) {
    this._unlinkedDartSummary = value;
  }

  PackageBundleBuilder({List<UnlinkedDartSummaryBuilder> unlinkedDartSummary})
      : _unlinkedDartSummary = unlinkedDartSummary;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _unlinkedDartSummary?.forEach((b) => b.flushInformative());
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    if (this._unlinkedDartSummary == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._unlinkedDartSummary.length);
      for (var x in this._unlinkedDartSummary) {
        x?.collectApiSignature(signature);
      }
    }
  }

  List<int> toBuffer() {
    fb.Builder fbBuilder = fb.Builder();
    return fbBuilder.finish(finish(fbBuilder), "APdl");
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_unlinkedDartSummary;
    if (!(_unlinkedDartSummary == null || _unlinkedDartSummary.isEmpty)) {
      offset_unlinkedDartSummary = fbBuilder.writeList(
          _unlinkedDartSummary.map((b) => b.finish(fbBuilder)).toList());
    }
    fbBuilder.startTable();
    if (offset_unlinkedDartSummary != null) {
      fbBuilder.addOffset(0, offset_unlinkedDartSummary);
    }
    return fbBuilder.endTable();
  }
}

idl.PackageBundle readPackageBundle(List<int> buffer) {
  fb.BufferContext rootRef = fb.BufferContext.fromBytes(buffer);
  return const _PackageBundleReader().read(rootRef, 0);
}

class _PackageBundleReader extends fb.TableReader<_PackageBundleImpl> {
  const _PackageBundleReader();

  @override
  _PackageBundleImpl createObject(fb.BufferContext bc, int offset) =>
      _PackageBundleImpl(bc, offset);
}

class _PackageBundleImpl extends Object
    with _PackageBundleMixin
    implements idl.PackageBundle {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _PackageBundleImpl(this._bc, this._bcOffset);

  List<idl.UnlinkedDartSummary> _unlinkedDartSummary;

  @override
  List<idl.UnlinkedDartSummary> get unlinkedDartSummary {
    _unlinkedDartSummary ??= const fb.ListReader<idl.UnlinkedDartSummary>(
            _UnlinkedDartSummaryReader())
        .vTableGet(_bc, _bcOffset, 0, const <idl.UnlinkedDartSummary>[]);
    return _unlinkedDartSummary;
  }
}

abstract class _PackageBundleMixin implements idl.PackageBundle {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (unlinkedDartSummary.isNotEmpty) {
      _result["unlinkedDartSummary"] =
          unlinkedDartSummary.map((_value) => _value.toJson()).toList();
    }
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "unlinkedDartSummary": unlinkedDartSummary,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class SummarizedAnalysisErrorBuilder extends Object
    with _SummarizedAnalysisErrorMixin
    implements idl.SummarizedAnalysisError {
  String _correction;
  String _errorCode;
  int _length;
  String _message;
  int _offset;

  @override
  String get correction => _correction ??= '';

  set correction(String value) {
    this._correction = value;
  }

  @override
  String get errorCode => _errorCode ??= '';

  set errorCode(String value) {
    this._errorCode = value;
  }

  @override
  int get length => _length ??= 0;

  set length(int value) {
    assert(value == null || value >= 0);
    this._length = value;
  }

  @override
  String get message => _message ??= '';

  set message(String value) {
    this._message = value;
  }

  @override
  int get offset => _offset ??= 0;

  set offset(int value) {
    assert(value == null || value >= 0);
    this._offset = value;
  }

  SummarizedAnalysisErrorBuilder(
      {String correction,
      String errorCode,
      int length,
      String message,
      int offset})
      : _correction = correction,
        _errorCode = errorCode,
        _length = length,
        _message = message,
        _offset = offset;

  /// Flush [informative] data recursively.
  void flushInformative() {}

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    signature.addString(this._errorCode ?? '');
    signature.addString(this._message ?? '');
    signature.addString(this._correction ?? '');
    signature.addInt(this._offset ?? 0);
    signature.addInt(this._length ?? 0);
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_correction;
    fb.Offset offset_errorCode;
    fb.Offset offset_message;
    if (_correction != null) {
      offset_correction = fbBuilder.writeString(_correction);
    }
    if (_errorCode != null) {
      offset_errorCode = fbBuilder.writeString(_errorCode);
    }
    if (_message != null) {
      offset_message = fbBuilder.writeString(_message);
    }
    fbBuilder.startTable();
    if (offset_correction != null) {
      fbBuilder.addOffset(2, offset_correction);
    }
    if (offset_errorCode != null) {
      fbBuilder.addOffset(0, offset_errorCode);
    }
    if (_length != null && _length != 0) {
      fbBuilder.addUint32(4, _length);
    }
    if (offset_message != null) {
      fbBuilder.addOffset(1, offset_message);
    }
    if (_offset != null && _offset != 0) {
      fbBuilder.addUint32(3, _offset);
    }
    return fbBuilder.endTable();
  }
}

class _SummarizedAnalysisErrorReader
    extends fb.TableReader<_SummarizedAnalysisErrorImpl> {
  const _SummarizedAnalysisErrorReader();

  @override
  _SummarizedAnalysisErrorImpl createObject(fb.BufferContext bc, int offset) =>
      _SummarizedAnalysisErrorImpl(bc, offset);
}

class _SummarizedAnalysisErrorImpl extends Object
    with _SummarizedAnalysisErrorMixin
    implements idl.SummarizedAnalysisError {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _SummarizedAnalysisErrorImpl(this._bc, this._bcOffset);

  String _correction;
  String _errorCode;
  int _length;
  String _message;
  int _offset;

  @override
  String get correction {
    _correction ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 2, '');
    return _correction;
  }

  @override
  String get errorCode {
    _errorCode ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 0, '');
    return _errorCode;
  }

  @override
  int get length {
    _length ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 4, 0);
    return _length;
  }

  @override
  String get message {
    _message ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 1, '');
    return _message;
  }

  @override
  int get offset {
    _offset ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 3, 0);
    return _offset;
  }
}

abstract class _SummarizedAnalysisErrorMixin
    implements idl.SummarizedAnalysisError {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (correction != '') _result["correction"] = correction;
    if (errorCode != '') _result["errorCode"] = errorCode;
    if (length != 0) _result["length"] = length;
    if (message != '') _result["message"] = message;
    if (offset != 0) _result["offset"] = offset;
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "correction": correction,
        "errorCode": errorCode,
        "length": length,
        "message": message,
        "offset": offset,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class SummarizedAnalysisErrorFromPathBuilder extends Object
    with _SummarizedAnalysisErrorFromPathMixin
    implements idl.SummarizedAnalysisErrorFromPath {
  String _classname;
  SummarizedAnalysisErrorBuilder _originalError;
  String _path;

  @override
  String get classname => _classname ??= '';

  set classname(String value) {
    this._classname = value;
  }

  @override
  SummarizedAnalysisErrorBuilder get originalError => _originalError;

  set originalError(SummarizedAnalysisErrorBuilder value) {
    this._originalError = value;
  }

  @override
  String get path => _path ??= '';

  set path(String value) {
    this._path = value;
  }

  SummarizedAnalysisErrorFromPathBuilder(
      {String classname,
      SummarizedAnalysisErrorBuilder originalError,
      String path})
      : _classname = classname,
        _originalError = originalError,
        _path = path;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _originalError?.flushInformative();
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    signature.addString(this._path ?? '');
    signature.addString(this._classname ?? '');
    signature.addBool(this._originalError != null);
    this._originalError?.collectApiSignature(signature);
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_classname;
    fb.Offset offset_originalError;
    fb.Offset offset_path;
    if (_classname != null) {
      offset_classname = fbBuilder.writeString(_classname);
    }
    if (_originalError != null) {
      offset_originalError = _originalError.finish(fbBuilder);
    }
    if (_path != null) {
      offset_path = fbBuilder.writeString(_path);
    }
    fbBuilder.startTable();
    if (offset_classname != null) {
      fbBuilder.addOffset(1, offset_classname);
    }
    if (offset_originalError != null) {
      fbBuilder.addOffset(2, offset_originalError);
    }
    if (offset_path != null) {
      fbBuilder.addOffset(0, offset_path);
    }
    return fbBuilder.endTable();
  }
}

class _SummarizedAnalysisErrorFromPathReader
    extends fb.TableReader<_SummarizedAnalysisErrorFromPathImpl> {
  const _SummarizedAnalysisErrorFromPathReader();

  @override
  _SummarizedAnalysisErrorFromPathImpl createObject(
          fb.BufferContext bc, int offset) =>
      _SummarizedAnalysisErrorFromPathImpl(bc, offset);
}

class _SummarizedAnalysisErrorFromPathImpl extends Object
    with _SummarizedAnalysisErrorFromPathMixin
    implements idl.SummarizedAnalysisErrorFromPath {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _SummarizedAnalysisErrorFromPathImpl(this._bc, this._bcOffset);

  String _classname;
  idl.SummarizedAnalysisError _originalError;
  String _path;

  @override
  String get classname {
    _classname ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 1, '');
    return _classname;
  }

  @override
  idl.SummarizedAnalysisError get originalError {
    _originalError ??= const _SummarizedAnalysisErrorReader()
        .vTableGet(_bc, _bcOffset, 2, null);
    return _originalError;
  }

  @override
  String get path {
    _path ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 0, '');
    return _path;
  }
}

abstract class _SummarizedAnalysisErrorFromPathMixin
    implements idl.SummarizedAnalysisErrorFromPath {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (classname != '') _result["classname"] = classname;
    if (originalError != null) {
      _result["originalError"] = originalError.toJson();
    }
    if (path != '') _result["path"] = path;
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "classname": classname,
        "originalError": originalError,
        "path": path,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class SummarizedBindableBuilder extends Object
    with _SummarizedBindableMixin
    implements idl.SummarizedBindable {
  String _name;
  int _nameOffset;
  String _propName;
  int _propNameOffset;

  @override
  String get name => _name ??= '';

  set name(String value) {
    this._name = value;
  }

  @override
  int get nameOffset => _nameOffset ??= 0;

  set nameOffset(int value) {
    assert(value == null || value >= 0);
    this._nameOffset = value;
  }

  @override
  String get propName => _propName ??= '';

  set propName(String value) {
    this._propName = value;
  }

  @override
  int get propNameOffset => _propNameOffset ??= 0;

  set propNameOffset(int value) {
    assert(value == null || value >= 0);
    this._propNameOffset = value;
  }

  SummarizedBindableBuilder(
      {String name, int nameOffset, String propName, int propNameOffset})
      : _name = name,
        _nameOffset = nameOffset,
        _propName = propName,
        _propNameOffset = propNameOffset;

  /// Flush [informative] data recursively.
  void flushInformative() {}

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    signature.addString(this._name ?? '');
    signature.addInt(this._nameOffset ?? 0);
    signature.addString(this._propName ?? '');
    signature.addInt(this._propNameOffset ?? 0);
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_name;
    fb.Offset offset_propName;
    if (_name != null) {
      offset_name = fbBuilder.writeString(_name);
    }
    if (_propName != null) {
      offset_propName = fbBuilder.writeString(_propName);
    }
    fbBuilder.startTable();
    if (offset_name != null) {
      fbBuilder.addOffset(0, offset_name);
    }
    if (_nameOffset != null && _nameOffset != 0) {
      fbBuilder.addUint32(1, _nameOffset);
    }
    if (offset_propName != null) {
      fbBuilder.addOffset(2, offset_propName);
    }
    if (_propNameOffset != null && _propNameOffset != 0) {
      fbBuilder.addUint32(3, _propNameOffset);
    }
    return fbBuilder.endTable();
  }
}

class _SummarizedBindableReader
    extends fb.TableReader<_SummarizedBindableImpl> {
  const _SummarizedBindableReader();

  @override
  _SummarizedBindableImpl createObject(fb.BufferContext bc, int offset) =>
      _SummarizedBindableImpl(bc, offset);
}

class _SummarizedBindableImpl extends Object
    with _SummarizedBindableMixin
    implements idl.SummarizedBindable {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _SummarizedBindableImpl(this._bc, this._bcOffset);

  String _name;
  int _nameOffset;
  String _propName;
  int _propNameOffset;

  @override
  String get name {
    _name ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 0, '');
    return _name;
  }

  @override
  int get nameOffset {
    _nameOffset ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 1, 0);
    return _nameOffset;
  }

  @override
  String get propName {
    _propName ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 2, '');
    return _propName;
  }

  @override
  int get propNameOffset {
    _propNameOffset ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 3, 0);
    return _propNameOffset;
  }
}

abstract class _SummarizedBindableMixin implements idl.SummarizedBindable {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (name != '') _result["name"] = name;
    if (nameOffset != 0) _result["nameOffset"] = nameOffset;
    if (propName != '') _result["propName"] = propName;
    if (propNameOffset != 0) _result["propNameOffset"] = propNameOffset;
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "name": name,
        "nameOffset": nameOffset,
        "propName": propName,
        "propNameOffset": propNameOffset,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class SummarizedClassAnnotationsBuilder extends Object
    with _SummarizedClassAnnotationsMixin
    implements idl.SummarizedClassAnnotations {
  String _className;
  List<SummarizedContentChildFieldBuilder> _contentChildFields;
  List<SummarizedContentChildFieldBuilder> _contentChildrenFields;
  List<SummarizedBindableBuilder> _inputs;
  List<SummarizedBindableBuilder> _outputs;

  @override
  String get className => _className ??= '';

  set className(String value) {
    this._className = value;
  }

  @override
  List<SummarizedContentChildFieldBuilder> get contentChildFields =>
      _contentChildFields ??= <SummarizedContentChildFieldBuilder>[];

  set contentChildFields(List<SummarizedContentChildFieldBuilder> value) {
    this._contentChildFields = value;
  }

  @override
  List<SummarizedContentChildFieldBuilder> get contentChildrenFields =>
      _contentChildrenFields ??= <SummarizedContentChildFieldBuilder>[];

  set contentChildrenFields(List<SummarizedContentChildFieldBuilder> value) {
    this._contentChildrenFields = value;
  }

  @override
  List<SummarizedBindableBuilder> get inputs =>
      _inputs ??= <SummarizedBindableBuilder>[];

  set inputs(List<SummarizedBindableBuilder> value) {
    this._inputs = value;
  }

  @override
  List<SummarizedBindableBuilder> get outputs =>
      _outputs ??= <SummarizedBindableBuilder>[];

  set outputs(List<SummarizedBindableBuilder> value) {
    this._outputs = value;
  }

  SummarizedClassAnnotationsBuilder(
      {String className,
      List<SummarizedContentChildFieldBuilder> contentChildFields,
      List<SummarizedContentChildFieldBuilder> contentChildrenFields,
      List<SummarizedBindableBuilder> inputs,
      List<SummarizedBindableBuilder> outputs})
      : _className = className,
        _contentChildFields = contentChildFields,
        _contentChildrenFields = contentChildrenFields,
        _inputs = inputs,
        _outputs = outputs;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _contentChildFields?.forEach((b) => b.flushInformative());
    _contentChildrenFields?.forEach((b) => b.flushInformative());
    _inputs?.forEach((b) => b.flushInformative());
    _outputs?.forEach((b) => b.flushInformative());
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    signature.addString(this._className ?? '');
    if (this._inputs == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._inputs.length);
      for (var x in this._inputs) {
        x?.collectApiSignature(signature);
      }
    }
    if (this._outputs == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._outputs.length);
      for (var x in this._outputs) {
        x?.collectApiSignature(signature);
      }
    }
    if (this._contentChildFields == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._contentChildFields.length);
      for (var x in this._contentChildFields) {
        x?.collectApiSignature(signature);
      }
    }
    if (this._contentChildrenFields == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._contentChildrenFields.length);
      for (var x in this._contentChildrenFields) {
        x?.collectApiSignature(signature);
      }
    }
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_className;
    fb.Offset offset_contentChildFields;
    fb.Offset offset_contentChildrenFields;
    fb.Offset offset_inputs;
    fb.Offset offset_outputs;
    if (_className != null) {
      offset_className = fbBuilder.writeString(_className);
    }
    if (!(_contentChildFields == null || _contentChildFields.isEmpty)) {
      offset_contentChildFields = fbBuilder.writeList(
          _contentChildFields.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_contentChildrenFields == null || _contentChildrenFields.isEmpty)) {
      offset_contentChildrenFields = fbBuilder.writeList(
          _contentChildrenFields.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_inputs == null || _inputs.isEmpty)) {
      offset_inputs =
          fbBuilder.writeList(_inputs.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_outputs == null || _outputs.isEmpty)) {
      offset_outputs = fbBuilder
          .writeList(_outputs.map((b) => b.finish(fbBuilder)).toList());
    }
    fbBuilder.startTable();
    if (offset_className != null) {
      fbBuilder.addOffset(0, offset_className);
    }
    if (offset_contentChildFields != null) {
      fbBuilder.addOffset(3, offset_contentChildFields);
    }
    if (offset_contentChildrenFields != null) {
      fbBuilder.addOffset(4, offset_contentChildrenFields);
    }
    if (offset_inputs != null) {
      fbBuilder.addOffset(1, offset_inputs);
    }
    if (offset_outputs != null) {
      fbBuilder.addOffset(2, offset_outputs);
    }
    return fbBuilder.endTable();
  }
}

class _SummarizedClassAnnotationsReader
    extends fb.TableReader<_SummarizedClassAnnotationsImpl> {
  const _SummarizedClassAnnotationsReader();

  @override
  _SummarizedClassAnnotationsImpl createObject(
          fb.BufferContext bc, int offset) =>
      _SummarizedClassAnnotationsImpl(bc, offset);
}

class _SummarizedClassAnnotationsImpl extends Object
    with _SummarizedClassAnnotationsMixin
    implements idl.SummarizedClassAnnotations {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _SummarizedClassAnnotationsImpl(this._bc, this._bcOffset);

  String _className;
  List<idl.SummarizedContentChildField> _contentChildFields;
  List<idl.SummarizedContentChildField> _contentChildrenFields;
  List<idl.SummarizedBindable> _inputs;
  List<idl.SummarizedBindable> _outputs;

  @override
  String get className {
    _className ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 0, '');
    return _className;
  }

  @override
  List<idl.SummarizedContentChildField> get contentChildFields {
    _contentChildFields ??=
        const fb.ListReader<idl.SummarizedContentChildField>(
                _SummarizedContentChildFieldReader())
            .vTableGet(
                _bc, _bcOffset, 3, const <idl.SummarizedContentChildField>[]);
    return _contentChildFields;
  }

  @override
  List<idl.SummarizedContentChildField> get contentChildrenFields {
    _contentChildrenFields ??=
        const fb.ListReader<idl.SummarizedContentChildField>(
                _SummarizedContentChildFieldReader())
            .vTableGet(
                _bc, _bcOffset, 4, const <idl.SummarizedContentChildField>[]);
    return _contentChildrenFields;
  }

  @override
  List<idl.SummarizedBindable> get inputs {
    _inputs ??=
        const fb.ListReader<idl.SummarizedBindable>(_SummarizedBindableReader())
            .vTableGet(_bc, _bcOffset, 1, const <idl.SummarizedBindable>[]);
    return _inputs;
  }

  @override
  List<idl.SummarizedBindable> get outputs {
    _outputs ??=
        const fb.ListReader<idl.SummarizedBindable>(_SummarizedBindableReader())
            .vTableGet(_bc, _bcOffset, 2, const <idl.SummarizedBindable>[]);
    return _outputs;
  }
}

abstract class _SummarizedClassAnnotationsMixin
    implements idl.SummarizedClassAnnotations {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (className != '') _result["className"] = className;
    if (contentChildFields.isNotEmpty) {
      _result["contentChildFields"] =
          contentChildFields.map((_value) => _value.toJson()).toList();
    }
    if (contentChildrenFields.isNotEmpty) {
      _result["contentChildrenFields"] =
          contentChildrenFields.map((_value) => _value.toJson()).toList();
    }
    if (inputs.isNotEmpty) {
      _result["inputs"] = inputs.map((_value) => _value.toJson()).toList();
    }
    if (outputs.isNotEmpty) {
      _result["outputs"] = outputs.map((_value) => _value.toJson()).toList();
    }
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "className": className,
        "contentChildFields": contentChildFields,
        "contentChildrenFields": contentChildrenFields,
        "inputs": inputs,
        "outputs": outputs,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class SummarizedContentChildFieldBuilder extends Object
    with _SummarizedContentChildFieldMixin
    implements idl.SummarizedContentChildField {
  String _fieldName;
  int _nameLength;
  int _nameOffset;
  int _typeLength;
  int _typeOffset;

  @override
  String get fieldName => _fieldName ??= '';

  set fieldName(String value) {
    this._fieldName = value;
  }

  @override
  int get nameLength => _nameLength ??= 0;

  set nameLength(int value) {
    assert(value == null || value >= 0);
    this._nameLength = value;
  }

  @override
  int get nameOffset => _nameOffset ??= 0;

  set nameOffset(int value) {
    assert(value == null || value >= 0);
    this._nameOffset = value;
  }

  @override
  int get typeLength => _typeLength ??= 0;

  set typeLength(int value) {
    assert(value == null || value >= 0);
    this._typeLength = value;
  }

  @override
  int get typeOffset => _typeOffset ??= 0;

  set typeOffset(int value) {
    assert(value == null || value >= 0);
    this._typeOffset = value;
  }

  SummarizedContentChildFieldBuilder(
      {String fieldName,
      int nameLength,
      int nameOffset,
      int typeLength,
      int typeOffset})
      : _fieldName = fieldName,
        _nameLength = nameLength,
        _nameOffset = nameOffset,
        _typeLength = typeLength,
        _typeOffset = typeOffset;

  /// Flush [informative] data recursively.
  void flushInformative() {}

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    signature.addString(this._fieldName ?? '');
    signature.addInt(this._nameOffset ?? 0);
    signature.addInt(this._nameLength ?? 0);
    signature.addInt(this._typeOffset ?? 0);
    signature.addInt(this._typeLength ?? 0);
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_fieldName;
    if (_fieldName != null) {
      offset_fieldName = fbBuilder.writeString(_fieldName);
    }
    fbBuilder.startTable();
    if (offset_fieldName != null) {
      fbBuilder.addOffset(0, offset_fieldName);
    }
    if (_nameLength != null && _nameLength != 0) {
      fbBuilder.addUint32(2, _nameLength);
    }
    if (_nameOffset != null && _nameOffset != 0) {
      fbBuilder.addUint32(1, _nameOffset);
    }
    if (_typeLength != null && _typeLength != 0) {
      fbBuilder.addUint32(4, _typeLength);
    }
    if (_typeOffset != null && _typeOffset != 0) {
      fbBuilder.addUint32(3, _typeOffset);
    }
    return fbBuilder.endTable();
  }
}

class _SummarizedContentChildFieldReader
    extends fb.TableReader<_SummarizedContentChildFieldImpl> {
  const _SummarizedContentChildFieldReader();

  @override
  _SummarizedContentChildFieldImpl createObject(
          fb.BufferContext bc, int offset) =>
      _SummarizedContentChildFieldImpl(bc, offset);
}

class _SummarizedContentChildFieldImpl extends Object
    with _SummarizedContentChildFieldMixin
    implements idl.SummarizedContentChildField {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _SummarizedContentChildFieldImpl(this._bc, this._bcOffset);

  String _fieldName;
  int _nameLength;
  int _nameOffset;
  int _typeLength;
  int _typeOffset;

  @override
  String get fieldName {
    _fieldName ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 0, '');
    return _fieldName;
  }

  @override
  int get nameLength {
    _nameLength ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 2, 0);
    return _nameLength;
  }

  @override
  int get nameOffset {
    _nameOffset ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 1, 0);
    return _nameOffset;
  }

  @override
  int get typeLength {
    _typeLength ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 4, 0);
    return _typeLength;
  }

  @override
  int get typeOffset {
    _typeOffset ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 3, 0);
    return _typeOffset;
  }
}

abstract class _SummarizedContentChildFieldMixin
    implements idl.SummarizedContentChildField {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (fieldName != '') _result["fieldName"] = fieldName;
    if (nameLength != 0) _result["nameLength"] = nameLength;
    if (nameOffset != 0) _result["nameOffset"] = nameOffset;
    if (typeLength != 0) _result["typeLength"] = typeLength;
    if (typeOffset != 0) _result["typeOffset"] = typeOffset;
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "fieldName": fieldName,
        "nameLength": nameLength,
        "nameOffset": nameOffset,
        "typeLength": typeLength,
        "typeOffset": typeOffset,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class SummarizedDirectiveBuilder extends Object
    with _SummarizedDirectiveMixin
    implements idl.SummarizedDirective {
  SummarizedClassAnnotationsBuilder _classAnnotations;
  int _constDirectiveStrategyLength;
  int _constDirectiveStrategyOffset;
  String _exportAs;
  int _exportAsOffset;
  List<SummarizedExportedIdentifierBuilder> _exports;
  String _functionName;
  bool _isComponent;
  List<SummarizedNgContentBuilder> _ngContents;
  List<SummarizedPipesUseBuilder> _pipesUse;
  int _selectorOffset;
  String _selectorStr;
  List<SummarizedDirectiveUseBuilder> _subdirectives;
  int _templateOffset;
  String _templateText;
  String _templateUrl;
  int _templateUrlLength;
  int _templateUrlOffset;
  bool _usesArrayOfDirectiveReferencesStrategy;

  @override
  SummarizedClassAnnotationsBuilder get classAnnotations => _classAnnotations;

  set classAnnotations(SummarizedClassAnnotationsBuilder value) {
    this._classAnnotations = value;
  }

  @override
  int get constDirectiveStrategyLength => _constDirectiveStrategyLength ??= 0;

  set constDirectiveStrategyLength(int value) {
    assert(value == null || value >= 0);
    this._constDirectiveStrategyLength = value;
  }

  @override
  int get constDirectiveStrategyOffset => _constDirectiveStrategyOffset ??= 0;

  set constDirectiveStrategyOffset(int value) {
    assert(value == null || value >= 0);
    this._constDirectiveStrategyOffset = value;
  }

  @override
  String get exportAs => _exportAs ??= '';

  set exportAs(String value) {
    this._exportAs = value;
  }

  @override
  int get exportAsOffset => _exportAsOffset ??= 0;

  set exportAsOffset(int value) {
    assert(value == null || value >= 0);
    this._exportAsOffset = value;
  }

  @override
  List<SummarizedExportedIdentifierBuilder> get exports =>
      _exports ??= <SummarizedExportedIdentifierBuilder>[];

  set exports(List<SummarizedExportedIdentifierBuilder> value) {
    this._exports = value;
  }

  @override
  String get functionName => _functionName ??= '';

  set functionName(String value) {
    this._functionName = value;
  }

  @override
  bool get isComponent => _isComponent ??= false;

  set isComponent(bool value) {
    this._isComponent = value;
  }

  @override
  List<SummarizedNgContentBuilder> get ngContents =>
      _ngContents ??= <SummarizedNgContentBuilder>[];

  set ngContents(List<SummarizedNgContentBuilder> value) {
    this._ngContents = value;
  }

  @override
  List<SummarizedPipesUseBuilder> get pipesUse =>
      _pipesUse ??= <SummarizedPipesUseBuilder>[];

  set pipesUse(List<SummarizedPipesUseBuilder> value) {
    this._pipesUse = value;
  }

  @override
  int get selectorOffset => _selectorOffset ??= 0;

  set selectorOffset(int value) {
    assert(value == null || value >= 0);
    this._selectorOffset = value;
  }

  @override
  String get selectorStr => _selectorStr ??= '';

  set selectorStr(String value) {
    this._selectorStr = value;
  }

  @override
  List<SummarizedDirectiveUseBuilder> get subdirectives =>
      _subdirectives ??= <SummarizedDirectiveUseBuilder>[];

  set subdirectives(List<SummarizedDirectiveUseBuilder> value) {
    this._subdirectives = value;
  }

  @override
  int get templateOffset => _templateOffset ??= 0;

  set templateOffset(int value) {
    assert(value == null || value >= 0);
    this._templateOffset = value;
  }

  @override
  String get templateText => _templateText ??= '';

  set templateText(String value) {
    this._templateText = value;
  }

  @override
  String get templateUrl => _templateUrl ??= '';

  set templateUrl(String value) {
    this._templateUrl = value;
  }

  @override
  int get templateUrlLength => _templateUrlLength ??= 0;

  set templateUrlLength(int value) {
    assert(value == null || value >= 0);
    this._templateUrlLength = value;
  }

  @override
  int get templateUrlOffset => _templateUrlOffset ??= 0;

  set templateUrlOffset(int value) {
    assert(value == null || value >= 0);
    this._templateUrlOffset = value;
  }

  @override
  bool get usesArrayOfDirectiveReferencesStrategy =>
      _usesArrayOfDirectiveReferencesStrategy ??= false;

  set usesArrayOfDirectiveReferencesStrategy(bool value) {
    this._usesArrayOfDirectiveReferencesStrategy = value;
  }

  SummarizedDirectiveBuilder(
      {SummarizedClassAnnotationsBuilder classAnnotations,
      int constDirectiveStrategyLength,
      int constDirectiveStrategyOffset,
      String exportAs,
      int exportAsOffset,
      List<SummarizedExportedIdentifierBuilder> exports,
      String functionName,
      bool isComponent,
      List<SummarizedNgContentBuilder> ngContents,
      List<SummarizedPipesUseBuilder> pipesUse,
      int selectorOffset,
      String selectorStr,
      List<SummarizedDirectiveUseBuilder> subdirectives,
      int templateOffset,
      String templateText,
      String templateUrl,
      int templateUrlLength,
      int templateUrlOffset,
      bool usesArrayOfDirectiveReferencesStrategy})
      : _classAnnotations = classAnnotations,
        _constDirectiveStrategyLength = constDirectiveStrategyLength,
        _constDirectiveStrategyOffset = constDirectiveStrategyOffset,
        _exportAs = exportAs,
        _exportAsOffset = exportAsOffset,
        _exports = exports,
        _functionName = functionName,
        _isComponent = isComponent,
        _ngContents = ngContents,
        _pipesUse = pipesUse,
        _selectorOffset = selectorOffset,
        _selectorStr = selectorStr,
        _subdirectives = subdirectives,
        _templateOffset = templateOffset,
        _templateText = templateText,
        _templateUrl = templateUrl,
        _templateUrlLength = templateUrlLength,
        _templateUrlOffset = templateUrlOffset,
        _usesArrayOfDirectiveReferencesStrategy =
            usesArrayOfDirectiveReferencesStrategy;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _classAnnotations?.flushInformative();
    _exports?.forEach((b) => b.flushInformative());
    _ngContents?.forEach((b) => b.flushInformative());
    _pipesUse?.forEach((b) => b.flushInformative());
    _subdirectives?.forEach((b) => b.flushInformative());
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    signature.addBool(this._classAnnotations != null);
    this._classAnnotations?.collectApiSignature(signature);
    signature.addString(this._functionName ?? '');
    signature.addBool(this._isComponent == true);
    signature.addString(this._selectorStr ?? '');
    signature.addInt(this._selectorOffset ?? 0);
    signature.addString(this._exportAs ?? '');
    signature.addInt(this._exportAsOffset ?? 0);
    signature.addString(this._templateUrl ?? '');
    signature.addInt(this._templateUrlOffset ?? 0);
    signature.addInt(this._templateUrlLength ?? 0);
    signature.addString(this._templateText ?? '');
    signature.addInt(this._templateOffset ?? 0);
    if (this._ngContents == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._ngContents.length);
      for (var x in this._ngContents) {
        x?.collectApiSignature(signature);
      }
    }
    signature.addBool(this._usesArrayOfDirectiveReferencesStrategy == true);
    if (this._subdirectives == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._subdirectives.length);
      for (var x in this._subdirectives) {
        x?.collectApiSignature(signature);
      }
    }
    if (this._exports == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._exports.length);
      for (var x in this._exports) {
        x?.collectApiSignature(signature);
      }
    }
    if (this._pipesUse == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._pipesUse.length);
      for (var x in this._pipesUse) {
        x?.collectApiSignature(signature);
      }
    }
    signature.addInt(this._constDirectiveStrategyOffset ?? 0);
    signature.addInt(this._constDirectiveStrategyLength ?? 0);
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_classAnnotations;
    fb.Offset offset_exportAs;
    fb.Offset offset_exports;
    fb.Offset offset_functionName;
    fb.Offset offset_ngContents;
    fb.Offset offset_pipesUse;
    fb.Offset offset_selectorStr;
    fb.Offset offset_subdirectives;
    fb.Offset offset_templateText;
    fb.Offset offset_templateUrl;
    if (_classAnnotations != null) {
      offset_classAnnotations = _classAnnotations.finish(fbBuilder);
    }
    if (_exportAs != null) {
      offset_exportAs = fbBuilder.writeString(_exportAs);
    }
    if (!(_exports == null || _exports.isEmpty)) {
      offset_exports = fbBuilder
          .writeList(_exports.map((b) => b.finish(fbBuilder)).toList());
    }
    if (_functionName != null) {
      offset_functionName = fbBuilder.writeString(_functionName);
    }
    if (!(_ngContents == null || _ngContents.isEmpty)) {
      offset_ngContents = fbBuilder
          .writeList(_ngContents.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_pipesUse == null || _pipesUse.isEmpty)) {
      offset_pipesUse = fbBuilder
          .writeList(_pipesUse.map((b) => b.finish(fbBuilder)).toList());
    }
    if (_selectorStr != null) {
      offset_selectorStr = fbBuilder.writeString(_selectorStr);
    }
    if (!(_subdirectives == null || _subdirectives.isEmpty)) {
      offset_subdirectives = fbBuilder
          .writeList(_subdirectives.map((b) => b.finish(fbBuilder)).toList());
    }
    if (_templateText != null) {
      offset_templateText = fbBuilder.writeString(_templateText);
    }
    if (_templateUrl != null) {
      offset_templateUrl = fbBuilder.writeString(_templateUrl);
    }
    fbBuilder.startTable();
    if (offset_classAnnotations != null) {
      fbBuilder.addOffset(0, offset_classAnnotations);
    }
    if (_constDirectiveStrategyLength != null &&
        _constDirectiveStrategyLength != 0) {
      fbBuilder.addUint32(18, _constDirectiveStrategyLength);
    }
    if (_constDirectiveStrategyOffset != null &&
        _constDirectiveStrategyOffset != 0) {
      fbBuilder.addUint32(17, _constDirectiveStrategyOffset);
    }
    if (offset_exportAs != null) {
      fbBuilder.addOffset(5, offset_exportAs);
    }
    if (_exportAsOffset != null && _exportAsOffset != 0) {
      fbBuilder.addUint32(6, _exportAsOffset);
    }
    if (offset_exports != null) {
      fbBuilder.addOffset(15, offset_exports);
    }
    if (offset_functionName != null) {
      fbBuilder.addOffset(1, offset_functionName);
    }
    if (_isComponent == true) {
      fbBuilder.addBool(2, true);
    }
    if (offset_ngContents != null) {
      fbBuilder.addOffset(12, offset_ngContents);
    }
    if (offset_pipesUse != null) {
      fbBuilder.addOffset(16, offset_pipesUse);
    }
    if (_selectorOffset != null && _selectorOffset != 0) {
      fbBuilder.addUint32(4, _selectorOffset);
    }
    if (offset_selectorStr != null) {
      fbBuilder.addOffset(3, offset_selectorStr);
    }
    if (offset_subdirectives != null) {
      fbBuilder.addOffset(14, offset_subdirectives);
    }
    if (_templateOffset != null && _templateOffset != 0) {
      fbBuilder.addUint32(11, _templateOffset);
    }
    if (offset_templateText != null) {
      fbBuilder.addOffset(10, offset_templateText);
    }
    if (offset_templateUrl != null) {
      fbBuilder.addOffset(7, offset_templateUrl);
    }
    if (_templateUrlLength != null && _templateUrlLength != 0) {
      fbBuilder.addUint32(9, _templateUrlLength);
    }
    if (_templateUrlOffset != null && _templateUrlOffset != 0) {
      fbBuilder.addUint32(8, _templateUrlOffset);
    }
    if (_usesArrayOfDirectiveReferencesStrategy == true) {
      fbBuilder.addBool(13, true);
    }
    return fbBuilder.endTable();
  }
}

class _SummarizedDirectiveReader
    extends fb.TableReader<_SummarizedDirectiveImpl> {
  const _SummarizedDirectiveReader();

  @override
  _SummarizedDirectiveImpl createObject(fb.BufferContext bc, int offset) =>
      _SummarizedDirectiveImpl(bc, offset);
}

class _SummarizedDirectiveImpl extends Object
    with _SummarizedDirectiveMixin
    implements idl.SummarizedDirective {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _SummarizedDirectiveImpl(this._bc, this._bcOffset);

  idl.SummarizedClassAnnotations _classAnnotations;
  int _constDirectiveStrategyLength;
  int _constDirectiveStrategyOffset;
  String _exportAs;
  int _exportAsOffset;
  List<idl.SummarizedExportedIdentifier> _exports;
  String _functionName;
  bool _isComponent;
  List<idl.SummarizedNgContent> _ngContents;
  List<idl.SummarizedPipesUse> _pipesUse;
  int _selectorOffset;
  String _selectorStr;
  List<idl.SummarizedDirectiveUse> _subdirectives;
  int _templateOffset;
  String _templateText;
  String _templateUrl;
  int _templateUrlLength;
  int _templateUrlOffset;
  bool _usesArrayOfDirectiveReferencesStrategy;

  @override
  idl.SummarizedClassAnnotations get classAnnotations {
    _classAnnotations ??= const _SummarizedClassAnnotationsReader()
        .vTableGet(_bc, _bcOffset, 0, null);
    return _classAnnotations;
  }

  @override
  int get constDirectiveStrategyLength {
    _constDirectiveStrategyLength ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 18, 0);
    return _constDirectiveStrategyLength;
  }

  @override
  int get constDirectiveStrategyOffset {
    _constDirectiveStrategyOffset ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 17, 0);
    return _constDirectiveStrategyOffset;
  }

  @override
  String get exportAs {
    _exportAs ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 5, '');
    return _exportAs;
  }

  @override
  int get exportAsOffset {
    _exportAsOffset ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 6, 0);
    return _exportAsOffset;
  }

  @override
  List<idl.SummarizedExportedIdentifier> get exports {
    _exports ??= const fb.ListReader<idl.SummarizedExportedIdentifier>(
            _SummarizedExportedIdentifierReader())
        .vTableGet(
            _bc, _bcOffset, 15, const <idl.SummarizedExportedIdentifier>[]);
    return _exports;
  }

  @override
  String get functionName {
    _functionName ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 1, '');
    return _functionName;
  }

  @override
  bool get isComponent {
    _isComponent ??= const fb.BoolReader().vTableGet(_bc, _bcOffset, 2, false);
    return _isComponent;
  }

  @override
  List<idl.SummarizedNgContent> get ngContents {
    _ngContents ??= const fb.ListReader<idl.SummarizedNgContent>(
            _SummarizedNgContentReader())
        .vTableGet(_bc, _bcOffset, 12, const <idl.SummarizedNgContent>[]);
    return _ngContents;
  }

  @override
  List<idl.SummarizedPipesUse> get pipesUse {
    _pipesUse ??=
        const fb.ListReader<idl.SummarizedPipesUse>(_SummarizedPipesUseReader())
            .vTableGet(_bc, _bcOffset, 16, const <idl.SummarizedPipesUse>[]);
    return _pipesUse;
  }

  @override
  int get selectorOffset {
    _selectorOffset ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 4, 0);
    return _selectorOffset;
  }

  @override
  String get selectorStr {
    _selectorStr ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 3, '');
    return _selectorStr;
  }

  @override
  List<idl.SummarizedDirectiveUse> get subdirectives {
    _subdirectives ??= const fb.ListReader<idl.SummarizedDirectiveUse>(
            _SummarizedDirectiveUseReader())
        .vTableGet(_bc, _bcOffset, 14, const <idl.SummarizedDirectiveUse>[]);
    return _subdirectives;
  }

  @override
  int get templateOffset {
    _templateOffset ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 11, 0);
    return _templateOffset;
  }

  @override
  String get templateText {
    _templateText ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 10, '');
    return _templateText;
  }

  @override
  String get templateUrl {
    _templateUrl ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 7, '');
    return _templateUrl;
  }

  @override
  int get templateUrlLength {
    _templateUrlLength ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 9, 0);
    return _templateUrlLength;
  }

  @override
  int get templateUrlOffset {
    _templateUrlOffset ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 8, 0);
    return _templateUrlOffset;
  }

  @override
  bool get usesArrayOfDirectiveReferencesStrategy {
    _usesArrayOfDirectiveReferencesStrategy ??=
        const fb.BoolReader().vTableGet(_bc, _bcOffset, 13, false);
    return _usesArrayOfDirectiveReferencesStrategy;
  }
}

abstract class _SummarizedDirectiveMixin implements idl.SummarizedDirective {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (classAnnotations != null) {
      _result["classAnnotations"] = classAnnotations.toJson();
    }
    if (constDirectiveStrategyLength != 0) {
      _result["constDirectiveStrategyLength"] = constDirectiveStrategyLength;
    }
    if (constDirectiveStrategyOffset != 0) {
      _result["constDirectiveStrategyOffset"] = constDirectiveStrategyOffset;
    }
    if (exportAs != '') _result["exportAs"] = exportAs;
    if (exportAsOffset != 0) _result["exportAsOffset"] = exportAsOffset;
    if (exports.isNotEmpty) {
      _result["exports"] = exports.map((_value) => _value.toJson()).toList();
    }
    if (functionName != '') _result["functionName"] = functionName;
    if (isComponent != false) _result["isComponent"] = isComponent;
    if (ngContents.isNotEmpty) {
      _result["ngContents"] =
          ngContents.map((_value) => _value.toJson()).toList();
    }
    if (pipesUse.isNotEmpty) {
      _result["pipesUse"] = pipesUse.map((_value) => _value.toJson()).toList();
    }
    if (selectorOffset != 0) _result["selectorOffset"] = selectorOffset;
    if (selectorStr != '') _result["selectorStr"] = selectorStr;
    if (subdirectives.isNotEmpty) {
      _result["subdirectives"] =
          subdirectives.map((_value) => _value.toJson()).toList();
    }
    if (templateOffset != 0) _result["templateOffset"] = templateOffset;
    if (templateText != '') _result["templateText"] = templateText;
    if (templateUrl != '') _result["templateUrl"] = templateUrl;
    if (templateUrlLength != 0) {
      _result["templateUrlLength"] = templateUrlLength;
    }
    if (templateUrlOffset != 0) {
      _result["templateUrlOffset"] = templateUrlOffset;
    }
    if (usesArrayOfDirectiveReferencesStrategy != false) {
      _result["usesArrayOfDirectiveReferencesStrategy"] =
          usesArrayOfDirectiveReferencesStrategy;
    }
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "classAnnotations": classAnnotations,
        "constDirectiveStrategyLength": constDirectiveStrategyLength,
        "constDirectiveStrategyOffset": constDirectiveStrategyOffset,
        "exportAs": exportAs,
        "exportAsOffset": exportAsOffset,
        "exports": exports,
        "functionName": functionName,
        "isComponent": isComponent,
        "ngContents": ngContents,
        "pipesUse": pipesUse,
        "selectorOffset": selectorOffset,
        "selectorStr": selectorStr,
        "subdirectives": subdirectives,
        "templateOffset": templateOffset,
        "templateText": templateText,
        "templateUrl": templateUrl,
        "templateUrlLength": templateUrlLength,
        "templateUrlOffset": templateUrlOffset,
        "usesArrayOfDirectiveReferencesStrategy":
            usesArrayOfDirectiveReferencesStrategy,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class SummarizedDirectiveUseBuilder extends Object
    with _SummarizedDirectiveUseMixin
    implements idl.SummarizedDirectiveUse {
  int _length;
  String _name;
  int _offset;
  String _prefix;

  @override
  int get length => _length ??= 0;

  set length(int value) {
    assert(value == null || value >= 0);
    this._length = value;
  }

  @override
  String get name => _name ??= '';

  set name(String value) {
    this._name = value;
  }

  @override
  int get offset => _offset ??= 0;

  set offset(int value) {
    assert(value == null || value >= 0);
    this._offset = value;
  }

  @override
  String get prefix => _prefix ??= '';

  set prefix(String value) {
    this._prefix = value;
  }

  SummarizedDirectiveUseBuilder(
      {int length, String name, int offset, String prefix})
      : _length = length,
        _name = name,
        _offset = offset,
        _prefix = prefix;

  /// Flush [informative] data recursively.
  void flushInformative() {}

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    signature.addString(this._name ?? '');
    signature.addString(this._prefix ?? '');
    signature.addInt(this._offset ?? 0);
    signature.addInt(this._length ?? 0);
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_name;
    fb.Offset offset_prefix;
    if (_name != null) {
      offset_name = fbBuilder.writeString(_name);
    }
    if (_prefix != null) {
      offset_prefix = fbBuilder.writeString(_prefix);
    }
    fbBuilder.startTable();
    if (_length != null && _length != 0) {
      fbBuilder.addUint32(3, _length);
    }
    if (offset_name != null) {
      fbBuilder.addOffset(0, offset_name);
    }
    if (_offset != null && _offset != 0) {
      fbBuilder.addUint32(2, _offset);
    }
    if (offset_prefix != null) {
      fbBuilder.addOffset(1, offset_prefix);
    }
    return fbBuilder.endTable();
  }
}

class _SummarizedDirectiveUseReader
    extends fb.TableReader<_SummarizedDirectiveUseImpl> {
  const _SummarizedDirectiveUseReader();

  @override
  _SummarizedDirectiveUseImpl createObject(fb.BufferContext bc, int offset) =>
      _SummarizedDirectiveUseImpl(bc, offset);
}

class _SummarizedDirectiveUseImpl extends Object
    with _SummarizedDirectiveUseMixin
    implements idl.SummarizedDirectiveUse {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _SummarizedDirectiveUseImpl(this._bc, this._bcOffset);

  int _length;
  String _name;
  int _offset;
  String _prefix;

  @override
  int get length {
    _length ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 3, 0);
    return _length;
  }

  @override
  String get name {
    _name ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 0, '');
    return _name;
  }

  @override
  int get offset {
    _offset ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 2, 0);
    return _offset;
  }

  @override
  String get prefix {
    _prefix ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 1, '');
    return _prefix;
  }
}

abstract class _SummarizedDirectiveUseMixin
    implements idl.SummarizedDirectiveUse {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (length != 0) _result["length"] = length;
    if (name != '') _result["name"] = name;
    if (offset != 0) _result["offset"] = offset;
    if (prefix != '') _result["prefix"] = prefix;
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "length": length,
        "name": name,
        "offset": offset,
        "prefix": prefix,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class SummarizedExportedIdentifierBuilder extends Object
    with _SummarizedExportedIdentifierMixin
    implements idl.SummarizedExportedIdentifier {
  int _length;
  String _name;
  int _offset;
  String _prefix;

  @override
  int get length => _length ??= 0;

  set length(int value) {
    assert(value == null || value >= 0);
    this._length = value;
  }

  @override
  String get name => _name ??= '';

  set name(String value) {
    this._name = value;
  }

  @override
  int get offset => _offset ??= 0;

  set offset(int value) {
    assert(value == null || value >= 0);
    this._offset = value;
  }

  @override
  String get prefix => _prefix ??= '';

  set prefix(String value) {
    this._prefix = value;
  }

  SummarizedExportedIdentifierBuilder(
      {int length, String name, int offset, String prefix})
      : _length = length,
        _name = name,
        _offset = offset,
        _prefix = prefix;

  /// Flush [informative] data recursively.
  void flushInformative() {}

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    signature.addString(this._name ?? '');
    signature.addString(this._prefix ?? '');
    signature.addInt(this._offset ?? 0);
    signature.addInt(this._length ?? 0);
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_name;
    fb.Offset offset_prefix;
    if (_name != null) {
      offset_name = fbBuilder.writeString(_name);
    }
    if (_prefix != null) {
      offset_prefix = fbBuilder.writeString(_prefix);
    }
    fbBuilder.startTable();
    if (_length != null && _length != 0) {
      fbBuilder.addUint32(3, _length);
    }
    if (offset_name != null) {
      fbBuilder.addOffset(0, offset_name);
    }
    if (_offset != null && _offset != 0) {
      fbBuilder.addUint32(2, _offset);
    }
    if (offset_prefix != null) {
      fbBuilder.addOffset(1, offset_prefix);
    }
    return fbBuilder.endTable();
  }
}

class _SummarizedExportedIdentifierReader
    extends fb.TableReader<_SummarizedExportedIdentifierImpl> {
  const _SummarizedExportedIdentifierReader();

  @override
  _SummarizedExportedIdentifierImpl createObject(
          fb.BufferContext bc, int offset) =>
      _SummarizedExportedIdentifierImpl(bc, offset);
}

class _SummarizedExportedIdentifierImpl extends Object
    with _SummarizedExportedIdentifierMixin
    implements idl.SummarizedExportedIdentifier {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _SummarizedExportedIdentifierImpl(this._bc, this._bcOffset);

  int _length;
  String _name;
  int _offset;
  String _prefix;

  @override
  int get length {
    _length ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 3, 0);
    return _length;
  }

  @override
  String get name {
    _name ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 0, '');
    return _name;
  }

  @override
  int get offset {
    _offset ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 2, 0);
    return _offset;
  }

  @override
  String get prefix {
    _prefix ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 1, '');
    return _prefix;
  }
}

abstract class _SummarizedExportedIdentifierMixin
    implements idl.SummarizedExportedIdentifier {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (length != 0) _result["length"] = length;
    if (name != '') _result["name"] = name;
    if (offset != 0) _result["offset"] = offset;
    if (prefix != '') _result["prefix"] = prefix;
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "length": length,
        "name": name,
        "offset": offset,
        "prefix": prefix,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class SummarizedNgContentBuilder extends Object
    with _SummarizedNgContentMixin
    implements idl.SummarizedNgContent {
  int _length;
  int _offset;
  int _selectorOffset;
  String _selectorStr;

  @override
  int get length => _length ??= 0;

  set length(int value) {
    assert(value == null || value >= 0);
    this._length = value;
  }

  @override
  int get offset => _offset ??= 0;

  set offset(int value) {
    assert(value == null || value >= 0);
    this._offset = value;
  }

  @override
  int get selectorOffset => _selectorOffset ??= 0;

  set selectorOffset(int value) {
    assert(value == null || value >= 0);
    this._selectorOffset = value;
  }

  @override
  String get selectorStr => _selectorStr ??= '';

  set selectorStr(String value) {
    this._selectorStr = value;
  }

  SummarizedNgContentBuilder(
      {int length, int offset, int selectorOffset, String selectorStr})
      : _length = length,
        _offset = offset,
        _selectorOffset = selectorOffset,
        _selectorStr = selectorStr;

  /// Flush [informative] data recursively.
  void flushInformative() {}

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    signature.addInt(this._offset ?? 0);
    signature.addInt(this._length ?? 0);
    signature.addString(this._selectorStr ?? '');
    signature.addInt(this._selectorOffset ?? 0);
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_selectorStr;
    if (_selectorStr != null) {
      offset_selectorStr = fbBuilder.writeString(_selectorStr);
    }
    fbBuilder.startTable();
    if (_length != null && _length != 0) {
      fbBuilder.addUint32(1, _length);
    }
    if (_offset != null && _offset != 0) {
      fbBuilder.addUint32(0, _offset);
    }
    if (_selectorOffset != null && _selectorOffset != 0) {
      fbBuilder.addUint32(3, _selectorOffset);
    }
    if (offset_selectorStr != null) {
      fbBuilder.addOffset(2, offset_selectorStr);
    }
    return fbBuilder.endTable();
  }
}

class _SummarizedNgContentReader
    extends fb.TableReader<_SummarizedNgContentImpl> {
  const _SummarizedNgContentReader();

  @override
  _SummarizedNgContentImpl createObject(fb.BufferContext bc, int offset) =>
      _SummarizedNgContentImpl(bc, offset);
}

class _SummarizedNgContentImpl extends Object
    with _SummarizedNgContentMixin
    implements idl.SummarizedNgContent {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _SummarizedNgContentImpl(this._bc, this._bcOffset);

  int _length;
  int _offset;
  int _selectorOffset;
  String _selectorStr;

  @override
  int get length {
    _length ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 1, 0);
    return _length;
  }

  @override
  int get offset {
    _offset ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 0, 0);
    return _offset;
  }

  @override
  int get selectorOffset {
    _selectorOffset ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 3, 0);
    return _selectorOffset;
  }

  @override
  String get selectorStr {
    _selectorStr ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 2, '');
    return _selectorStr;
  }
}

abstract class _SummarizedNgContentMixin implements idl.SummarizedNgContent {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (length != 0) _result["length"] = length;
    if (offset != 0) _result["offset"] = offset;
    if (selectorOffset != 0) _result["selectorOffset"] = selectorOffset;
    if (selectorStr != '') _result["selectorStr"] = selectorStr;
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "length": length,
        "offset": offset,
        "selectorOffset": selectorOffset,
        "selectorStr": selectorStr,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class SummarizedPipeBuilder extends Object
    with _SummarizedPipeMixin
    implements idl.SummarizedPipe {
  String _decoratedClassName;
  bool _isPure;
  String _pipeName;
  int _pipeNameOffset;

  @override
  String get decoratedClassName => _decoratedClassName ??= '';

  set decoratedClassName(String value) {
    this._decoratedClassName = value;
  }

  @override
  bool get isPure => _isPure ??= false;

  set isPure(bool value) {
    this._isPure = value;
  }

  @override
  String get pipeName => _pipeName ??= '';

  set pipeName(String value) {
    this._pipeName = value;
  }

  @override
  int get pipeNameOffset => _pipeNameOffset ??= 0;

  set pipeNameOffset(int value) {
    assert(value == null || value >= 0);
    this._pipeNameOffset = value;
  }

  SummarizedPipeBuilder(
      {String decoratedClassName,
      bool isPure,
      String pipeName,
      int pipeNameOffset})
      : _decoratedClassName = decoratedClassName,
        _isPure = isPure,
        _pipeName = pipeName,
        _pipeNameOffset = pipeNameOffset;

  /// Flush [informative] data recursively.
  void flushInformative() {}

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    signature.addString(this._pipeName ?? '');
    signature.addInt(this._pipeNameOffset ?? 0);
    signature.addBool(this._isPure == true);
    signature.addString(this._decoratedClassName ?? '');
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_decoratedClassName;
    fb.Offset offset_pipeName;
    if (_decoratedClassName != null) {
      offset_decoratedClassName = fbBuilder.writeString(_decoratedClassName);
    }
    if (_pipeName != null) {
      offset_pipeName = fbBuilder.writeString(_pipeName);
    }
    fbBuilder.startTable();
    if (offset_decoratedClassName != null) {
      fbBuilder.addOffset(3, offset_decoratedClassName);
    }
    if (_isPure == true) {
      fbBuilder.addBool(2, true);
    }
    if (offset_pipeName != null) {
      fbBuilder.addOffset(0, offset_pipeName);
    }
    if (_pipeNameOffset != null && _pipeNameOffset != 0) {
      fbBuilder.addUint32(1, _pipeNameOffset);
    }
    return fbBuilder.endTable();
  }
}

class _SummarizedPipeReader extends fb.TableReader<_SummarizedPipeImpl> {
  const _SummarizedPipeReader();

  @override
  _SummarizedPipeImpl createObject(fb.BufferContext bc, int offset) =>
      _SummarizedPipeImpl(bc, offset);
}

class _SummarizedPipeImpl extends Object
    with _SummarizedPipeMixin
    implements idl.SummarizedPipe {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _SummarizedPipeImpl(this._bc, this._bcOffset);

  String _decoratedClassName;
  bool _isPure;
  String _pipeName;
  int _pipeNameOffset;

  @override
  String get decoratedClassName {
    _decoratedClassName ??=
        const fb.StringReader().vTableGet(_bc, _bcOffset, 3, '');
    return _decoratedClassName;
  }

  @override
  bool get isPure {
    _isPure ??= const fb.BoolReader().vTableGet(_bc, _bcOffset, 2, false);
    return _isPure;
  }

  @override
  String get pipeName {
    _pipeName ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 0, '');
    return _pipeName;
  }

  @override
  int get pipeNameOffset {
    _pipeNameOffset ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 1, 0);
    return _pipeNameOffset;
  }
}

abstract class _SummarizedPipeMixin implements idl.SummarizedPipe {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (decoratedClassName != '') {
      _result["decoratedClassName"] = decoratedClassName;
    }
    if (isPure != false) _result["isPure"] = isPure;
    if (pipeName != '') _result["pipeName"] = pipeName;
    if (pipeNameOffset != 0) _result["pipeNameOffset"] = pipeNameOffset;
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "decoratedClassName": decoratedClassName,
        "isPure": isPure,
        "pipeName": pipeName,
        "pipeNameOffset": pipeNameOffset,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class SummarizedPipesUseBuilder extends Object
    with _SummarizedPipesUseMixin
    implements idl.SummarizedPipesUse {
  int _length;
  String _name;
  int _offset;
  String _prefix;

  @override
  int get length => _length ??= 0;

  set length(int value) {
    assert(value == null || value >= 0);
    this._length = value;
  }

  @override
  String get name => _name ??= '';

  set name(String value) {
    this._name = value;
  }

  @override
  int get offset => _offset ??= 0;

  set offset(int value) {
    assert(value == null || value >= 0);
    this._offset = value;
  }

  @override
  String get prefix => _prefix ??= '';

  set prefix(String value) {
    this._prefix = value;
  }

  SummarizedPipesUseBuilder(
      {int length, String name, int offset, String prefix})
      : _length = length,
        _name = name,
        _offset = offset,
        _prefix = prefix;

  /// Flush [informative] data recursively.
  void flushInformative() {}

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    signature.addString(this._name ?? '');
    signature.addString(this._prefix ?? '');
    signature.addInt(this._offset ?? 0);
    signature.addInt(this._length ?? 0);
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_name;
    fb.Offset offset_prefix;
    if (_name != null) {
      offset_name = fbBuilder.writeString(_name);
    }
    if (_prefix != null) {
      offset_prefix = fbBuilder.writeString(_prefix);
    }
    fbBuilder.startTable();
    if (_length != null && _length != 0) {
      fbBuilder.addUint32(3, _length);
    }
    if (offset_name != null) {
      fbBuilder.addOffset(0, offset_name);
    }
    if (_offset != null && _offset != 0) {
      fbBuilder.addUint32(2, _offset);
    }
    if (offset_prefix != null) {
      fbBuilder.addOffset(1, offset_prefix);
    }
    return fbBuilder.endTable();
  }
}

class _SummarizedPipesUseReader
    extends fb.TableReader<_SummarizedPipesUseImpl> {
  const _SummarizedPipesUseReader();

  @override
  _SummarizedPipesUseImpl createObject(fb.BufferContext bc, int offset) =>
      _SummarizedPipesUseImpl(bc, offset);
}

class _SummarizedPipesUseImpl extends Object
    with _SummarizedPipesUseMixin
    implements idl.SummarizedPipesUse {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _SummarizedPipesUseImpl(this._bc, this._bcOffset);

  int _length;
  String _name;
  int _offset;
  String _prefix;

  @override
  int get length {
    _length ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 3, 0);
    return _length;
  }

  @override
  String get name {
    _name ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 0, '');
    return _name;
  }

  @override
  int get offset {
    _offset ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 2, 0);
    return _offset;
  }

  @override
  String get prefix {
    _prefix ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 1, '');
    return _prefix;
  }
}

abstract class _SummarizedPipesUseMixin implements idl.SummarizedPipesUse {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (length != 0) _result["length"] = length;
    if (name != '') _result["name"] = name;
    if (offset != 0) _result["offset"] = offset;
    if (prefix != '') _result["prefix"] = prefix;
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "length": length,
        "name": name,
        "offset": offset,
        "prefix": prefix,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class UnlinkedDartSummaryBuilder extends Object
    with _UnlinkedDartSummaryMixin
    implements idl.UnlinkedDartSummary {
  List<SummarizedClassAnnotationsBuilder> _annotatedClasses;
  List<SummarizedDirectiveBuilder> _directiveSummaries;
  List<SummarizedAnalysisErrorBuilder> _errors;
  List<SummarizedPipeBuilder> _pipeSummaries;

  @override
  List<SummarizedClassAnnotationsBuilder> get annotatedClasses =>
      _annotatedClasses ??= <SummarizedClassAnnotationsBuilder>[];

  set annotatedClasses(List<SummarizedClassAnnotationsBuilder> value) {
    this._annotatedClasses = value;
  }

  @override
  List<SummarizedDirectiveBuilder> get directiveSummaries =>
      _directiveSummaries ??= <SummarizedDirectiveBuilder>[];

  set directiveSummaries(List<SummarizedDirectiveBuilder> value) {
    this._directiveSummaries = value;
  }

  @override
  List<SummarizedAnalysisErrorBuilder> get errors =>
      _errors ??= <SummarizedAnalysisErrorBuilder>[];

  set errors(List<SummarizedAnalysisErrorBuilder> value) {
    this._errors = value;
  }

  @override
  List<SummarizedPipeBuilder> get pipeSummaries =>
      _pipeSummaries ??= <SummarizedPipeBuilder>[];

  set pipeSummaries(List<SummarizedPipeBuilder> value) {
    this._pipeSummaries = value;
  }

  UnlinkedDartSummaryBuilder(
      {List<SummarizedClassAnnotationsBuilder> annotatedClasses,
      List<SummarizedDirectiveBuilder> directiveSummaries,
      List<SummarizedAnalysisErrorBuilder> errors,
      List<SummarizedPipeBuilder> pipeSummaries})
      : _annotatedClasses = annotatedClasses,
        _directiveSummaries = directiveSummaries,
        _errors = errors,
        _pipeSummaries = pipeSummaries;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _annotatedClasses?.forEach((b) => b.flushInformative());
    _directiveSummaries?.forEach((b) => b.flushInformative());
    _errors?.forEach((b) => b.flushInformative());
    _pipeSummaries?.forEach((b) => b.flushInformative());
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    if (this._directiveSummaries == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._directiveSummaries.length);
      for (var x in this._directiveSummaries) {
        x?.collectApiSignature(signature);
      }
    }
    if (this._annotatedClasses == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._annotatedClasses.length);
      for (var x in this._annotatedClasses) {
        x?.collectApiSignature(signature);
      }
    }
    if (this._errors == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._errors.length);
      for (var x in this._errors) {
        x?.collectApiSignature(signature);
      }
    }
    if (this._pipeSummaries == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._pipeSummaries.length);
      for (var x in this._pipeSummaries) {
        x?.collectApiSignature(signature);
      }
    }
  }

  List<int> toBuffer() {
    fb.Builder fbBuilder = fb.Builder();
    return fbBuilder.finish(finish(fbBuilder), "APUD");
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_annotatedClasses;
    fb.Offset offset_directiveSummaries;
    fb.Offset offset_errors;
    fb.Offset offset_pipeSummaries;
    if (!(_annotatedClasses == null || _annotatedClasses.isEmpty)) {
      offset_annotatedClasses = fbBuilder.writeList(
          _annotatedClasses.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_directiveSummaries == null || _directiveSummaries.isEmpty)) {
      offset_directiveSummaries = fbBuilder.writeList(
          _directiveSummaries.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_errors == null || _errors.isEmpty)) {
      offset_errors =
          fbBuilder.writeList(_errors.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_pipeSummaries == null || _pipeSummaries.isEmpty)) {
      offset_pipeSummaries = fbBuilder
          .writeList(_pipeSummaries.map((b) => b.finish(fbBuilder)).toList());
    }
    fbBuilder.startTable();
    if (offset_annotatedClasses != null) {
      fbBuilder.addOffset(1, offset_annotatedClasses);
    }
    if (offset_directiveSummaries != null) {
      fbBuilder.addOffset(0, offset_directiveSummaries);
    }
    if (offset_errors != null) {
      fbBuilder.addOffset(2, offset_errors);
    }
    if (offset_pipeSummaries != null) {
      fbBuilder.addOffset(3, offset_pipeSummaries);
    }
    return fbBuilder.endTable();
  }
}

idl.UnlinkedDartSummary readUnlinkedDartSummary(List<int> buffer) {
  fb.BufferContext rootRef = fb.BufferContext.fromBytes(buffer);
  return const _UnlinkedDartSummaryReader().read(rootRef, 0);
}

class _UnlinkedDartSummaryReader
    extends fb.TableReader<_UnlinkedDartSummaryImpl> {
  const _UnlinkedDartSummaryReader();

  @override
  _UnlinkedDartSummaryImpl createObject(fb.BufferContext bc, int offset) =>
      _UnlinkedDartSummaryImpl(bc, offset);
}

class _UnlinkedDartSummaryImpl extends Object
    with _UnlinkedDartSummaryMixin
    implements idl.UnlinkedDartSummary {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _UnlinkedDartSummaryImpl(this._bc, this._bcOffset);

  List<idl.SummarizedClassAnnotations> _annotatedClasses;
  List<idl.SummarizedDirective> _directiveSummaries;
  List<idl.SummarizedAnalysisError> _errors;
  List<idl.SummarizedPipe> _pipeSummaries;

  @override
  List<idl.SummarizedClassAnnotations> get annotatedClasses {
    _annotatedClasses ??= const fb.ListReader<idl.SummarizedClassAnnotations>(
            _SummarizedClassAnnotationsReader())
        .vTableGet(_bc, _bcOffset, 1, const <idl.SummarizedClassAnnotations>[]);
    return _annotatedClasses;
  }

  @override
  List<idl.SummarizedDirective> get directiveSummaries {
    _directiveSummaries ??= const fb.ListReader<idl.SummarizedDirective>(
            _SummarizedDirectiveReader())
        .vTableGet(_bc, _bcOffset, 0, const <idl.SummarizedDirective>[]);
    return _directiveSummaries;
  }

  @override
  List<idl.SummarizedAnalysisError> get errors {
    _errors ??= const fb.ListReader<idl.SummarizedAnalysisError>(
            _SummarizedAnalysisErrorReader())
        .vTableGet(_bc, _bcOffset, 2, const <idl.SummarizedAnalysisError>[]);
    return _errors;
  }

  @override
  List<idl.SummarizedPipe> get pipeSummaries {
    _pipeSummaries ??=
        const fb.ListReader<idl.SummarizedPipe>(_SummarizedPipeReader())
            .vTableGet(_bc, _bcOffset, 3, const <idl.SummarizedPipe>[]);
    return _pipeSummaries;
  }
}

abstract class _UnlinkedDartSummaryMixin implements idl.UnlinkedDartSummary {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (annotatedClasses.isNotEmpty) {
      _result["annotatedClasses"] =
          annotatedClasses.map((_value) => _value.toJson()).toList();
    }
    if (directiveSummaries.isNotEmpty) {
      _result["directiveSummaries"] =
          directiveSummaries.map((_value) => _value.toJson()).toList();
    }
    if (errors.isNotEmpty) {
      _result["errors"] = errors.map((_value) => _value.toJson()).toList();
    }
    if (pipeSummaries.isNotEmpty) {
      _result["pipeSummaries"] =
          pipeSummaries.map((_value) => _value.toJson()).toList();
    }
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "annotatedClasses": annotatedClasses,
        "directiveSummaries": directiveSummaries,
        "errors": errors,
        "pipeSummaries": pipeSummaries,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class UnlinkedHtmlSummaryBuilder extends Object
    with _UnlinkedHtmlSummaryMixin
    implements idl.UnlinkedHtmlSummary {
  List<SummarizedNgContentBuilder> _ngContents;

  @override
  List<SummarizedNgContentBuilder> get ngContents =>
      _ngContents ??= <SummarizedNgContentBuilder>[];

  set ngContents(List<SummarizedNgContentBuilder> value) {
    this._ngContents = value;
  }

  UnlinkedHtmlSummaryBuilder({List<SummarizedNgContentBuilder> ngContents})
      : _ngContents = ngContents;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _ngContents?.forEach((b) => b.flushInformative());
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signature) {
    if (this._ngContents == null) {
      signature.addInt(0);
    } else {
      signature.addInt(this._ngContents.length);
      for (var x in this._ngContents) {
        x?.collectApiSignature(signature);
      }
    }
  }

  List<int> toBuffer() {
    fb.Builder fbBuilder = fb.Builder();
    return fbBuilder.finish(finish(fbBuilder), "APUH");
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset offset_ngContents;
    if (!(_ngContents == null || _ngContents.isEmpty)) {
      offset_ngContents = fbBuilder
          .writeList(_ngContents.map((b) => b.finish(fbBuilder)).toList());
    }
    fbBuilder.startTable();
    if (offset_ngContents != null) {
      fbBuilder.addOffset(0, offset_ngContents);
    }
    return fbBuilder.endTable();
  }
}

idl.UnlinkedHtmlSummary readUnlinkedHtmlSummary(List<int> buffer) {
  fb.BufferContext rootRef = fb.BufferContext.fromBytes(buffer);
  return const _UnlinkedHtmlSummaryReader().read(rootRef, 0);
}

class _UnlinkedHtmlSummaryReader
    extends fb.TableReader<_UnlinkedHtmlSummaryImpl> {
  const _UnlinkedHtmlSummaryReader();

  @override
  _UnlinkedHtmlSummaryImpl createObject(fb.BufferContext bc, int offset) =>
      _UnlinkedHtmlSummaryImpl(bc, offset);
}

class _UnlinkedHtmlSummaryImpl extends Object
    with _UnlinkedHtmlSummaryMixin
    implements idl.UnlinkedHtmlSummary {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _UnlinkedHtmlSummaryImpl(this._bc, this._bcOffset);

  List<idl.SummarizedNgContent> _ngContents;

  @override
  List<idl.SummarizedNgContent> get ngContents {
    _ngContents ??= const fb.ListReader<idl.SummarizedNgContent>(
            _SummarizedNgContentReader())
        .vTableGet(_bc, _bcOffset, 0, const <idl.SummarizedNgContent>[]);
    return _ngContents;
  }
}

abstract class _UnlinkedHtmlSummaryMixin implements idl.UnlinkedHtmlSummary {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> _result = <String, Object>{};
    if (ngContents.isNotEmpty) {
      _result["ngContents"] =
          ngContents.map((_value) => _value.toJson()).toList();
    }
    return _result;
  }

  @override
  Map<String, Object> toMap() => {
        "ngContents": ngContents,
      };

  @override
  String toString() => convert.json.encode(toJson());
}
