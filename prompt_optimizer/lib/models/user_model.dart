class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String picture;

  const UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    required this.picture,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? json['display_name']?.toString() ?? '',
      picture: json['picture']?.toString() ?? json['photoURL']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'picture': picture,
    };
  }
}
