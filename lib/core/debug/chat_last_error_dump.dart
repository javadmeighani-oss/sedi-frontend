/// In-memory last chat error summary for quick copy during testing.
/// Not persisted. No secrets/tokens stored.

class ChatLastErrorDump {
  static String? _endpoint;
  static List<String>? _payloadKeys;
  static String? _responseMessage;
  static int? _statusCode;
  static DateTime? _at;

  static void set({
    required String endpoint,
    required List<String> payloadKeys,
    String? responseMessage,
    int? statusCode,
  }) {
    _endpoint = endpoint;
    _payloadKeys = List.from(payloadKeys);
    _responseMessage = responseMessage;
    _statusCode = statusCode;
    _at = DateTime.now();
  }

  static void clear() {
    _endpoint = null;
    _payloadKeys = null;
    _responseMessage = null;
    _statusCode = null;
    _at = null;
  }

  static String? get endpoint => _endpoint;
  static List<String>? get payloadKeys => _payloadKeys != null ? List.unmodifiable(_payloadKeys!) : null;
  static String? get responseMessage => _responseMessage;
  static int? get statusCode => _statusCode;
  static DateTime? get at => _at;

  /// One-line summary for logs; empty if no dump.
  static String get summary {
    if (_endpoint == null) return '';
    final keys = _payloadKeys?.join(', ') ?? '';
    final msg = _responseMessage ?? '';
    final status = _statusCode ?? 0;
    return '[$_at] $status $_endpoint payload_keys=[$keys] response=$msg';
  }
}
