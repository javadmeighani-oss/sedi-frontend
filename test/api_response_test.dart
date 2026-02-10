import 'package:flutter_test/flutter_test.dart';

import 'package:sedi_app/core/network/api_error.dart';
import 'package:sedi_app/core/network/api_response.dart';

void main() {
  group('ApiError', () {
    test('fromJson with code and message', () {
      final e = ApiError.fromJson({'code': 'ERR_1', 'message': 'Failed'});
      expect(e.code, 'ERR_1');
      expect(e.message, 'Failed');
    });

    test('fromJson message only', () {
      final e = ApiError.fromJson({'message': 'Unknown'});
      expect(e.code, isNull);
      expect(e.message, 'Unknown');
    });

    test('fromJson null returns default message', () {
      final e = ApiError.fromJson(null);
      expect(e.message, 'Unknown error');
    });
  });

  group('ApiResponse.fromJson', () {
    test('success with data', () {
      final r = ApiResponse.fromJson<int>(
        {'ok': true, 'data': 42, 'error': null},
        (v) => v as int,
      );
      expect(r.ok, isTrue);
      expect(r.data, 42);
      expect(r.error, isNull);
      expect(r.isSuccess, isTrue);
    });

    test('success with map data', () {
      final r = ApiResponse.fromJson<Map<String, dynamic>>(
        {
          'ok': true,
          'data': {'key': 'value'},
          'error': null,
        },
        (v) => v == null ? null : Map<String, dynamic>.from(v as Map),
      );
      expect(r.ok, isTrue);
      expect(r.data!['key'], 'value');
      expect(r.error, isNull);
    });

    test('failure with error', () {
      final r = ApiResponse.fromJson<String>(
        {
          'ok': false,
          'data': null,
          'error': {'code': 'VALIDATION', 'message': 'Invalid input'},
        },
        (v) => v as String?,
      );
      expect(r.ok, isFalse);
      expect(r.data, isNull);
      expect(r.error?.code, 'VALIDATION');
      expect(r.error?.message, 'Invalid input');
      expect(r.errorMessage, 'Invalid input');
    });

    test('parser throws leaves data null', () {
      final r = ApiResponse.fromJson<int>(
        {'ok': true, 'data': 'not_an_int', 'error': null},
        (v) => v as int,
      );
      expect(r.ok, isTrue);
      expect(r.data, isNull);
    });
  });
}
