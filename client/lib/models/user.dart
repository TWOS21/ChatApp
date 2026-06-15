class UserModel {
  final int id;
  final String username;
  final String? nickname;
  final String? avatarUrl;
  final String? bio;

  UserModel({
    required this.id,
    required this.username,
    this.nickname,
    this.avatarUrl,
    this.bio,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      username: json['username'],
      nickname: json['nickname'],
      avatarUrl: json['avatar_url'],
      bio: json['bio'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'nickname': nickname,
        'avatar_url': avatarUrl,
        'bio': bio,
      };

  String get displayName => nickname ?? username;
}
