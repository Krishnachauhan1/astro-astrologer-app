import 'package:astrosarthi_vendor/app_theme.dart';
import 'package:astrosarthi_vendor/utils/profile_photo_url.dart'; 
import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final Map<String, dynamic>? user;
  final String? photoUrl;
  final String? name;
  final double size;
  final double borderWidth;
  final Color? borderColor;

  const ProfileAvatar({
    super.key,
    this.user,
    this.photoUrl,
    this.name,
    this.size = 56,
    this.borderWidth = 2,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final url = photoUrl ?? resolveProfilePhotoUrl(user: user);
    final displayName = name ?? user?['name']?.toString();
    final initials = initialsFromName(displayName);
    final border = borderColor ?? Colors.white.withOpacity(0.5);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: border, width: borderWidth),
        color: Colors.white.withOpacity(0.15),
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null
          ? Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(initials),
            )
          : _placeholder(initials),
      );
  }

  Widget _placeholder(String initials) {
    return ColoredBox(
      color: Colors.white.withOpacity(0.2),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.36,
          ),
        ),
      ),
      );
  }
}
