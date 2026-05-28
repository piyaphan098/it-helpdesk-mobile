/// Custom application exception with user-friendly message.
class AppException implements Exception {
  const AppException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'AppException: $message${code != null ? ' ($code)' : ''}';
}

/// Maps Supabase Auth error messages to user-friendly text.
String mapAuthErrorMessage(String message) {
  final lower = message.toLowerCase();

  if (lower.contains('invalid login credentials')) {
    return 'Invalid email or password. Please try again.';
  }
  if (lower.contains('email not confirmed')) {
    return 'Please confirm your email before signing in.';
  }
  if (lower.contains('user already registered')) {
    return 'An account with this email already exists.';
  }
  if (lower.contains('password should be at least')) {
    return 'Password must be at least 6 characters.';
  }
  if (lower.contains('unable to validate email')) {
    return 'Please enter a valid email address.';
  }
  if (lower.contains('signup is disabled')) {
    return 'Registration is currently disabled. Contact your administrator.';
  }

  return message;
}


