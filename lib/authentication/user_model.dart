class UserModel {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String? profilePhoto;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.profilePhoto,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] ?? 0,
    name: json['name'] ?? '',
    email: json['email'] ?? '',
    phone: json['phone'] ?? '',
    profilePhoto: json['profile_photo'],
  );
}
