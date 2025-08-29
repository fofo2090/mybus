import 'package:flutter/material.dart';

/// مساعد للتعامل مع الشاشات المتجاوبة
class ResponsiveHelper {
  // نقاط التوقف للشاشات المختلفة
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;
  static const double largeDesktopBreakpoint = 1600;

  /// تحديد نوع الجهاز بناءً على عرض الشاشة
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < mobileBreakpoint) {
      return DeviceType.mobile;
    } else if (width < tabletBreakpoint) {
      return DeviceType.tablet;
    } else if (width < desktopBreakpoint) {
      return DeviceType.desktop;
    } else {
      return DeviceType.largeDesktop;
    }
  }

  /// الحصول على عدد الأعمدة المناسب للـ GridView
  static int getGridCrossAxisCount(BuildContext context, {
    int? mobileCount,
    int? tabletCount,
    int? desktopCount,
    int? largeDesktopCount,
  }) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return mobileCount ?? 1;
      case DeviceType.tablet:
        return tabletCount ?? 2;
      case DeviceType.desktop:
        return desktopCount ?? 3;
      case DeviceType.largeDesktop:
        return largeDesktopCount ?? 4;
    }
  }

  /// الحصول على نسبة العرض إلى الارتفاع المناسبة
  static double getChildAspectRatio(BuildContext context, {
    double? mobileRatio,
    double? tabletRatio,
    double? desktopRatio,
    double? largeDesktopRatio,
  }) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return mobileRatio ?? 0.8;
      case DeviceType.tablet:
        return tabletRatio ?? 0.9;
      case DeviceType.desktop:
        return desktopRatio ?? 1.0;
      case DeviceType.largeDesktop:
        return largeDesktopRatio ?? 1.1;
    }
  }

  /// الحصول على المسافات المناسبة
  static double getSpacing(BuildContext context, {
    double? mobileSpacing,
    double? tabletSpacing,
    double? desktopSpacing,
    double? largeDesktopSpacing,
  }) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return mobileSpacing ?? 8.0;
      case DeviceType.tablet:
        return tabletSpacing ?? 12.0;
      case DeviceType.desktop:
        return desktopSpacing ?? 16.0;
      case DeviceType.largeDesktop:
        return largeDesktopSpacing ?? 20.0;
    }
  }

  /// الحصول على حجم الخط المناسب
  static double getFontSize(BuildContext context, {
    double? mobileFontSize,
    double? tabletFontSize,
    double? desktopFontSize,
    double? largeDesktopFontSize,
  }) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return mobileFontSize ?? 14.0;
      case DeviceType.tablet:
        return tabletFontSize ?? 16.0;
      case DeviceType.desktop:
        return desktopFontSize ?? 18.0;
      case DeviceType.largeDesktop:
        return largeDesktopFontSize ?? 20.0;
    }
  }

  /// الحصول على الحشو المناسب
  static EdgeInsets getPadding(BuildContext context, {
    EdgeInsets? mobilePadding,
    EdgeInsets? tabletPadding,
    EdgeInsets? desktopPadding,
    EdgeInsets? largeDesktopPadding,
  }) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return mobilePadding ?? const EdgeInsets.all(8.0);
      case DeviceType.tablet:
        return tabletPadding ?? const EdgeInsets.all(12.0);
      case DeviceType.desktop:
        return desktopPadding ?? const EdgeInsets.all(16.0);
      case DeviceType.largeDesktop:
        return largeDesktopPadding ?? const EdgeInsets.all(20.0);
    }
  }

  /// تحديد ما إذا كانت الشاشة صغيرة
  static bool isMobile(BuildContext context) {
    return getDeviceType(context) == DeviceType.mobile;
  }

  /// تحديد ما إذا كانت الشاشة متوسطة
  static bool isTablet(BuildContext context) {
    return getDeviceType(context) == DeviceType.tablet;
  }

  /// تحديد ما إذا كانت الشاشة كبيرة
  static bool isDesktop(BuildContext context) {
    final deviceType = getDeviceType(context);
    return deviceType == DeviceType.desktop || deviceType == DeviceType.largeDesktop;
  }

  /// الحصول على عرض الشاشة
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// الحصول على ارتفاع الشاشة
  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// تحديد ما إذا كانت الشاشة في الوضع الأفقي
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// تحديد ما إذا كانت الشاشة في الوضع العمودي
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  /// الحصول على حجم الأيقونة المناسب
  static double getIconSize(BuildContext context, {
    double? mobileSize,
    double? tabletSize,
    double? desktopSize,
    double? largeDesktopSize,
  }) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return mobileSize ?? 20.0;
      case DeviceType.tablet:
        return tabletSize ?? 24.0;
      case DeviceType.desktop:
        return desktopSize ?? 28.0;
      case DeviceType.largeDesktop:
        return largeDesktopSize ?? 32.0;
    }
  }

  /// الحصول على ارتفاع الزر المناسب
  static double getButtonHeight(BuildContext context, {
    double? mobileHeight,
    double? tabletHeight,
    double? desktopHeight,
    double? largeDesktopHeight,
  }) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return mobileHeight ?? 44.0;
      case DeviceType.tablet:
        return tabletHeight ?? 48.0;
      case DeviceType.desktop:
        return desktopHeight ?? 52.0;
      case DeviceType.largeDesktop:
        return largeDesktopHeight ?? 56.0;
    }
  }

  /// الحصول على نصف قطر الحدود المناسب
  static double getBorderRadius(BuildContext context, {
    double? mobileRadius,
    double? tabletRadius,
    double? desktopRadius,
    double? largeDesktopRadius,
  }) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return mobileRadius ?? 8.0;
      case DeviceType.tablet:
        return tabletRadius ?? 10.0;
      case DeviceType.desktop:
        return desktopRadius ?? 12.0;
      case DeviceType.largeDesktop:
        return largeDesktopRadius ?? 14.0;
    }
  }

  /// الحصول على العرض الأقصى للمحتوى
  static double getMaxContentWidth(BuildContext context) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return double.infinity;
      case DeviceType.tablet:
        return 800;
      case DeviceType.desktop:
        return 1000;
      case DeviceType.largeDesktop:
        return 1200;
    }
  }
}

/// أنواع الأجهزة
enum DeviceType {
  mobile,
  tablet,
  desktop,
  largeDesktop,
}

/// Widget للتخطيط المتجاوب
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, DeviceType deviceType) builder;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = ResponsiveHelper.getDeviceType(context);
    return builder(context, deviceType);
  }
}

/// Widget للتخطيط المتجاوب مع خيارات مختلفة لكل جهاز
class ResponsiveWidget extends StatelessWidget {
  final Widget? mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? largeDesktop;

  const ResponsiveWidget({
    super.key,
    this.mobile,
    this.tablet,
    this.desktop,
    this.largeDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = ResponsiveHelper.getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile ?? tablet ?? desktop ?? largeDesktop ?? const SizedBox();
      case DeviceType.tablet:
        return tablet ?? mobile ?? desktop ?? largeDesktop ?? const SizedBox();
      case DeviceType.desktop:
        return desktop ?? tablet ?? largeDesktop ?? mobile ?? const SizedBox();
      case DeviceType.largeDesktop:
        return largeDesktop ?? desktop ?? tablet ?? mobile ?? const SizedBox();
    }
  }
}
