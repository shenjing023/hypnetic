class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int? code;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.code,
  });

  factory ApiResponse.fromJson(
      Map<String, dynamic> json, T Function(dynamic) fromJson) {
    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      data: json['data'] != null ? fromJson(json['data']) : null,
      message: json['message'] as String?,
      code: json['code'] as int?,
    );
  }

  factory ApiResponse.success(T data) {
    return ApiResponse<T>(
      success: true,
      data: data,
    );
  }

  factory ApiResponse.error(String message, {int? code}) {
    return ApiResponse<T>(
      success: false,
      message: message,
      code: code,
    );
  }
}
