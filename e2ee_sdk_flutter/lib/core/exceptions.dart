import 'package:flutter/services.dart';

class KKException implements PlatformException {
  final String _message;
  final String _errorCode;
  final dynamic _details;
  final String? _stackTrace;

  KKException(this._message, this._errorCode, this._details, this._stackTrace);

  @override
  String toString() {
    return _message;
  }

  @override
  String get code {
    return _errorCode;
  }

  @override
  get details {
    return _details;
  }

  @override
  String? get message {
    return _message;
  }

  @override
  String? get stacktrace {
    return _stackTrace;
  }
}
