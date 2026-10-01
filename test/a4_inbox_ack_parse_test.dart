import 'package:flutter_test/flutter_test.dart';

import 'package:sedi_app/core/auth/user_identity_service.dart';
import 'package:sedi_app/core/network/api_client.dart';
import 'package:sedi_app/core/network/api_error.dart';
import 'package:sedi_app/core/network/api_response.dart';
import 'package:sedi_app/services/notifications/notifications_service.dart';

class _StubApiClient extends ApiClient {
  _StubApiClient(this._postHandler) : super(baseUrl: 'http://stub.test');

  final Future<ApiResponse<Map<String, dynamic>>> Function(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) _postHandler;

  @override
  Future<ApiResponse<T>> post<T>(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    Map<String, String>? extraHeaders,
    String? accessToken,
    bool recoverSessionOn401 = true,
    required T? Function(Object? dataJson) parser,
  }) async {
    final stub = await _postHandler(
      path,
      body: body,
      queryParams: queryParams,
    );
    if (!stub.ok) {
      return ApiResponse<T>(
        ok: false,
        error: stub.error,
        statusCode: stub.statusCode,
      );
    }
    final parsed = parser(stub.data);
    if (parsed == null) {
      return ApiResponse<T>(
        ok: false,
        error: const ApiError(
          code: 'PARSE_ERROR',
          message: 'Failed to parse success payload',
        ),
        statusCode: stub.statusCode,
      );
    }
    return ApiResponse<T>(
      ok: true,
      data: parsed,
      statusCode: stub.statusCode,
    );
  }
}

void main() {
  setUp(() {
    UserIdentityService.debugSetCachedUserId(1);
  });

  tearDown(() {
    UserIdentityService.debugSetCachedUserId(null);
  });

  group('inbox ACK envelope parsing', () {
    test('hide success payload ok=true (not PARSE_ERROR)', () {
      final envelope = ApiResponse.fromJson<Map<String, dynamic>>(
        {
          'ok': true,
          'data': {
            'hidden_ids': [1],
            'newly_hidden': 1,
            'already_hidden': 0,
          },
          'error': null,
        },
        NotificationsService.parseAckData,
      );
      expect(envelope.ok, isTrue);
      expect(envelope.error, isNull);
      expect(envelope.data?['newly_hidden'], 1);
    });

    test('mark-read success payload ok=true (not PARSE_ERROR)', () {
      final envelope = ApiResponse.fromJson<Map<String, dynamic>>(
        {
          'ok': true,
          'data': {
            'ok': true,
            'notification_id': 1,
            'is_read': true,
          },
          'error': null,
        },
        NotificationsService.parseAckData,
      );
      expect(envelope.ok, isTrue);
      expect(envelope.error, isNull);
      expect(envelope.data?['is_read'], isTrue);
    });

    test('legacy null parser on success payload yields PARSE_ERROR', () {
      final broken = ApiResponse.fromJson<Map<String, dynamic>>(
        {
          'ok': true,
          'data': {'hidden_ids': [1]},
          'error': null,
        },
        (_) => null,
      );
      expect(broken.ok, isFalse);
      expect(broken.error?.code, 'PARSE_ERROR');
    });

    test('backend ok=false remains ok=false', () {
      final envelope = ApiResponse.fromJson<Map<String, dynamic>>(
        {
          'ok': false,
          'data': null,
          'error': {'code': 'HIDE_FAILED', 'message': 'denied'},
        },
        NotificationsService.parseAckData,
      );
      expect(envelope.ok, isFalse);
      expect(envelope.error?.code, 'HIDE_FAILED');
    });
  });

  group('NotificationsService hideInbox/markRead', () {
    test('hideInbox returns ok=true on successful hide ACK', () async {
      final service = NotificationsService(
        apiClient: _StubApiClient((path, {body, queryParams}) async {
          expect(path, '/notifications/inbox/hide');
          return ApiResponse<Map<String, dynamic>>(
            ok: true,
            data: {
              'hidden_ids': [1],
              'newly_hidden': 1,
              'already_hidden': 0,
            },
            statusCode: 200,
          );
        }),
      );

      final result = await service.hideInbox([1]);
      expect(result.ok, isTrue);
      expect(result.error, isNull);
    });

    test('markRead returns ok=true on successful mark-read ACK', () async {
      final service = NotificationsService(
        apiClient: _StubApiClient((path, {body, queryParams}) async {
          expect(path, '/notifications/1/mark-read');
          expect(queryParams?['user_id'], '1');
          return ApiResponse<Map<String, dynamic>>(
            ok: true,
            data: {
              'ok': true,
              'notification_id': 1,
              'is_read': true,
            },
            statusCode: 200,
          );
        }),
      );

      final result = await service.markRead(1);
      expect(result.ok, isTrue);
      expect(result.error, isNull);
    });

    test('hideInbox propagates backend failure', () async {
      final service = NotificationsService(
        apiClient: _StubApiClient((path, {body, queryParams}) async {
          return const ApiResponse<Map<String, dynamic>>(
            ok: false,
            error: ApiError(code: 'HIDE_FAILED', message: 'denied'),
            statusCode: 403,
          );
        }),
      );

      final result = await service.hideInbox([2]);
      expect(result.ok, isFalse);
      expect(result.error?.code, 'HIDE_FAILED');
    });
  });
}
