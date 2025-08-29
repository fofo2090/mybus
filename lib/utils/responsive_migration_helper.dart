import 'package:flutter/material.dart';
import '../widgets/responsive_widgets.dart';

/// مساعد لتحديث الـ widgets الموجودة للنظام المتجاوب الجديد
class ResponsiveMigrationHelper {
  
  /// تحويل Text عادي إلى ResponsiveText
  static Widget migrateText(Text originalText) {
    final style = originalText.style;
    final fontSize = style?.fontSize;
    
    // تحديد نوع النص بناءً على حجم الخط
    if (fontSize != null) {
      if (fontSize >= 24) {
        return ResponsiveTitle(
          originalText.data ?? '',
          color: style?.color,
          textAlign: originalText.textAlign,
          maxLines: originalText.maxLines,
          overflow: originalText.overflow,
        );
      } else if (fontSize >= 18) {
        return ResponsiveSubtitle(
          originalText.data ?? '',
          color: style?.color,
          textAlign: originalText.textAlign,
          maxLines: originalText.maxLines,
          overflow: originalText.overflow,
        );
      } else if (fontSize <= 12) {
        return ResponsiveSmall(
          originalText.data ?? '',
          color: style?.color,
          textAlign: originalText.textAlign,
          maxLines: originalText.maxLines,
          overflow: originalText.overflow,
        );
      }
    }
    
    // النص العادي
    return ResponsiveBody(
      originalText.data ?? '',
      color: style?.color,
      textAlign: originalText.textAlign,
      maxLines: originalText.maxLines,
      overflow: originalText.overflow,
    );
  }
  
  /// تحويل Container عادي إلى ResponsiveContainer
  static Widget migrateContainer(Container originalContainer) {
    return ResponsiveContainer(
      padding: originalContainer.padding,
      margin: originalContainer.margin,
      backgroundColor: originalContainer.color,
      child: originalContainer.child ?? const SizedBox(),
    );
  }
  
  /// تحويل GridView عادي إلى ResponsiveGrid
  static Widget migrateGridView(GridView originalGrid) {
    final delegate = originalGrid.gridDelegate;
    
    if (delegate is SliverGridDelegateWithFixedCrossAxisCount) {
      return ResponsiveGridEnhanced(
        mobileColumns: delegate.crossAxisCount == 1 ? 1 : 1,
        tabletColumns: delegate.crossAxisCount <= 2 ? 2 : delegate.crossAxisCount,
        desktopColumns: delegate.crossAxisCount <= 3 ? 3 : delegate.crossAxisCount,
        largeDesktopColumns: delegate.crossAxisCount + 1,
        shrinkWrap: originalGrid.shrinkWrap,
        physics: originalGrid.physics,
        padding: originalGrid.padding,
        children: _extractGridChildren(originalGrid),
      );
    }
    
    // إذا لم نستطع التحويل، نرجع ResponsiveCardGrid بسيط
    return ResponsiveCardGrid(
      shrinkWrap: originalGrid.shrinkWrap,
      physics: originalGrid.physics,
      padding: originalGrid.padding,
      children: _extractGridChildren(originalGrid),
    );
  }
  
  /// تحويل ElevatedButton إلى ResponsiveButton
  static Widget migrateElevatedButton(ElevatedButton originalButton) {
    return ResponsiveButtonEnhanced(
      onPressed: originalButton.onPressed,
      style: originalButton.style,
      child: originalButton.child ?? const Text(''),
    );
  }
  
  /// تحويل OutlinedButton إلى ResponsiveButton
  static Widget migrateOutlinedButton(OutlinedButton originalButton) {
    return ResponsiveButtonEnhanced(
      onPressed: originalButton.onPressed,
      style: originalButton.style,
      buttonType: ButtonType.outlined,
      child: originalButton.child ?? const Text(''),
    );
  }
  
  /// تحويل TextButton إلى ResponsiveButton
  static Widget migrateTextButton(TextButton originalButton) {
    return ResponsiveButtonEnhanced(
      onPressed: originalButton.onPressed,
      style: originalButton.style,
      buttonType: ButtonType.text,
      child: originalButton.child ?? const Text(''),
    );
  }
  
  /// تحويل Card إلى ResponsiveCard
  static Widget migrateCard(Card originalCard) {
    return ResponsiveCard(
      color: originalCard.color,
      elevation: originalCard.elevation,
      margin: originalCard.margin,
      child: originalCard.child ?? const SizedBox(),
    );
  }
  
  /// تحويل Padding إلى ResponsiveContainer مع padding
  static Widget migratePadding(Padding originalPadding) {
    return ResponsiveContainer(
      padding: originalPadding.padding,
      child: originalPadding.child,
    );
  }
  
