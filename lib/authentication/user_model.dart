class UserModel {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String? profilePhoto;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.role = 'user',
    this.profilePhoto,
  });

  bool get isAstrologer => role == 'astrologer';

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] ?? 0,
    name: json['name'] ?? '',
    email: json['email'] ?? '',
    phone: json['phone'] ?? '',
    role: json['role']?.toString() ?? 'user',
    profilePhoto: json['profile_photo'],
  );
}
