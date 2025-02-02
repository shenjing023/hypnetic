/// 应用错误类型
enum AppErrorType {
  network('网络错误'),
  server('服务器错误'),
  parse('解析错误'),
  business('业务错误'),
  unknown('未知错误');

  final String message;
  const AppErrorType(this.message);
}

/// 应用错误类
class AppError implements Exception {
  final AppErrorType type;
  final String message;
  final dynamic originalError;
  final StackTrace? stackTrace;

  AppError({
    required this.type,
    required this.message,
    this.originalError,
    this.stackTrace,
  });

  factory AppError.network(String message,
      [dynamic error, StackTrace? stackTrace]) {
    return AppError(
      type: AppErrorType.network,
      message: message,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  factory AppError.server(String message,
      [dynamic error, StackTrace? stackTrace]) {
    return AppError(
      type: AppErrorType.server,
      message: message,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  factory AppError.parse(String message,
      [dynamic error, StackTrace? stackTrace]) {
    return AppError(
      type: AppErrorType.parse,
      message: message,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  factory AppError.business(String message,
      [dynamic error, StackTrace? stackTrace]) {
    return AppError(
      type: AppErrorType.business,
      message: message,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  factory AppError.unknown(String message,
      [dynamic error, StackTrace? stackTrace]) {
    return AppError(
      type: AppErrorType.unknown,
      message: message,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  @override
  String toString() => '${type.message}: $message';
}

/// 错误处理工具类
class ErrorHandler {
  static AppError handle(dynamic error, [StackTrace? stackTrace]) {
    if (error is AppError) return error;

    if (error is Exception) {
      // 处理网络错误
      if (error.toString().contains('SocketException') ||
          error.toString().contains('TimeoutException')) {
        return AppError.network('网络连接失败，请检查网络设置', error, stackTrace);
      }

      // 处理服务器错误
      if (error.toString().contains('HttpException')) {
        return AppError.server('服务器响应错误', error, stackTrace);
      }

      // 处理解析错误
      if (error.toString().contains('FormatException')) {
        return AppError.parse('数据格式错误', error, stackTrace);
      }
    }

    // 未知错误
    return AppError.unknown(error.toString(), error, stackTrace);
  }
}
