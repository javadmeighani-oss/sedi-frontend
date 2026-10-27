import '../network/api_client.dart';
import '../network/api_response.dart';
import 'memory_attachment.dart';

/// Client of the I7 attachment endpoints (R-021 / M4). The backend answers 404 FEATURE_DISABLED until its flag is on.
///
/// POST   /memory/attachments                 (multipart, field "file")
/// POST   /memory/attachments/{id}/process    (document: read; voice: transcribe)
/// POST   /memory/attachments/{id}/confirm    (the user says "remember this")
/// DELETE /memory/attachments/{id}
class MemoryAttachmentsService {
  MemoryAttachmentsService({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<ApiResponse<MemoryAttachment>> upload({
    required List<int> bytes,
    required String filename,
    required String mimeType,
  }) {
    return _api.postMultipart<MemoryAttachment>(
      '/memory/attachments',
      fieldName: 'file',
      bytes: bytes,
      filename: filename,
      contentType: mimeType,
      parser: MemoryAttachment.tryParse,
    );
  }

  Future<ApiResponse<MemoryAttachment>> process(int id) {
    return _api.postLongRunning<MemoryAttachment>(
      '/memory/attachments/$id/process',
      parser: MemoryAttachment.tryParse,
    );
  }

  Future<ApiResponse<MemoryAttachment>> confirm(int id) {
    return _api.post<MemoryAttachment>(
      '/memory/attachments/$id/confirm',
      parser: MemoryAttachment.tryParse,
    );
  }

  Future<ApiResponse<bool>> delete(int id) {
    return _api.delete<bool>(
      '/memory/attachments/$id',
      parser: (d) => d is Map && d['deleted'] == true,
    );
  }
}
