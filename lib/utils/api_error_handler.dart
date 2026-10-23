import 'package:dio/dio.dart';

class ApiErrorHandler {
  static DioException normalizeDioException(DioException error) {
    final message = getMessage(error);

    return error.copyWith(
      message: message,
      error: ApiException(
        message,
        statusCode: error.response?.statusCode,
      ),
    );
  }

  static String getMessage(dynamic error) {
    if (error is ApiException) {
      return error.message;
    }

    if (error is DioException) {
      final responseData = error.response?.data;
      final statusCode = error.response?.statusCode;

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'Connection timed out. Please try again.';
      }

      if (error.type == DioExceptionType.connectionError) {
        return 'No internet connection. Please check your network.';
      }

      if (error.type == DioExceptionType.cancel) {
        return 'Request was cancelled.';
      }

      final apiMessage = _messageFromResponse(responseData);
      if (apiMessage != null) return apiMessage;

      final statusMessage = _messageFromStatusCode(statusCode);
      if (statusMessage != null) return statusMessage;
      if (statusCode != null && statusCode >= 500) {
        return 'Server error ($statusCode). Please try again later.';
      }
    }

    final text = error.toString().replaceFirst('Exception: ', '').trim();
    if (text.isNotEmpty && text != 'null') return text;

    return 'Something went wrong. Please try again.';
  }

  static String? _messageFromResponse(dynamic responseData) {
    if (responseData is Map) {
      for (final key in ['message', 'error', 'detail', 'title']) {
        final value = responseData[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }

      final errors = responseData['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
        if (first != null) return first.toString();
      }
      if (errors is List && errors.isNotEmpty) return errors.first.toString();
    }

    if (responseData is String && responseData.trim().isNotEmpty) {
      return responseData.trim();
    }

    return null;
  }

  static String? _messageFromStatusCode(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request (400). Please check the submitted details.';
      case 401:
        return 'Unauthorized (401). Please log in again.';
      case 402:
        return 'Payment required (402). Please contact support.';
      case 403:
        return 'Forbidden (403). You do not have permission for this action.';
      case 404:
        return 'Not found (404). The requested resource was not found.';
      case 405:
        return 'Method not allowed (405). Please update the app or contact support.';
      case 406:
        return 'Not acceptable (406). Please update the app or contact support.';
      case 408:
        return 'Request timeout (408). Please try again.';
      case 409:
        return 'Conflict (409). The data may have changed. Please refresh and try again.';
      case 410:
        return 'Gone (410). This resource is no longer available.';
      case 413:
        return 'Payload too large (413). Please reduce the file size or submitted data.';
      case 415:
        return 'Unsupported media type (415). Please check the selected file.';
      case 422:
        return 'Validation failed (422). Please check the entered details.';
      case 423:
        return 'Locked (423). This record is currently locked.';
      case 429:
        return 'Too many requests (429). Please wait a moment and try again.';
      case 500:
        return 'Internal server error (500). Please try again later.';
      case 501:
        return 'Not implemented (501). Please contact support.';
      case 502:
        return 'Bad gateway (502). Please try again later.';
      case 503:
        return 'Service unavailable (503). Please try again later.';
      case 504:
        return 'Gateway timeout (504). Please try again later.';
    }

    return null;
  }
}

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
