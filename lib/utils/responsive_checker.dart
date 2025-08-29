import 'package:flutter/material.dart';
import 'responsive_helper.dart';

/// مساعد للتحقق من التجاوب وإعطاء توصيات
class ResponsiveChecker {
  
  /// فحص شامل للتجاوب
  static ResponsiveAnalysis analyzeScreen(BuildContext context) {
    final deviceType = ResponsiveHelper.getDeviceType(context);
    final screenWidth = ResponsiveHelper.getScreenWidth(context);
    final screenHeight = ResponsiveHelper.getScreenHeight(context);
    final isLandscape = ResponsiveHelper.isLandscape(context);
    
    List<ResponsiveIssue> issues = [];
    List<ResponsiveRecommendation> recommendations = [];
    
    // فحص العرض
    _checkScreenWidth(screenWidth, deviceType, issues, recommendations);
    
    // فحص الارتفاع
    _checkScreenHeight(screenHeight, deviceType, issues, recommendations);
    
    // فحص الاتجاه
    _checkOrientation(isLandscape, deviceType, issues, recommendations);
    
    // فحص نسبة العرض إلى الارتفاع
    _checkAspectRatio(screenWidth, screenHeight, issues, recommendations);
    
    // حساب النتيجة الإجمالية
    final score = _calculateScore(issues);
    
    return ResponsiveAnalysis(
      deviceType: deviceType,
      screenWidth: screenWidth,
      screenHeight: screenHeight,
      isLandscape: isLandscape,
      issues: issues,
      recommendations: recommendations,
      score: score,
    );
  }
  
  /// فحص العرض
  static void _checkScreenWidth(double width, DeviceType deviceType, 
      List<ResponsiveIssue> issues, List<ResponsiveRecommendation> recommendations) {
    
    if (deviceType == DeviceType.mobile && width > 600) {
      issues.add(ResponsiveIssue(
        type: IssueType.warning,
        message: 'الجهاز مصنف كموبايل لكن العرض كبير ($width px)',
        severity: IssueSeverity.medium,
      ));
    }
    
    if (width < 320) {
      issues.add(ResponsiveIssue(
        type: IssueType.error,
        message: 'العرض صغير جداً ($width px) - قد يسبب مشاكل في التخطيط',
        severity: IssueSeverity.high,
      ));
      recommendations.add(ResponsiveRecommendation(
        message: 'استخدم SingleChildScrollView أفقي للمحتوى الواسع',
        priority: RecommendationPriority.high,
      ));
    }
    
    if (width > 1920) {
      recommendations.add(ResponsiveRecommendation(
        message: 'الشاشة كبيرة جداً - فكر في تحديد عرض أقصى للمحتوى',
        priority: RecommendationPriority.medium,
      ));
    }
  }
  
  /// فحص الارتفاع
  static void _checkScreenHeight(double height, DeviceType deviceType,
      List<ResponsiveIssue> issues, List<ResponsiveRecommendation> recommendations) {
    
    if (height < 600) {
      issues.add(ResponsiveIssue(
        type: IssueType.warning,
        message: 'الارتفاع صغير ($height px) - قد يحتاج تمرير',
        severity: IssueSeverity.medium,
      ));
      recommendations.add(ResponsiveRecommendation(
        message: 'استخدم SingleChildScrollView للمحتوى الطويل',
        priority: RecommendationPriority.high,
      ));
    }
    
    if (deviceType == DeviceType.mobile && height > 1000) {
      recommendations.add(ResponsiveRecommendation(
        message: 'الشاشة طويلة - استغل المساحة الإضافية بذكاء',
        priority: RecommendationPriority.low,
      ));
    }
  }
  
  /// فحص الاتجاه
  static void _checkOrientation(bool isLandscape, DeviceType deviceType,
      List<ResponsiveIssue> issues, List<ResponsiveRecommendation> recommendations) {
    
    if (isLandscape && deviceType == DeviceType.mobile) {
      recommendations.add(ResponsiveRecommendation(
        message: 'في الوضع الأفقي، فكر في تخطيط مختلف للاستفادة من العرض',
        priority: RecommendationPriority.medium,
      ));
    }
    
    if (!isLandscape && deviceType == DeviceType.desktop) {
      issues.add(ResponsiveIssue(
        type: IssueType.info,
        message: 'سطح المكتب في وضع عمودي - تخطيط غير مألوف',
        severity: IssueSeverity.low,
      ));
    }
  }
  
  /// فحص نسبة العرض إلى الارتفاع
  static void _checkAspectRatio(double width, double height,
      List<ResponsiveIssue> issues, List<ResponsiveRecommendation> recommendations) {
    
    final aspectRatio = width / height;
    
    if (aspectRatio < 0.5) {
      issues.add(ResponsiveIssue(
        type: IssueType.warning,
        message: 'الشاشة طويلة جداً (نسبة $aspectRatio) - قد تحتاج تخطيط خاص',
        severity: IssueSeverity.medium,
      ));
    }
    
    if (aspectRatio > 3.0) {
      issues.add(ResponsiveIssue(
        type: IssueType.warning,
        message: 'الشاشة عريضة جداً (نسبة $aspectRatio) - قد تحتاج تخطيط خاص',
        severity: IssueSeverity.medium,
      ));
    }
  }
  
