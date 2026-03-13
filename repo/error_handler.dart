/**
 * Error Handler
 * 
 * Xử lý lỗi toàn cầu cho ứng dụng
 * Centralize error handling, logging, và user notifications
 */

import 'package:flutter/material.dart';

/// Custom exception classes
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalException;
  final StackTrace? stackTrace;

  AppException({
    required this.message,
    this.code,
    this.originalException,
    this.stackTrace,
  });

  @override
  String toString() => 'AppException: $message';
}

class NetworkException extends AppException {
  NetworkException({
    required String message,
    String? code,
    dynamic originalException,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    code: code ?? 'NETWORK_ERROR',
    originalException: originalException,
    stackTrace: stackTrace,
  );
}

class ServerException extends AppException {
  final int? statusCode;

  ServerException({
    required String message,
    this.statusCode,
    String? code,
    dynamic originalException,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    code: code ?? 'SERVER_ERROR',
    originalException: originalException,
    stackTrace: stackTrace,
  );
}

class ValidationException extends AppException {
  final Map<String, String>? errors;

  ValidationException({
    required String message,
    this.errors,
    String? code,
    dynamic originalException,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    code: code ?? 'VALIDATION_ERROR',
    originalException: originalException,
    stackTrace: stackTrace,
  );
}

class UnauthorizedException extends AppException {
  UnauthorizedException({
    required String message,
    String? code,
    dynamic originalException,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    code: code ?? 'UNAUTHORIZED',
    originalException: originalException,
    stackTrace: stackTrace,
  );
}

class CacheException extends AppException {
  CacheException({
    required String message,
    String? code,
    dynamic originalException,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    code: code ?? 'CACHE_ERROR',
    originalException: originalException,
    stackTrace: stackTrace,
  );
}

/// Error handler service
class ErrorHandlerService {
  static final ErrorHandlerService _instance = ErrorHandlerService._internal();

  factory ErrorHandlerService() {
    return _instance;
  }

  ErrorHandlerService._internal();

  /// Handle error dan return user-friendly message
  String getErrorMessage(dynamic error) {
    if (error is AppException) {
      return error.message;
    } else if (error is NetworkException) {
      return 'Lỗi kết nối mạng. Vui lòng kiểm tra kết nối của bạn.';
    } else if (error is ServerException) {
      if (error.statusCode == 401) {
        return 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.';
      } else if (error.statusCode == 403) {
        return 'Bạn không có quyền thực hiện hành động này.';
      } else if (error.statusCode == 404) {
        return 'Dữ liệu không được tìm thấy.';
      } else if (error.statusCode == 500) {
        return 'Lỗi máy chủ. Vui lòng thử lại sau.';
      }
      return error.message;
    } else if (error is ValidationException) {
      return error.message;
    } else if (error is UnauthorizedException) {
      return 'Bạn cần đăng nhập để tiếp tục.';
    } else if (error is CacheException) {
      return 'Lỗi lưu trữ dữ liệu. Vui lòng thử lại.';
    }

    return 'Đã xảy ra lỗi không xác định. Vui lòng thử lại.';
  }

  /// Log error (có thể extend để gửi đến service theo dõi)
  void logError(
    dynamic error, {
    StackTrace? stackTrace,
    String? tag,
  }) {
    print('[$tag] Error: $error');
    if (stackTrace != null) {
      print('StackTrace: $stackTrace');
    }
  }

  /// Show error snackbar
  void showErrorSnackBar(
    BuildContext context,
    dynamic error, {
    Duration duration = const Duration(seconds: 3),
  }) {
    final message = getErrorMessage(error);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: duration,
        action: SnackBarAction(
          label: 'Đóng',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show error dialog
  Future<void> showErrorDialog(
    BuildContext context,
    dynamic error, {
    String title = 'Lỗi',
  }) {
    final message = getErrorMessage(error);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Retry logic with exponential backoff
  Future<T> retryWithBackoff<T>(
    Future<T> Function() fn, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(milliseconds: 100),
  }) async {
    int attempt = 0;

    while (attempt < maxRetries) {
      try {
        return await fn();
      } catch (e) {
        attempt++;

        if (attempt >= maxRetries) {
          rethrow;
        }

        // Exponential backoff: 100ms, 200ms, 400ms, ...
        final delay = initialDelay * (pow(2, attempt - 1) as int);
        await Future.delayed(delay);
      }
    }

    throw Exception('Max retries exceeded');
  }
}

double pow(double base, int exponent) {
  return base * pow(base, exponent - 1);
}
