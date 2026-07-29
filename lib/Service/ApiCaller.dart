// ignore_for_file: file_names

import 'dart:async';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';

typedef JsonMap = Map<String, dynamic>;
typedef TokenProvider = FutureOr<String?> Function();
typedef RefreshTokenCallback = FutureOr<bool> Function();
typedef UnauthorizedCallback = FutureOr<void> Function();

enum ApiMethod { get, post, put, patch, delete }

class ApiResponse<T> {
  const ApiResponse({
    required this.statusCode,
    required this.data,
    this.message,
    this.headers,
  });

  final int? statusCode;
  final T data;
  final String? message;
  final Headers? headers;

  bool get isSuccess =>
      statusCode != null && statusCode! >= 200 && statusCode! < 300;
}

class BaseResponse<T> {
  const BaseResponse({
    required this.data,
    this.success = true,
    this.message,
    this.code,
    this.raw,
  });

  final T data;
  final bool success;
  final String? message;
  final String? code;
  final Object? raw;

  factory BaseResponse.fromJson(
    Object? json, {
    T Function(Object? data)? decoder,
  }) {
    if (json is! Map) {
      return BaseResponse<T>(data: _decodeData<T>(json, decoder), raw: json);
    }

    final data = json['data'];
    return BaseResponse<T>(
      data: _decodeData<T>(data, decoder),
      success: _extractSuccess(json),
      message: _extractString(json, const ['message', 'error', 'detail']),
      code: _extractString(json, const ['code', 'error_code', 'statusCode']),
      raw: json,
    );
  }

  static T _decodeData<T>(Object? data, T Function(Object? data)? decoder) {
    if (decoder != null) {
      return decoder(data);
    }
    if (data is T) {
      return data;
    }
    if (data == null) {
      return null as T;
    }
    throw ApiException(
      message:
          'BaseResponse data type mismatch. Provide a decoder for ${T.toString()}.',
      data: data,
      code: 'decode_error',
    );
  }

  static bool _extractSuccess(Map<dynamic, dynamic> json) {
    final value = json['success'] ?? json['isSuccess'] ?? json['status'];
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.toLowerCase();
      return normalized == 'success' ||
          normalized == 'true' ||
          normalized == 'ok';
    }
    return true;
  }

  static String? _extractString(Map<dynamic, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null) {
        return value.toString();
      }
    }
    return null;
  }
}

class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.data,
    this.stackTrace,
  });

  final String message;
  final int? statusCode;
  final String? code;
  final Object? data;
  final StackTrace? stackTrace;

  @override
  String toString() {
    final status = statusCode == null ? '' : ' [$statusCode]';
    final errorCode = code == null ? '' : ' ($code)';
    return 'ApiException$status$errorCode: $message';
  }
}

class ApiCaller {
  static const String appVersionHeader = 'X-App-Version';
  static const String defaultAppVersion = '1.0.0';

  ApiCaller._({
    required Dio dio,
    TokenProvider? tokenProvider,
    RefreshTokenCallback? refreshToken,
    UnauthorizedCallback? onUnauthorized,
  }) : _dio = dio,
       _tokenProvider = tokenProvider,
       _refreshToken = refreshToken,
       _onUnauthorized = onUnauthorized;

  static ApiCaller? _instance;

  factory ApiCaller.getInstance() {
    final instance = _instance;
    if (instance == null) {
      throw StateError(
        'ApiCaller is not configured. Call ApiCaller.configure(...) when the app starts.',
      );
    }
    return instance;
  }

