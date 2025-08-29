import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Widget لعرض الصور المحفوظة كـ base64 في قاعدة البيانات
class Base64ImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const Base64ImageWidget({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholder();
    }

    // Check if it's a base64 image
    if (imageUrl!.startsWith('data:image/')) {
      return _buildBase64Image();
    }

    // Check if it's a Firebase Storage URL
    if (imageUrl!.startsWith('https://')) {
      return _buildNetworkImage();
    }

    // Fallback to placeholder
    return _buildPlaceholder();
  }

  Widget _buildBase64Image() {
    try {
      // Extract base64 data from data URL
      final base64Data = imageUrl!.split(',')[1];
      final bytes = base64Decode(base64Data);

      return _wrapWithBorderRadius(
        Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('❌ Error displaying base64 image: $error');
            return _buildErrorWidget();
          },
        ),
      );
    } catch (e) {
      debugPrint('❌ Error decoding base64 image: $e');
      return _buildErrorWidget();
    }
  }

  Widget _buildNetworkImage() {
    return _wrapWithBorderRadius(
      Image.network(
        imageUrl!,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingWidget(loadingProgress);
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint('❌ Error loading network image: $error');
          return _buildErrorWidget();
        },
      ),
    );
  }

  Widget _buildPlaceholder() {
    return _wrapWithBorderRadius(
      placeholder ??
          Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: const Icon(
              Icons.person,
              color: Colors.grey,
              size: 40,
            ),
          ),
    );
  }

  Widget _buildErrorWidget() {
    return _wrapWithBorderRadius(
      errorWidget ??
          Container(
            width: width,
            height: height,
            color: Colors.grey[100],
            child: const Icon(
              Icons.broken_image,
              color: Colors.grey,
              size: 40,
            ),
          ),
    );
  }

  Widget _buildLoadingWidget(ImageChunkEvent loadingProgress) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[100],
      child: Center(
        child: CircularProgressIndicator(
          value: loadingProgress.expectedTotalBytes != null
              ? loadingProgress.cumulativeBytesLoaded /
                  loadingProgress.expectedTotalBytes!
              : null,
          strokeWidth: 2,
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1E88E5)),
        ),
      ),
    );
  }

  Widget _wrapWithBorderRadius(Widget child) {
    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: child,
      );
    }
    return child;
  }
}

/// Widget مخصص لصور الطلاب مع تصميم دائري
class StudentAvatarWidget extends StatelessWidget {
  final String? imageUrl;
  final String studentName;
  final double radius;

  const StudentAvatarWidget({
    super.key,
    required this.imageUrl,
    required this.studentName,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF1E88E5),
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? ClipOval(
              child: Base64ImageWidget(
                imageUrl: imageUrl,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                placeholder: _buildInitialAvatar(),
                errorWidget: _buildInitialAvatar(),
              ),
            )
          : _buildInitialAvatar(),
    );
  }

  Widget _buildInitialAvatar() {
    return Text(
      studentName.isNotEmpty ? studentName[0].toUpperCase() : 'ط',
      style: TextStyle(
        color: Colors.white,
        fontSize: radius * 0.8,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

/// Helper functions للتعامل مع الصور
class ImageUtils {
  /// تحويل base64 إلى Uint8List
  static Uint8List? base64ToBytes(String base64String) {
    try {
      if (base64String.startsWith('data:image/')) {
        final base64Data = base64String.split(',')[1];
        return base64Decode(base64Data);
      }
      return base64Decode(base64String);
    } catch (e) {
      debugPrint('❌ Error converting base64 to bytes: $e');
      return null;
    }
  }

  /// تحويل Uint8List إلى base64
  static String bytesToBase64(Uint8List bytes, {String mimeType = 'image/jpeg'}) {
    final base64String = base64Encode(bytes);
    return 'data:$mimeType;base64,$base64String';
  }

  /// فحص إذا كان الرابط صورة base64
  static bool isBase64Image(String? url) {
    return url != null && url.startsWith('data:image/');
  }

  /// فحص إذا كان الرابط صورة شبكة
  static bool isNetworkImage(String? url) {
    return url != null && (url.startsWith('http://') || url.startsWith('https://'));
  }

  /// حساب حجم الصورة بالـ KB
  static double getImageSizeKB(String base64String) {
    try {
      if (base64String.startsWith('data:image/')) {
        final base64Data = base64String.split(',')[1];
        final bytes = base64Decode(base64Data);
        return bytes.length / 1024;
      }
      final bytes = base64Decode(base64String);
      return bytes.length / 1024;
    } catch (e) {
      return 0;
    }
  }
}
