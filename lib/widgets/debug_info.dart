import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

/// Widget بسيط لعرض معلومات الشاشة للاختبار
class DebugInfo extends StatelessWidget {
  const DebugInfo({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final deviceType = ResponsiveHelper.getDeviceType(context);
    
    return Positioned(
      top: 50,
      left: 10,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Screen Info',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Type: ${_getDeviceText(deviceType)}',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            Text(
              'Size: ${screenSize.width.toInt()} x ${screenSize.height.toInt()}',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  String _getDeviceText(DeviceType deviceType) {
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
}
