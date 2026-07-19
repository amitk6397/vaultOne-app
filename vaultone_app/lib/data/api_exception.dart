class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

String readableApiError(Object error) {
  if (error is ApiException) return error.message;
  final message = error.toString().replaceFirst('Exception: ', '').trim();
  if (message.isEmpty || message == 'null') {
    return 'Something went wrong. Please try again.';
  }
  return message;
}
