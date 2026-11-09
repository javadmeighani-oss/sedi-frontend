import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/core/network/api_response.dart';

void main() {
  // Javad 2026-11-09: adding / deleting in My Schedule showed "could not save" although the server had saved,
  // because a parser returning null turns a successful envelope with a data object into PARSE_ERROR.
  test('an ack parser keeps a successful create/patch/delete successful', () {
    final json = <String, dynamic>{
      'ok': true,
      'data': {'id': 7, 'deleted': true},
    };
    final r = ApiResponse.fromJson<void>(json, ackParser);
    expect(r.ok, isTrue);
    expect(r.error, isNull);
  });

  test('a null parser is what used to fail (guards the reason for ackParser)', () {
    final json = <String, dynamic>{
      'ok': true,
      'data': {'id': 7},
    };
    final r = ApiResponse.fromJson<void>(json, (_) => null);
    expect(r.ok, isFalse);
  });

  test('a real server refusal stays a failure with the ack parser', () {
    final json = <String, dynamic>{
      'ok': false,
      'error': {'code': 'X', 'message': 'no'},
    };
    expect(ApiResponse.fromJson<void>(json, ackParser).ok, isFalse);
  });
}
