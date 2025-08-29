import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'responsive_helper.dart';

/// أداة فحص وتحليل التجاوب في التطبيق
class ResponsiveValidator {
  static final ResponsiveValidator _instance = ResponsiveValidator._internal();
  factory ResponsiveValidator() => _instance;
  ResponsiveValidator._internal();

  /// فحص شامل للتجاوب
  static Future<ResponsiveAnalysisResult> analyzeResponsiveness(BuildContext context) async {
    debugPrint('🔍 بدء تحليل التجاوب الشامل...');
    
    final result = ResponsiveAnalysisResult();
    
    // فحص معلومات الجهاز
    result.deviceInfo = _analyzeDeviceInfo(context);
    
    // فحص نقاط التوقف
    result.breakpointAnalysis = _analyzeBreakpoints(context);
    
    // فحص الخطوط
    result.fontAnalysis = _analyzeFonts(context);
    
    // فحص المسافات
    result.spacingAnalysis = _analyzeSpacing(context);
    
    // فحص الأيقونات
    result.iconAnalysis = _analyzeIcons(context);
    
    // تقييم عام
    result.overallScore = _calculateOverallScore(result);
    result.recommendations = _generateRecommendations(result);
    
    debugPrint('✅ تم تحليل التجاوب بنجاح - النتيجة: ${result.overallScore}/100');
    
    return result;
  }

  /// تحليل معلومات الجهاز
  static DeviceAnalysis _analyzeDeviceInfo(BuildContext context) {
    final deviceType = ResponsiveHelper.getDeviceType(context);
    final screenWidth = ResponsiveHelper.getScreenWidth(context);
    final screenHeight = ResponsiveHelper.getScreenHeight(context);
    final isLandscape = ResponsiveHelper.isLandscape(context);
    
    return DeviceAnalysis(
      deviceType: deviceType,
      screenWidth: screenWidth,
      screenHeight: screenHeight,
      isLandscape: isLandscape,
      aspectRatio: screenWidth / screenHeight,
      pixelDensity: MediaQuery.of(context).devicePixelRatio,
    );
  }

  /// تحليل نقاط التوقف
  static BreakpointAnalysis _analyzeBreakpoints(BuildContext context) {
    final screenWidth = ResponsiveHelper.getScreenWidth(context);
    
    return BreakpointAnalysis(
      currentBreakpoint: ResponsiveHelper.getDeviceType(context),
      isOptimalSize: _isOptimalScreenSize(screenWidth),
      distanceToNextBreakpoint: _getDistanceToNextBreakpoint(screenWidth),
      recommendedColumns: ResponsiveHelper.getGridCrossAxisCount(context),
    );
  }

  /// تحليل الخطوط
  static FontAnalysis _analyzeFonts(BuildContext context) {
    final baseFontSize = ResponsiveHelper.getFontSize(context);
    final headingFontSize = ResponsiveHelper.getFontSize(context,
      mobileFontSize: 20, tabletFontSize: 24, desktopFontSize: 28);
    
    return FontAnalysis(
      baseFontSize: baseFontSize,
      headingFontSize: headingFontSize,
      isReadable: _isFontSizeReadable(baseFontSize),
      scaleRatio: headingFontSize / baseFontSize,
    );
  }

  /// تحليل المسافات
  static SpacingAnalysis _analyzeSpacing(BuildContext context) {
    final baseSpacing = ResponsiveHelper.getSpacing(context);
    final padding = ResponsiveHelper.getPadding(context);
    
    return SpacingAnalysis(
      baseSpacing: baseSpacing,
      padding: padding,
      isConsistent: _isSpacingConsistent(baseSpacing),
      density: _calculateSpacingDensity(context),
    );
  }

  /// تحليل الأيقونات
  static IconAnalysis _analyzeIcons(BuildContext context) {
    final iconSize = ResponsiveHelper.getIconSize(context);
    
    return IconAnalysis(
      iconSize: iconSize,
      isTouchFriendly: _isIconTouchFriendly(iconSize),
      isVisuallyBalanced: _isIconVisuallyBalanced(iconSize, context),
    );
  }

