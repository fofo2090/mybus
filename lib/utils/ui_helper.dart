import 'package:flutter/material.dart';
import 'app_constants.dart';

class UIHelper {
  // Common padding values
  static const EdgeInsets defaultPadding = EdgeInsets.all(AppConstants.defaultPadding);
  static const EdgeInsets horizontalPadding = EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding);
  static const EdgeInsets verticalPadding = EdgeInsets.symmetric(vertical: AppConstants.defaultPadding);
  static const EdgeInsets smallPadding = EdgeInsets.all(8.0);
  static const EdgeInsets largePadding = EdgeInsets.all(24.0);

  // Common spacing
  static const SizedBox smallVerticalSpace = SizedBox(height: 8);
  static const SizedBox mediumVerticalSpace = SizedBox(height: 16);
  static const SizedBox largeVerticalSpace = SizedBox(height: 24);
  static const SizedBox extraLargeVerticalSpace = SizedBox(height: 32);

  static const SizedBox smallHorizontalSpace = SizedBox(width: 8);
  static const SizedBox mediumHorizontalSpace = SizedBox(width: 16);
  static const SizedBox largeHorizontalSpace = SizedBox(width: 24);

  // Common border radius
  static BorderRadius get defaultBorderRadius => BorderRadius.circular(AppConstants.defaultBorderRadius);
  static BorderRadius get smallBorderRadius => BorderRadius.circular(8);
  static BorderRadius get largeBorderRadius => BorderRadius.circular(20);

  // Common shadows
  static List<BoxShadow> get defaultShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get strongShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // Build card with consistent styling
  static Widget buildCard({
    required Widget child,
    EdgeInsets? padding,
    EdgeInsets? margin,
    Color? color,
    List<BoxShadow>? boxShadow,
    BorderRadius? borderRadius,
    double? elevation,
  }) {
    return Container(
      margin: margin ?? const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: borderRadius ?? defaultBorderRadius,
        boxShadow: boxShadow ?? defaultShadow,
      ),
      child: Padding(
        padding: padding ?? defaultPadding,
        child: child,
      ),
    );
  }

  // Build section header
  static Widget buildSectionHeader({
    required String title,
    String? subtitle,
    Widget? trailing,
    EdgeInsets? padding,
  }) {
    return Padding(
      padding: padding ?? horizontalPadding,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF718096),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  // Build info row
  static Widget buildInfoRow({
    required String label,
    required String value,
    IconData? icon,
    Color? iconColor,
    TextStyle? labelStyle,
    TextStyle? valueStyle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: iconColor ?? AppConstants.primaryColor,
            ),
            const SizedBox(width: 8),
          ],
          Text(
            '$label: ',
            style: labelStyle ?? const TextStyle(
              fontWeight: FontWeight.w500,
              color: Color(0xFF4A5568),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: valueStyle ?? const TextStyle(
                color: Color(0xFF2D3748),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build status chip
  static Widget buildStatusChip({
    required String label,
    required Color color,
    Color? textColor,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor ?? color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Build action button
  static Widget buildActionButton({
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
    Color? backgroundColor,
    Color? textColor,
    bool isLoading = false,
    bool isEnabled = true,
  }) {
    return ElevatedButton(
      onPressed: isEnabled && !isLoading ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? AppConstants.primaryColor,
        foregroundColor: textColor ?? Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: defaultBorderRadius,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16),
                  const SizedBox(width: 8),
                ],
                Text(label),
              ],
            ),
    );
  }

  // Build empty state
  static Widget buildEmptyState({
    required String title,
    String? subtitle,
    IconData? icon,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
            ],
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4A5568),
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF718096),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action,
            ],
          ],
        ),
      ),
    );
  }

  // Build loading indicator
  static Widget buildLoadingIndicator({String? message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                color: Color(0xFF718096),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Build error state
  static Widget buildErrorState({
    required String title,
    String? subtitle,
    VoidCallback? onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4A5568),
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF718096),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              buildActionButton(
                label: 'إعادة المحاولة',
                onPressed: onRetry,
                icon: Icons.refresh,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