  static ApiCaller _createInstance({
    required String baseUrl,
    Dio? dio,
    TokenProvider? tokenProvider,
    RefreshTokenCallback? refreshToken,
    UnauthorizedCallback? onUnauthorized,
    Duration connectTimeout = const Duration(seconds: 20),
    Duration receiveTimeout = const Duration(seconds: 30),
    Duration sendTimeout = const Duration(seconds: 30),
    bool enableLogging = false,
    Map<String, String>? defaultHeaders,
  }) {
    final client = dio ?? Dio();
    _configureDio(
      dio: client,
      baseUrl: baseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      sendTimeout: sendTimeout,
      defaultHeaders: defaultHeaders,
    );

    final apiCaller = ApiCaller._(
      dio: client,
      tokenProvider: tokenProvider,
      refreshToken: refreshToken,
      onUnauthorized: onUnauthorized,
    );

    client.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final skipAuth = options.extra['skipAuth'] == true;
          final token = skipAuth
              ? null
              : await apiCaller._tokenProvider?.call();
          if (!skipAuth && token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await apiCaller._onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );

    if (enableLogging) {
      client.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (object) =>
              developer.log(object.toString(), name: 'ApiCaller'),
        ),
      );
    }

    _instance = apiCaller;
    return _instance!;
  }

  final Dio _dio;
  TokenProvider? _tokenProvider;
  RefreshTokenCallback? _refreshToken;
  UnauthorizedCallback? _onUnauthorized;
  Future<bool>? _refreshTokenFuture;

  Dio get client => _dio;

  static void configure({
    required String baseUrl,
    TokenProvider? tokenProvider,
    RefreshTokenCallback? refreshToken,
    UnauthorizedCallback? onUnauthorized,
    Duration connectTimeout = const Duration(seconds: 20),
    Duration receiveTimeout = const Duration(seconds: 30),
    Duration sendTimeout = const Duration(seconds: 30),
    bool enableLogging = false,
    Map<String, String>? defaultHeaders,
    bool forceRecreate = false,
  }) {
    if (_instance != null && !forceRecreate) {
      _instance!._tokenProvider = tokenProvider;
      _instance!._refreshToken = refreshToken;
      _instance!._onUnauthorized = onUnauthorized;
      _configureDio(
        dio: _instance!._dio,
        baseUrl: baseUrl,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        sendTimeout: sendTimeout,
        defaultHeaders: defaultHeaders,
      );
      return;
    }

    _instance = null;
    _createInstance(
      baseUrl: baseUrl,
      tokenProvider: tokenProvider,
      refreshToken: refreshToken,
      onUnauthorized: onUnauthorized,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      sendTimeout: sendTimeout,
      enableLogging: enableLogging,
      defaultHeaders: defaultHeaders,
    );
  }

  Future<ApiResponse<T>> get<T>(
    String path,
    JsonMap? param, {
    JsonMap? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(Object? data)? decoder,
  }) {
    return request<T>(
      path,
      method: ApiMethod.get,
      queryParameters: queryParameters ?? param,
      options: options,
      cancelToken: cancelToken,
      decoder: decoder,
    );
  }

  Future<ApiResponse<T>> post<T>(
    String path,
    Object? param, {
    Object? body,
    JsonMap? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    T Function(Object? data)? decoder,
  }) {
    return request<T>(
      path,
      method: ApiMethod.post,
      body: body ?? param,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
      decoder: decoder,
    );
  }

  Future<ApiResponse<T>> put<T>(
    String path,
    Object? param, {
    Object? body,
    JsonMap? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(Object? data)? decoder,
  }) {
    return request<T>(
      path,
      method: ApiMethod.put,
      body: body ?? param,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      decoder: decoder,
    );
  }

  Future<ApiResponse<T>> patch<T>(
    String path,
    Object? param, {
    Object? body,
    JsonMap? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(Object? data)? decoder,
  }) {
    return request<T>(
      path,
      method: ApiMethod.patch,
      body: body ?? param,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      decoder: decoder,
    );
  }

  Future<ApiResponse<T>> delete<T>(
    String path,
    Object? param, {
    Object? body,
    JsonMap? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(Object? data)? decoder,
  }) {
    return request<T>(
      path,
      method: ApiMethod.delete,
      body: body ?? param,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      decoder: decoder,
    );
  }

  Future<BaseResponse<T>> getBase<T>(
    String path,
    JsonMap? param, {
    JsonMap? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(Object? data)? decoder,
  }) async {
    final response = await get<Object?>(
      path,
      param,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
    return BaseResponse<T>.fromJson(response.data, decoder: decoder);
  }

  Future<BaseResponse<T>> postBase<T>(
    String path,
    Object? param, {
    Object? body,
    JsonMap? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    T Function(Object? data)? decoder,
  }) async {
    final response = await post<Object?>(
      path,
      param,
      body: body,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
    return BaseResponse<T>.fromJson(response.data, decoder: decoder);
  }

  Future<BaseResponse<T>> requestBase<T>(
    String path, {
    required ApiMethod method,
    Object? body,
    JsonMap? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    T Function(Object? data)? decoder,
  }) async {
    final response = await request<Object?>(
      path,
      method: method,
      body: body,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
    return BaseResponse<T>.fromJson(response.data, decoder: decoder);
  }

  Future<ApiResponse<T>> request<T>(
    String path, {
    required ApiMethod method,
    Object? body,
    JsonMap? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    T Function(Object? data)? decoder,
  }) async {
    try {
      var response = await _sendRequest(
        path: path,
        method: method,
        body: body,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );

      if (response.statusCode == 401 && await _refreshTokenSingleFlight()) {
        response = await _sendRequest(
          path: path,
          method: method,
          body: body,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
          onSendProgress: onSendProgress,
          onReceiveProgress: onReceiveProgress,
          hasRetried: true,
        );
      }

      if (!_isSuccessful(response.statusCode)) {
        if (response.statusCode == 401) {
          await _onUnauthorized?.call();
        }
        throw _exceptionFromResponse(response);
      }

      return ApiResponse<T>(
        statusCode: response.statusCode,
        data: _decode<T>(response.data, decoder),
        message: _extractMessage(response.data),
        headers: response.headers,
      );
    } on DioException catch (error, stackTrace) {
      throw _exceptionFromDio(error, stackTrace);
    }
  }

  Future<Response<Object?>> _sendRequest({
    required String path,
    required ApiMethod method,
    Object? body,
    JsonMap? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    bool hasRetried = false,
  }) {
    return _dio.request<Object?>(
      path,
      data: body,
      queryParameters: queryParameters,
      options: _mergeOptions(options, method, hasRetried: hasRetried),
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  void setHeader(String key, String value) {
    _dio.options.headers[key] = value;
  }

  void removeHeader(String key) {
    _dio.options.headers.remove(key);
  }

  static void _configureDio({
    required Dio dio,
    required String baseUrl,
    required Duration connectTimeout,
    required Duration receiveTimeout,
    required Duration sendTimeout,
    required Map<String, String>? defaultHeaders,
  }) {
    dio.options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      sendTimeout: sendTimeout,
      responseType: ResponseType.json,
      contentType: Headers.jsonContentType,
      headers: <String, dynamic>{
        Headers.acceptHeader: Headers.jsonContentType,
        appVersionHeader: defaultAppVersion,
        if (defaultHeaders != null) ...defaultHeaders,
      },
      validateStatus: (status) => status != null && status < 500,
    );
  }

  Options _mergeOptions(
    Options? options,
    ApiMethod method, {
    bool hasRetried = false,
  }) {
    final merged = options ?? Options();
    final extra = Map<String, dynamic>.from(merged.extra ?? const {});
    extra['hasRetriedAfterRefresh'] = hasRetried;

    return merged.copyWith(method: method.name.toUpperCase(), extra: extra);
  }

  Future<bool> _refreshTokenSingleFlight() {
    final refreshToken = _refreshToken;
    if (refreshToken == null) {
      return Future.value(false);
    }

    final runningRefresh = _refreshTokenFuture;
    if (runningRefresh != null) {
      return runningRefresh;
    }

    final refreshFuture = Future.sync(refreshToken)
        .then((success) {
          return success;
        })
        .catchError((Object error, StackTrace stackTrace) {
          developer.log(
            'Refresh token failed',
            name: 'ApiCaller',
            error: error,
            stackTrace: stackTrace,
          );
          return false;
        })
        .whenComplete(() {
          _refreshTokenFuture = null;
        });

    _refreshTokenFuture = refreshFuture;
    return refreshFuture;
  }

  bool _isSuccessful(int? statusCode) {
    return statusCode != null && statusCode >= 200 && statusCode < 300;
  }

  T _decode<T>(Object? data, T Function(Object? data)? decoder) {
    if (decoder != null) {
      return decoder(data);
    }

    if (data is T) {
      return data;
    }

    if (data == null) {
      return null as T;
    }

    throw ApiException(
      message: 'Response type mismatch. Provide a decoder for ${T.toString()}.',
      data: data,
      code: 'decode_error',
    );
  }

  ApiException _exceptionFromDio(DioException error, StackTrace stackTrace) {
    final response = error.response;
    if (response != null) {
      return _exceptionFromResponse(response, stackTrace: stackTrace);
    }

    return ApiException(
      message: _messageForDioException(error),
      code: error.type.name,
      data: error.error,
      stackTrace: stackTrace,
    );
  }

  ApiException _exceptionFromResponse(
    Response<Object?> response, {
    StackTrace? stackTrace,
  }) {
    return ApiException(
      message:
          _extractMessage(response.data) ??
          _messageForStatus(response.statusCode),
      statusCode: response.statusCode,
      code: _extractCode(response.data),
      data: response.data,
      stackTrace: stackTrace,
    );
  }

  String? _extractMessage(Object? data) {
    if (data is Map) {
      final message = data['message'] ?? data['error'] ?? data['detail'];
      if (message != null) {
        return message.toString();
      }
    }
    if (data is String && data.trim().isNotEmpty) {
      return data;
    }
    return null;
  }

  String? _extractCode(Object? data) {
    if (data is Map) {
      final code = data['code'] ?? data['error_code'];
      return code?.toString();
    }
    return null;
  }

  String _messageForDioException(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout =>
        'Connection timeout. Please try again.',
      DioExceptionType.sendTimeout => 'Send timeout. Please try again.',
      DioExceptionType.receiveTimeout => 'Receive timeout. Please try again.',
      DioExceptionType.badCertificate => 'Invalid server certificate.',
      DioExceptionType.badResponse => 'Server returned an invalid response.',
      DioExceptionType.cancel => 'Request was cancelled.',
      DioExceptionType.connectionError =>
        'Cannot connect to server. Check your network.',
      DioExceptionType.unknown => 'Unexpected network error.',
    };
  }

  String _messageForStatus(int? statusCode) {
    final code = statusCode ?? 0;
    return switch (code) {
      400 => 'Bad request.',
      401 => 'Unauthorized.',
      403 => 'Forbidden.',
      404 => 'Resource not found.',
      408 => 'Request timeout.',
      422 => 'Validation failed.',
      429 => 'Too many requests.',
      >= 500 => 'Server error. Please try again later.',
      _ => 'Request failed.',
    };
  }
}