  /// حساب النتيجة الإجمالية
  static int _calculateOverallScore(ResponsiveAnalysisResult result) {
    int score = 0;
    
    // نقاط الجهاز (20 نقطة)
    if (result.deviceInfo.isLandscape != null) score += 5;
    if (result.deviceInfo.aspectRatio > 0) score += 5;
    if (result.deviceInfo.pixelDensity > 0) score += 10;
    
    // نقاط التوقف (25 نقطة)
    if (result.breakpointAnalysis.isOptimalSize) score += 15;
    if (result.breakpointAnalysis.recommendedColumns > 0) score += 10;
    
    // نقاط الخطوط (25 نقطة)
    if (result.fontAnalysis.isReadable) score += 15;
    if (result.fontAnalysis.scaleRatio >= 1.2 && result.fontAnalysis.scaleRatio <= 2.0) score += 10;
    
    // نقاط المسافات (15 نقطة)
    if (result.spacingAnalysis.isConsistent) score += 10;
    if (result.spacingAnalysis.density >= 0.5 && result.spacingAnalysis.density <= 2.0) score += 5;
    
    // نقاط الأيقونات (15 نقطة)
    if (result.iconAnalysis.isTouchFriendly) score += 10;
    if (result.iconAnalysis.isVisuallyBalanced) score += 5;
    
    return score;
  }

  /// توليد التوصيات
  static List<String> _generateRecommendations(ResponsiveAnalysisResult result) {
    final recommendations = <String>[];
    
    if (!result.breakpointAnalysis.isOptimalSize) {
      recommendations.add('⚠️ حجم الشاشة غير مثالي - فكر في تحسين التخطيط');
    }
    
    if (!result.fontAnalysis.isReadable) {
      recommendations.add('📝 حجم الخط صغير جداً - زد حجم الخط الأساسي');
    }
    
    if (result.fontAnalysis.scaleRatio < 1.2) {
      recommendations.add('📏 نسبة تدرج الخطوط منخفضة - زد الفرق بين أحجام الخطوط');
    }
    
    if (!result.spacingAnalysis.isConsistent) {
      recommendations.add('📐 المسافات غير متسقة - استخدم نظام مسافات موحد');
    }
    
    if (!result.iconAnalysis.isTouchFriendly) {
      recommendations.add('👆 الأيقونات صغيرة للمس - زد حجم الأيقونات');
    }
    
    if (result.overallScore >= 80) {
      recommendations.add('🎉 ممتاز! التطبيق متجاوب بشكل جيد');
    } else if (result.overallScore >= 60) {
      recommendations.add('👍 جيد! هناك مجال للتحسين');
    } else {
      recommendations.add('⚠️ يحتاج تحسين كبير في التجاوب');
    }
    
    return recommendations;
  }

  // Helper methods
  static bool _isOptimalScreenSize(double width) {
    return width >= 320 && width <= 1920; // نطاق معقول للشاشات
  }

  static double _getDistanceToNextBreakpoint(double width) {
    if (width < ResponsiveHelper.mobileBreakpoint) {
      return ResponsiveHelper.mobileBreakpoint - width;
    } else if (width < ResponsiveHelper.tabletBreakpoint) {
      return ResponsiveHelper.tabletBreakpoint - width;
    } else if (width < ResponsiveHelper.desktopBreakpoint) {
      return ResponsiveHelper.desktopBreakpoint - width;
    } else {
      return ResponsiveHelper.largeDesktopBreakpoint - width;
    }
  }

  static bool _isFontSizeReadable(double fontSize) {
    return fontSize >= 12; // الحد الأدنى للقراءة
  }

  static bool _isSpacingConsistent(double spacing) {
    return spacing >= 4 && spacing <= 32; // نطاق معقول للمسافات
  }

  static double _calculateSpacingDensity(BuildContext context) {
    final spacing = ResponsiveHelper.getSpacing(context);
    final screenWidth = ResponsiveHelper.getScreenWidth(context);
    return spacing / (screenWidth / 100); // نسبة المسافة إلى عرض الشاشة
  }

  static bool _isIconTouchFriendly(double iconSize) {
    return iconSize >= 24; // الحد الأدنى للمس المريح
  }

  static bool _isIconVisuallyBalanced(double iconSize, BuildContext context) {
    final fontSize = ResponsiveHelper.getFontSize(context);
    final ratio = iconSize / fontSize;
    return ratio >= 1.2 && ratio <= 2.0; // نسبة متوازنة بين الأيقونة والنص
  }

