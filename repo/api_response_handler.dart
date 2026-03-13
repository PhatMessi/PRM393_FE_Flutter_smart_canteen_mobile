/**
 * API Response Handler
 * 
 * Xử lý tập hợp các response từ API
 * Cung cấp unified way để handle responses từ các service khác nhau
 */

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int? statusCode;
  final dynamic error;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
    this.error,
  });

  /// Factory constructor cho successful response
  factory ApiResponse.success(T data, {String? message, int? statusCode}) {
    return ApiResponse(
      success: true,
      data: data,
      message: message ?? 'Success',
      statusCode: statusCode ?? 200,
    );
  }

  /// Factory constructor cho failed response
  factory ApiResponse.failure(
    String message, {
    int? statusCode,
    dynamic error,
  }) {
    return ApiResponse(
      success: false,
      message: message,
      statusCode: statusCode ?? 400,
      error: error,
    );
  }

  /// Factory constructor cho error response
  factory ApiResponse.error(dynamic error, {String? message, int? statusCode}) {
    return ApiResponse(
      success: false,
      message: message ?? 'An error occurred',
      statusCode: statusCode ?? 500,
      error: error,
    );
  }

  @override
  String toString() =>
      'ApiResponse(success: $success, statusCode: $statusCode, message: $message)';
}

/// Base service class với error handling
abstract class BaseService {
  /// Wrap API calls với try-catch và response handling
  Future<ApiResponse<T>> makeRequest<T>(
    Future<T> Function() request,
  ) async {
    try {
      final data = await request();
      return ApiResponse.success(data);
    } catch (e) {
      return ApiResponse.error(e, message: 'Request failed: ${e.toString()}');
    }
  }

  /// Handle response với custom mapper
  Future<ApiResponse<T>> makeRequestWithMapper<R, T>(
    Future<R> Function() request,
    T Function(R) mapper,
  ) async {
    try {
      final response = await request();
      final data = mapper(response);
      return ApiResponse.success(data);
    } catch (e) {
      return ApiResponse.error(e, message: 'Request failed: ${e.toString()}');
    }
  }
}
