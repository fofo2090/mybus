import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class StudentAvatar extends StatelessWidget {
  final String? photoUrl;
  final String studentName;
  final double radius;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;
  final VoidCallback? onTap;
  final bool showCameraIcon;
  final Widget? cameraIcon;

  const StudentAvatar({
    super.key,
    this.photoUrl,
    required this.studentName,
    this.radius = 30,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
    this.onTap,
    this.showCameraIcon = false,
    this.cameraIcon,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    final initials = _getInitials(studentName);

    Widget avatar = CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? const Color(0xFF1E88E5),
      child: hasPhoto
          ? ClipOval(
              child: _buildImageWidget(photoUrl!, initials),
            )
          : _buildPlaceholder(initials),
    );

    if (showCameraIcon) {
      avatar = Stack(
        children: [
          avatar,
          Positioned(
            bottom: 0,
            right: 0,
            child: cameraIcon ?? Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.camera_alt,
                size: radius * 0.5,
                color: const Color(0xFF1E88E5),
              ),
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: avatar,
      );
    }

    return avatar;
  }

  Widget _buildPlaceholder(String initials) {
    return Text(
      initials,
      style: TextStyle(
        color: textColor ?? Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: fontSize ?? (radius * 0.6),
      ),
    );
  }

  Widget _buildImageWidget(String photoUrl, String initials) {
    // Check if it's a base64 data URL
    if (photoUrl.startsWith('data:image')) {
      try {
        // Extract base64 data from data URL
        final base64String = photoUrl.split(',')[1];
        final imageBytes = base64Decode(base64String);

        return Image.memory(
          imageBytes,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('❌ Error loading base64 image: $error');
            return _buildPlaceholder(initials);
          },
        );
      } catch (e) {
        debugPrint('❌ Error decoding base64 image: $e');
        return _buildPlaceholder(initials);
      }
    } else {
      // Regular network image
      return CachedNetworkImage(
        imageUrl: photoUrl,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildPlaceholder(initials),
        errorWidget: (context, url, error) => _buildPlaceholder(initials),
      );
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'ط';

    final words = name.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}';
    }
    return name[0];
  }
}

/// Enhanced Student Avatar with loading states and error handling
class EnhancedStudentAvatar extends StatelessWidget {
  final String? photoUrl;
  final String studentName;
  final double radius;
  final Color? backgroundColor;
  final Color? textColor;
  final VoidCallback? onTap;
  final bool showCameraIcon;
  final bool showBorder;
  final Color? borderColor;
  final double borderWidth;

  const EnhancedStudentAvatar({
    super.key,
    this.photoUrl,
    required this.studentName,
    this.radius = 30,
    this.backgroundColor,
    this.textColor,
    this.onTap,
    this.showCameraIcon = false,
    this.showBorder = false,
    this.borderColor,
    this.borderWidth = 2,
  });

  @override
  Widget build(BuildContext context) {
    Widget avatar = StudentAvatar(
      photoUrl: photoUrl,
      studentName: studentName,
      radius: radius,
      backgroundColor: backgroundColor,
      textColor: textColor,
      onTap: onTap,
      showCameraIcon: showCameraIcon,
    );

    if (showBorder) {
      avatar = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: borderColor ?? Colors.white,
            width: borderWidth,
          ),
        ),
        child: avatar,
      );
    }

    return avatar;
  }
}

/// Student Avatar with status indicator
class StudentAvatarWithStatus extends StatelessWidget {
  final String? photoUrl;
  final String studentName;
  final double radius;
  final Color? backgroundColor;
  final Color? textColor;
  final VoidCallback? onTap;
  final bool showCameraIcon;
  final Widget? statusIndicator;
  final Color? statusColor;
  final IconData? statusIcon;

  const StudentAvatarWithStatus({
    super.key,
    this.photoUrl,
    required this.studentName,
    this.radius = 30,
    this.backgroundColor,
    this.textColor,
    this.onTap,
    this.showCameraIcon = false,
    this.statusIndicator,
    this.statusColor,
    this.statusIcon,
  });

  @override
  Widget build(BuildContext context) {
    Widget avatar = StudentAvatar(
      photoUrl: photoUrl,
      studentName: studentName,
      radius: radius,
      backgroundColor: backgroundColor,
      textColor: textColor,
      onTap: onTap,
      showCameraIcon: showCameraIcon,
    );

    if (statusIndicator != null || statusIcon != null) {
      avatar = Stack(
        children: [
          avatar,
          Positioned(
            top: 0,
            right: 0,
            child: statusIndicator ?? Container(
              width: radius * 0.4,
              height: radius * 0.4,
              decoration: BoxDecoration(
                color: statusColor ?? Colors.green,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 1,
                ),
              ),
              child: statusIcon != null
                  ? Icon(
                      statusIcon,
                      size: radius * 0.25,
                      color: Colors.white,
                    )
                  : null,
            ),
          ),
        ],
      );
    }

    return avatar;
  }
}

/// Utility class for student avatar configurations
class StudentAvatarConfig {
  static const double smallRadius = 20;
  static const double mediumRadius = 30;
  static const double largeRadius = 40;
  static const double extraLargeRadius = 60;

  static const Color defaultBackgroundColor = Color(0xFF1E88E5);
  static const Color defaultTextColor = Colors.white;

  // Status colors
  static const Color onlineStatusColor = Colors.green;
  static const Color offlineStatusColor = Colors.grey;
  static const Color busStatusColor = Colors.orange;
  static const Color schoolStatusColor = Colors.blue;
}