  /// طباعة تقرير مفصل
  static void printDetailedReport(ResponsiveAnalysisResult result) {
    debugPrint('📊 تقرير التجاوب المفصل:');
    debugPrint('═══════════════════════════════════════');
    
    debugPrint('📱 معلومات الجهاز:');
    debugPrint('  نوع الجهاز: ${result.deviceInfo.deviceType}');
    debugPrint('  عرض الشاشة: ${result.deviceInfo.screenWidth.toInt()}px');
    debugPrint('  ارتفاع الشاشة: ${result.deviceInfo.screenHeight.toInt()}px');
    debugPrint('  الاتجاه: ${result.deviceInfo.isLandscape ? 'أفقي' : 'عمودي'}');
    debugPrint('  نسبة العرض للارتفاع: ${result.deviceInfo.aspectRatio.toStringAsFixed(2)}');
    
    debugPrint('\n🎯 تحليل نقاط التوقف:');
    debugPrint('  النقطة الحالية: ${result.breakpointAnalysis.currentBreakpoint}');
    debugPrint('  حجم مثالي: ${result.breakpointAnalysis.isOptimalSize ? 'نعم' : 'لا'}');
    debugPrint('  الأعمدة المقترحة: ${result.breakpointAnalysis.recommendedColumns}');
    
    debugPrint('\n📝 تحليل الخطوط:');
    debugPrint('  حجم الخط الأساسي: ${result.fontAnalysis.baseFontSize.toStringAsFixed(1)}px');
    debugPrint('  حجم خط العناوين: ${result.fontAnalysis.headingFontSize.toStringAsFixed(1)}px');
    debugPrint('  قابل للقراءة: ${result.fontAnalysis.isReadable ? 'نعم' : 'لا'}');
    debugPrint('  نسبة التدرج: ${result.fontAnalysis.scaleRatio.toStringAsFixed(2)}');
    
    debugPrint('\n📐 تحليل المسافات:');
    debugPrint('  المسافة الأساسية: ${result.spacingAnalysis.baseSpacing.toStringAsFixed(1)}px');
    debugPrint('  متسق: ${result.spacingAnalysis.isConsistent ? 'نعم' : 'لا'}');
    debugPrint('  الكثافة: ${result.spacingAnalysis.density.toStringAsFixed(2)}');
    
    debugPrint('\n🎨 تحليل الأيقونات:');
    debugPrint('  حجم الأيقونة: ${result.iconAnalysis.iconSize.toStringAsFixed(1)}px');
    debugPrint('  مناسب للمس: ${result.iconAnalysis.isTouchFriendly ? 'نعم' : 'لا'}');
    debugPrint('  متوازن بصرياً: ${result.iconAnalysis.isVisuallyBalanced ? 'نعم' : 'لا'}');
    
    debugPrint('\n🏆 النتيجة الإجمالية: ${result.overallScore}/100');
    
    debugPrint('\n💡 التوصيات:');
    for (final recommendation in result.recommendations) {
      debugPrint('  $recommendation');
    }
    
    debugPrint('═══════════════════════════════════════');
  }
}

/// نتيجة تحليل التجاوب
class ResponsiveAnalysisResult {
  late DeviceAnalysis deviceInfo;
  late BreakpointAnalysis breakpointAnalysis;
  late FontAnalysis fontAnalysis;
  late SpacingAnalysis spacingAnalysis;
  late IconAnalysis iconAnalysis;
  late int overallScore;
  late List<String> recommendations;
}

/// تحليل معلومات الجهاز
class DeviceAnalysis {
  final DeviceType deviceType;
  final double screenWidth;
  final double screenHeight;
  final bool isLandscape;
  final double aspectRatio;
  final double pixelDensity;

  DeviceAnalysis({
    required this.deviceType,
    required this.screenWidth,
    required this.screenHeight,
    required this.isLandscape,
    required this.aspectRatio,
    required this.pixelDensity,
  });
}

/// تحليل نقاط التوقف
class BreakpointAnalysis {
  final DeviceType currentBreakpoint;
  final bool isOptimalSize;
  final double distanceToNextBreakpoint;
  final int recommendedColumns;

  BreakpointAnalysis({
    required this.currentBreakpoint,
    required this.isOptimalSize,
    required this.distanceToNextBreakpoint,
    required this.recommendedColumns,
  });
}

/// تحليل الخطوط
class FontAnalysis {
  final double baseFontSize;
  final double headingFontSize;
  final bool isReadable;
  final double scaleRatio;

  FontAnalysis({
    required this.baseFontSize,
    required this.headingFontSize,
    required this.isReadable,
    required this.scaleRatio,
  });
}

/// تحليل المسافات
class SpacingAnalysis {
  final double baseSpacing;
  final EdgeInsets padding;
  final bool isConsistent;
  final double density;

  SpacingAnalysis({
    required this.baseSpacing,
    required this.padding,
    required this.isConsistent,
    required this.density,
  });
}

/// تحليل الأيقونات
class IconAnalysis {
  final double iconSize;
  final bool isTouchFriendly;
  final bool isVisuallyBalanced;

  IconAnalysis({
    required this.iconSize,
    required this.isTouchFriendly,
    required this.isVisuallyBalanced,
  });
}
