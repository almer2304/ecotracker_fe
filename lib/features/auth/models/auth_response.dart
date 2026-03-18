import 'user_model.dart';

class AuthResponse {
  final String token;
  final UserModel profile;

  AuthResponse({
    required this.token,
    required this.profile,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String,
      profile: UserModel.fromJson(json['profile'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'profile': profile.toJson(),
    };
  }
}