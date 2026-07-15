class UserModel {
  final int id;
  final String username;
  final String role;
  final int storeId;
  final String? email;

  UserModel({
    required this.id,
    required this.role,
    required this.username,
    required this.storeId,
    this.email,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as int,
        username: json['username'] as String,
        role: json['role'] as String,
        storeId: json['store_id'] as int,
        email: json['email'] as String?,
      );
}

class AuthResult {
  final String token;
  final UserModel user;

  AuthResult({required this.token, required this.user});

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
        token: json['token'] as String,
        user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      );
}
