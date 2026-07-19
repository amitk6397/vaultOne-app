class RegisterRequest {
  const RegisterRequest({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
    required this.confirmPassword,
    required this.termsAccepted,
  });

  final String fullName;
  final String email;
  final String phone;
  final String password;
  final String confirmPassword;
  final bool termsAccepted;

  Map<String, dynamic> toJson() => {
    'full_name': fullName,
    'email': email,
    'phone': phone,
    'password': password,
    'confirm_password': confirmPassword,
    'terms_accepted': termsAccepted,
  };
}

class LoginRequest {
  const LoginRequest({
    required this.identity,
    required this.password,
    required this.rememberMe,
  });

  final String identity;
  final String password;
  final bool rememberMe;

  Map<String, dynamic> toJson() => {
    'identity': identity,
    'password': password,
    'remember_me': rememberMe,
  };
}
