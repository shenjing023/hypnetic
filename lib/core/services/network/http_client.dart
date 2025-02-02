import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'network_state.dart';

class HttpClient {
  static final HttpClient instance = HttpClient._();
  final Dio _dio = Dio();

  HttpClient._() {
    _initializeDio();
  }

  void _initializeDio() {
    // 基础配置
    _dio.options = BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      // 可以设置通用的 baseUrl
      // baseUrl: 'https://api.example.com',
    );

    // 拦截器配置
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );

    // 在调试模式下打印请求日志
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
      ));
    }
  }

  void _onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!NetworkState.instance.isConnected) {
      return handler.reject(
        DioException(
          requestOptions: options,
          error: '网络连接不可用',
          type: DioExceptionType.unknown,
        ),
      );
    }

    // 添加通用请求头
    options.headers.addAll({
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    });

    return handler.next(options);
  }

  void _onResponse(Response response, ResponseInterceptorHandler handler) {
    // 这里可以对响应数据进行统一处理
    return handler.next(response);
  }

  Future<void> _onError(
      DioException err, ErrorInterceptorHandler handler) async {
    // 统一错误处理
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        err = DioException(
          requestOptions: err.requestOptions,
          error: '请求超时',
          type: err.type,
        );
        break;
      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        String message;
        switch (statusCode) {
          case 400:
            message = '请求参数错误';
            break;
          case 401:
            message = '未授权';
            break;
          case 403:
            message = '访问被拒绝';
            break;
          case 404:
            message = '请求资源不存在';
            break;
          case 500:
            message = '服务器内部错误';
            break;
          case 502:
            message = '网关错误';
            break;
          case 503:
            message = '服务不可用';
            break;
          case 504:
            message = '网关超时';
            break;
          default:
            message = '未知错误';
        }
        err = DioException(
          requestOptions: err.requestOptions,
          error: message,
          type: err.type,
          response: err.response,
        );
        break;
      default:
        err = DioException(
          requestOptions: err.requestOptions,
          error: '网络请求失败',
          type: err.type,
          response: err.response,
        );
    }

    return handler.next(err);
  }

  // GET 请求
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // POST 请求
  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 下载文件
  Future<String> download(
    String url,
    String savePath, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Function(int received, int total)? onReceiveProgress,
    Options? options,
  }) async {
    try {
      await _dio.download(
        url,
        savePath,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
        options: options,
      );
      return savePath;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    return Exception(e.error ?? '请求失败');
  }

  // 取消请求
  void cancelRequests(CancelToken token) {
    token.cancel('用户取消请求');
  }
}
