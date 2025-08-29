import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

/// Widget لعرض معلومات الاستجابة للتطوير والاختبار
class ResponsiveDebugInfo extends StatelessWidget {
  final bool showAlways;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;

  const ResponsiveDebugInfo({
    super.key,
    this.showAlways = false,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    // إظهار المعلومات فقط في وضع التطوير أو إذا كان showAlways = true
    if (!showAlways && const bool.fromEnvironment('dart.vm.product')) {
      return const SizedBox.shrink();
    }

    final screenSize = MediaQuery.of(context).size;
    final deviceType = ResponsiveHelper.getDeviceType(context);
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    
    return Positioned(
      top: 50,
      left: 10,
      child: Container(
        padding: padding ?? const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.black.withOpacity(0.7),
          borderRadius: borderRadius ?? BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Debug Info',
              style: TextStyle(
                color: textColor ?? Colors.white,
                fontSize: (fontSize ?? 12) + 2,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            _buildInfoRow('Device:', _getDeviceTypeText(deviceType)),
            _buildInfoRow('Width:', '${screenSize.width.toInt()}px'),
            _buildInfoRow('Height:', '${screenSize.height.toInt()}px'),
            _buildInfoRow('Ratio:', devicePixelRatio.toStringAsFixed(1)),
            _buildInfoRow('Breakpoint:', _getCurrentBreakpoint(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: textColor ?? Colors.white70,
              fontSize: fontSize ?? 10,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: textColor ?? Colors.white,
              fontSize: fontSize ?? 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getDeviceTypeText(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.mobile:
        return 'Mobile';
      case DeviceType.tablet:
        return 'Tablet';
      case DeviceType.desktop:
        return 'Desktop';
      case DeviceType.largeDesktop:
        return 'Large Desktop';
    }
  }

  String _getCurrentBreakpoint(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < ResponsiveHelper.mobileBreakpoint) {
      return '< ${ResponsiveHelper.mobileBreakpoint.toInt()}';
    } else if (width < ResponsiveHelper.tabletBreakpoint) {
      return '< ${ResponsiveHelper.tabletBreakpoint.toInt()}';
    } else if (width < ResponsiveHelper.desktopBreakpoint) {
      return '< ${ResponsiveHelper.desktopBreakpoint.toInt()}';
    } else {
      return '≥ ${ResponsiveHelper.desktopBreakpoint.toInt()}';
    }
  }
}

/// Widget مبسط لعرض نوع الجهاز فقط
class DeviceTypeIndicator extends StatelessWidget {
  final Color? color;
  final double? size;

  const DeviceTypeIndicator({
    super.key,
    this.color,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = ResponsiveHelper.getDeviceType(context);
    final indicatorColor = color ?? _getDeviceColor(deviceType);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: indicatorColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: indicatorColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getDeviceIcon(deviceType),
            size: size ?? 16,
            color: indicatorColor,
          ),
          const SizedBox(width: 4),
          Text(
            _getDeviceTypeText(deviceType),
            style: TextStyle(
              color: indicatorColor,
              fontSize: (size ?? 16) - 4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDeviceColor(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.mobile:
        return Colors.green;
      case DeviceType.tablet:
        return Colors.orange;
      case DeviceType.desktop:
        return Colors.blue;
      case DeviceType.largeDesktop:
        return Colors.purple;
    }
  }

  IconData _getDeviceIcon(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.mobile:
        return Icons.phone_android;
      case DeviceType.tablet:
        return Icons.tablet;
      case DeviceType.desktop:
        return Icons.desktop_windows;
      case DeviceType.largeDesktop:
        return Icons.tv;
    }
  }

  String _getDeviceTypeText(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.mobile:
        return 'Mobile';
      case DeviceType.tablet:
        return 'Tablet';
      case DeviceType.desktop:
        return 'Desktop';
      case DeviceType.largeDesktop:
        return 'Large';
    }
  }
}

/// Extension لإضافة معلومات الاستجابة لأي Widget
extension ResponsiveDebugExtension on Widget {
  Widget withResponsiveDebug({bool showAlways = false}) {
    return Stack(
      children: [
        this,
        ResponsiveDebugInfo(showAlways: showAlways),
      ],
    );
  }

  Widget withDeviceIndicator() {
    return Stack(
      children: [
        this,
        const Positioned(
          top: 10,
          right: 10,
          child: DeviceTypeIndicator(),
        ),
      ],
    );
  }
}

/// Mixin لإضافة وظائف الاختبار للشاشات
mixin ResponsiveTestMixin<T extends StatefulWidget> on State<T> {
  bool _showDebugInfo = false;

  void toggleDebugInfo() {
    setState(() {
      _showDebugInfo = !_showDebugInfo;
    });
  }

  Widget buildWithResponsiveTest(Widget child) {
    return Stack(
      children: [
        child,
        if (_showDebugInfo) ResponsiveDebugInfo(showAlways: true),
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton.small(
            onPressed: toggleDebugInfo,
            backgroundColor: Colors.black54,
            child: Icon(
              _showDebugInfo ? Icons.visibility_off : Icons.visibility,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
