/// Base exception for all Circle Vault errors.
class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() => 'AppException(code: $code, message: $message)';
}

/// Thrown for Firebase Auth and OTP errors.
class AuthException extends AppException {
  const AuthException(super.message, {super.code});

  @override
  String toString() => 'AuthException(code: $code, message: $message)';
}

/// Thrown for Paystack payment errors.
class PaymentException extends AppException {
  const PaymentException(super.message, {super.code});

  @override
  String toString() => 'PaymentException(code: $code, message: $message)';
}

/// Thrown for Firestore / circle logic errors.
class CircleException extends AppException {
  const CircleException(super.message, {super.code});

  @override
  String toString() => 'CircleException(code: $code, message: $message)';
}

/// Thrown for HTTP / connectivity errors.
class NetworkException extends AppException {
  const NetworkException(super.message, {super.code});

  @override
  String toString() => 'NetworkException(code: $code, message: $message)';
}

/// Thrown when an AI advisory API call fails.
class AiAdvisoryException extends AppException {
  const AiAdvisoryException(super.message, {super.code});

  @override
  String toString() => 'AiAdvisoryException(code: $code, message: $message)';
}