  /// حساب النتيجة الإجمالية
  static int _calculateScore(List<ResponsiveIssue> issues) {
    int score = 100;
    
    for (final issue in issues) {
      switch (issue.severity) {
        case IssueSeverity.high:
          score -= 20;
          break;
        case IssueSeverity.medium:
          score -= 10;
          break;
        case IssueSeverity.low:
          score -= 5;
          break;
      }
    }
    
    return score.clamp(0, 100);
  }
  
  /// فحص widget محدد
  static List<ResponsiveRecommendation> checkWidget(BuildContext context, Widget widget) {
    List<ResponsiveRecommendation> recommendations = [];
    
    // فحص النصوص
    if (widget is Text) {
      _checkTextWidget(context, widget, recommendations);
    }
    
    // فحص الأزرار
    if (widget is ElevatedButton || widget is OutlinedButton || widget is TextButton) {
      _checkButtonWidget(context, recommendations);
    }
    
    // فحص الحاويات
    if (widget is Container) {
      _checkContainerWidget(context, widget, recommendations);
    }
    
    return recommendations;
  }
  
  static void _checkTextWidget(BuildContext context, Text text, 
      List<ResponsiveRecommendation> recommendations) {
    
    final style = text.style;
    if (style?.fontSize != null) {
      final fontSize = style!.fontSize!;
      final deviceType = ResponsiveHelper.getDeviceType(context);
      
      if (deviceType == DeviceType.mobile && fontSize > 24) {
        recommendations.add(ResponsiveRecommendation(
          message: 'حجم الخط كبير للموبايل ($fontSize px)',
          priority: RecommendationPriority.medium,
        ));
      }
      
      if (deviceType == DeviceType.desktop && fontSize < 16) {
        recommendations.add(ResponsiveRecommendation(
          message: 'حجم الخط صغير لسطح المكتب ($fontSize px)',
          priority: RecommendationPriority.medium,
        ));
      }
    }
  }
  
  static void _checkButtonWidget(BuildContext context, 
      List<ResponsiveRecommendation> recommendations) {
    
    final isMobile = ResponsiveHelper.isMobile(context);
    
    if (isMobile) {
      recommendations.add(ResponsiveRecommendation(
        message: 'تأكد من أن الأزرار كبيرة بما يكفي للمس (44px على الأقل)',
        priority: RecommendationPriority.high,
      ));
    }
  }
  
  static void _checkContainerWidget(BuildContext context, Container container,
      List<ResponsiveRecommendation> recommendations) {
    
    if (container.constraints?.maxWidth == null) {
      final isDesktop = ResponsiveHelper.isDesktop(context);
      
      if (isDesktop) {
        recommendations.add(ResponsiveRecommendation(
          message: 'فكر في تحديد عرض أقصى للحاويات في الشاشات الكبيرة',
          priority: RecommendationPriority.low,
        ));
      }
    }
  }
}

/// تحليل التجاوب
class ResponsiveAnalysis {
  final DeviceType deviceType;
  final double screenWidth;
  final double screenHeight;
  final bool isLandscape;
  final List<ResponsiveIssue> issues;
  final List<ResponsiveRecommendation> recommendations;
  final int score;
  
  ResponsiveAnalysis({
    required this.deviceType,
    required this.screenWidth,
    required this.screenHeight,
    required this.isLandscape,
    required this.issues,
    required this.recommendations,
    required this.score,
  });
  
  /// هل التحليل جيد؟
  bool get isGood => score >= 80;
  
  /// هل التحليل مقبول؟
  bool get isAcceptable => score >= 60;
  
  /// هل التحليل سيء؟
  bool get isPoor => score < 60;
  
  /// الحصول على لون النتيجة
  Color get scoreColor {
    if (isGood) return Colors.green;
    if (isAcceptable) return Colors.orange;
    return Colors.red;
  }
  
  /// الحصول على أيقونة النتيجة
  IconData get scoreIcon {
    if (isGood) return Icons.check_circle;
    if (isAcceptable) return Icons.warning;
    return Icons.error;
  }
}

/// مشكلة في التجاوب
class ResponsiveIssue {
  final IssueType type;
  final String message;
  final IssueSeverity severity;
  
  ResponsiveIssue({
    required this.type,
    required this.message,
    required this.severity,
  });
}

/// توصية للتحسين
class ResponsiveRecommendation {
  final String message;
  final RecommendationPriority priority;
  
  ResponsiveRecommendation({
    required this.message,
    required this.priority,
  });
}

/// أنواع المشاكل
enum IssueType { error, warning, info }

/// شدة المشكلة
enum IssueSeverity { high, medium, low }

/// أولوية التوصية
enum RecommendationPriority { high, medium, low }