import 'package:astrosarthi_konnect_astrologer_app/servicess/api_service.dart';

String? resolveProfilePhotoUrl({
  Map<String, dynamic>? user,
  String? profilePhoto,
  String? profilePhotoUrl,
}) {
  final direct = profilePhotoUrl?.trim();
  if (direct != null && direct.isNotEmpty) return direct;

  final fromUser = user?['profile_photo_url']?.toString().trim();
  if (fromUser != null && fromUser.isNotEmpty) return fromUser;

  final path = profilePhoto?.trim() ?? user?['profile_photo']?.toString().trim();
  return resolveStorageUrl(path);
}

String? resolveStorageUrl(String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  return '$imageBaseUrl$path';
}

String initialsFromName(String? name) {
  final parts = (name ?? '').trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}
