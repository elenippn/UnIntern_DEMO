import 'package:dio/dio.dart';

String friendlyApiError(Object error) {
  if (error is DioException) {
    final status = error.response?.statusCode;
    if (status == 401) return 'Session expired. Please sign in again.';
    if (status == 403) return 'You are not allowed to do that.';
    if (status == 404) return 'Item not found (404).';
    if (status != null) return 'Request failed ($status). Please retry.';
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'Network timeout. Please retry.';
    }
    return 'Network error. Please retry.';
  }

  return 'Something went wrong. Please retry.';
}
