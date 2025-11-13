import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'auth_models.g.dart';

@JsonSerializable()
class AuthToken extends Equatable {
  final String accessToken;
  final String tokenType;
  final int expiresIn;

  const AuthToken({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
  });

  factory AuthToken.fromJson(Map<String, dynamic> json) =>
      _$AuthTokenFromJson(json);

  Map<String, dynamic> toJson() => _$AuthTokenToJson(this);

  @override
  List<Object?> get props => [accessToken, tokenType, expiresIn];
}

@JsonSerializable()
class UserProfile extends Equatable {
  final String id;
  final String email;
  final String username;
  final bool isActive;
  final bool isAdmin;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.email,
    required this.username,
    required this.isActive,
    this.isAdmin = false,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);

  Map<String, dynamic> toJson() => _$UserProfileToJson(this);

  @override
  List<Object?> get props => [id, email, username, isActive, isAdmin, createdAt];
}

