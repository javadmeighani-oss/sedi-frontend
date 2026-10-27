import '../network/api_client.dart';
import '../network/api_response.dart';
import 'memory_overview.dart';

/// Client of the I7 "my memory" API (R-021 / M1): see, correct and forget what Sedi remembers.
///
/// GET    /memory/overview
/// PATCH  /memory/facts/{id}        {value}
/// DELETE /memory/facts/{id}
/// POST   /memory/events            {kind, summary}
/// PATCH  /memory/events/{id}       {summary}
/// DELETE /memory/events/{id}
class MemoryOverviewService {
  MemoryOverviewService({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<ApiResponse<MemoryOverview>> fetch() {
    return _api.get<MemoryOverview>(
      '/memory/overview',
      parser: MemoryOverview.tryParse,
    );
  }

  Future<ApiResponse<bool>> editFact(int id, String value) {
    return _api.patch<bool>(
      '/memory/facts/$id',
      body: {'value': value},
      parser: (d) => d is Map,
    );
  }

  Future<ApiResponse<bool>> deleteFact(int id) {
    return _api.delete<bool>(
      '/memory/facts/$id',
      parser: (d) => d is Map && d['deleted'] == true,
    );
  }

  Future<ApiResponse<bool>> addEvent(String summary, {String kind = 'other'}) {
    return _api.post<bool>(
      '/memory/events',
      body: {'kind': kind, 'summary': summary, 'subject': 'self'},
      parser: (d) => d is Map,
    );
  }

  Future<ApiResponse<bool>> editEvent(int id, String summary) {
    return _api.patch<bool>(
      '/memory/events/$id',
      body: {'summary': summary},
      parser: (d) => d is Map,
    );
  }

  Future<ApiResponse<bool>> deleteEvent(int id) {
    return _api.delete<bool>(
      '/memory/events/$id',
      parser: (d) => d is Map && d['deleted'] == true,
    );
  }
}