  /// تحويل SizedBox إلى ResponsiveSpace
  static Widget migrateSizedBox(SizedBox originalSizedBox) {
    if (originalSizedBox.width != null && originalSizedBox.width! > 0) {
      return ResponsiveHorizontalSpace(
        multiplier: originalSizedBox.width! / 16, // افتراض أن 16 هو الأساس
      );
    }
    
    if (originalSizedBox.height != null && originalSizedBox.height! > 0) {
      return ResponsiveVerticalSpace(
        multiplier: originalSizedBox.height! / 16, // افتراض أن 16 هو الأساس
      );
    }
    
    return const ResponsiveVerticalSpace();
  }
  
  /// استخراج أطفال GridView
  static List<Widget> _extractGridChildren(GridView gridView) {
    // هذا مبسط - في الواقع قد نحتاج لمعالجة أكثر تعقيداً
    if (gridView.children.isNotEmpty) {
      return gridView.children;
    }
    
    // إذا كان يستخدم builder، نحتاج لمعالجة مختلفة
    return [];
  }
  
  /// تحليل widget وإعطاء توصيات للتحديث
  static List<MigrationRecommendation> analyzeWidget(Widget widget) {
    List<MigrationRecommendation> recommendations = [];
    
    if (widget is Text) {
      recommendations.add(MigrationRecommendation(
        widgetType: 'Text',
        currentWidget: widget.toString(),
        recommendation: 'استخدم ResponsiveText بدلاً من Text للحصول على أحجام خط متجاوبة',
        priority: MigrationPriority.high,
        migrationCode: 'ResponsiveBody("${widget.data}")',
      ));
    }
    
    if (widget is Container && widget.child != null) {
      recommendations.add(MigrationRecommendation(
        widgetType: 'Container',
        currentWidget: widget.toString(),
        recommendation: 'استخدم ResponsiveContainer للحصول على padding ومساحات متجاوبة',
        priority: MigrationPriority.medium,
        migrationCode: 'ResponsiveContainer(child: ...)',
      ));
    }
    
    if (widget is GridView) {
      recommendations.add(MigrationRecommendation(
        widgetType: 'GridView',
        currentWidget: widget.toString(),
        recommendation: 'استخدم ResponsiveGridEnhanced للحصول على شبكة متكيفة مع جميع الشاشات',
        priority: MigrationPriority.high,
        migrationCode: 'ResponsiveGridEnhanced(mobileColumns: 1, tabletColumns: 2, ...)',
      ));
    }
    
    if (widget is ElevatedButton || widget is OutlinedButton || widget is TextButton) {
      recommendations.add(MigrationRecommendation(
        widgetType: widget.runtimeType.toString(),
        currentWidget: widget.toString(),
        recommendation: 'استخدم ResponsiveButtonEnhanced للحصول على أزرار متجاوبة مع حالات تحميل',
        priority: MigrationPriority.medium,
        migrationCode: 'ResponsiveButtonEnhanced(onPressed: ..., child: ...)',
      ));
    }
    
    return recommendations;
  }
  
  /// تحليل شجرة widgets كاملة
  static List<MigrationRecommendation> analyzeWidgetTree(Widget root) {
    List<MigrationRecommendation> allRecommendations = [];
    
    void analyzeRecursively(Widget widget) {
      allRecommendations.addAll(analyzeWidget(widget));
      
      // تحليل الأطفال (مبسط)
      if (widget is SingleChildRenderObjectWidget && widget.child != null) {
        analyzeRecursively(widget.child!);
      }
      
      if (widget is MultiChildRenderObjectWidget) {
        for (final child in widget.children) {
          analyzeRecursively(child);
        }
      }
    }
    
    analyzeRecursively(root);
    return allRecommendations;
  }
}

/// توصية للتحديث
class MigrationRecommendation {
  final String widgetType;
  final String currentWidget;
  final String recommendation;
  final MigrationPriority priority;
  final String migrationCode;
  
  MigrationRecommendation({
    required this.widgetType,
    required this.currentWidget,
    required this.recommendation,
    required this.priority,
    required this.migrationCode,
  });
  
  @override
  String toString() {
    return '[$priority] $widgetType: $recommendation\nكود التحديث: $migrationCode\n';
  }
}

/// أولوية التحديث
enum MigrationPriority {
  high,
  medium,
  low,
}

/// مساحة أفقية متجاوبة
class ResponsiveHorizontalSpace extends StatelessWidget {
  final double multiplier;
  
  const ResponsiveHorizontalSpace({
    super.key,
    this.multiplier = 1.0,
  });
  
  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveHelper.getSpacing(context) * multiplier;
    return SizedBox(width: spacing);
  }
}

/// مساحة عمودية متجاوبة
class ResponsiveVerticalSpace extends StatelessWidget {
  final double multiplier;
  
  const ResponsiveVerticalSpace({
    super.key,
    this.multiplier = 1.0,
  });
  
  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveHelper.getSpacing(context) * multiplier;
    return SizedBox(height: spacing);
  }
}