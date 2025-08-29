import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

/// شبكة متجاوبة محسنة مع تحكم دقيق في التخطيط
class ResponsiveGridEnhanced extends StatelessWidget {
  final List<Widget> children;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final int? largeDesktopColumns;
  final double? mobileSpacing;
  final double? tabletSpacing;
  final double? desktopSpacing;
  final double? largeDesktopSpacing;
  final double? mobileAspectRatio;
  final double? tabletAspectRatio;
  final double? desktopAspectRatio;
  final double? largeDesktopAspectRatio;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsets? padding;
  final bool addCard;
  final double? minItemWidth;
  final double? maxItemWidth;

  const ResponsiveGridEnhanced({
    super.key,
    required this.children,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
    this.largeDesktopColumns,
    this.mobileSpacing,
    this.tabletSpacing,
    this.desktopSpacing,
    this.largeDesktopSpacing,
    this.mobileAspectRatio,
    this.tabletAspectRatio,
    this.desktopAspectRatio,
    this.largeDesktopAspectRatio,
    this.shrinkWrap = false,
    this.physics,
    this.padding,
    this.addCard = false,
    this.minItemWidth,
    this.maxItemWidth,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = ResponsiveHelper.getDeviceType(context);
    final screenWidth = ResponsiveHelper.getScreenWidth(context);
    
    // تحديد عدد الأعمدة بناءً على نوع الجهاز
    int columns = _getColumns(deviceType);
    
    // تحديد المسافات
    final spacing = _getSpacing(deviceType);
    
    // تحديد نسبة العرض إلى الارتفاع
    final aspectRatio = _getAspectRatio(deviceType);
    
    // إذا تم تحديد عرض أدنى وأقصى، احسب الأعمدة تلقائياً
    if (minItemWidth != null) {
      final availableWidth = screenWidth - (padding?.horizontal ?? 0);
      final itemWidth = minItemWidth!;
      final calculatedColumns = (availableWidth / (itemWidth + spacing)).floor();
      columns = calculatedColumns > 0 ? calculatedColumns : 1;
      
      // تطبيق الحد الأقصى للعرض إذا لزم الأمر
      if (maxItemWidth != null) {
        final maxColumns = (availableWidth / (maxItemWidth! + spacing)).floor();
        columns = columns > maxColumns ? maxColumns : columns;
      }
    }

    Widget grid = GridView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: padding ?? ResponsiveHelper.getPadding(context),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: aspectRatio,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) {
        Widget child = children[index];
        
        if (addCard) {
          child = Card(
            elevation: ResponsiveHelper.isMobile(context) ? 2 : 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getBorderRadius(context),
              ),
            ),
            child: child,
          );
        }
        
        return child;
      },
    );

    return grid;
  }

  int _getColumns(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.mobile:
        return mobileColumns ?? 1;
      case DeviceType.tablet:
        return tabletColumns ?? 2;
      case DeviceType.desktop:
        return desktopColumns ?? 3;
      case DeviceType.largeDesktop:
        return largeDesktopColumns ?? 4;
    }
  }

  double _getSpacing(DeviceType deviceType) {
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

  double _getAspectRatio(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.mobile:
        return mobileAspectRatio ?? 1.0;
      case DeviceType.tablet:
        return tabletAspectRatio ?? 1.1;
      case DeviceType.desktop:
        return desktopAspectRatio ?? 1.2;
      case DeviceType.largeDesktop:
        return largeDesktopAspectRatio ?? 1.3;
    }
  }
}

/// شبكة متجاوبة للبطاقات
class ResponsiveCardGrid extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const ResponsiveCardGrid({
    super.key,
    required this.children,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveGridEnhanced(
      children: children,
      mobileColumns: 1,
      tabletColumns: 2,
      desktopColumns: 3,
      largeDesktopColumns: 4,
      mobileAspectRatio: 1.2,
      tabletAspectRatio: 1.1,
      desktopAspectRatio: 1.0,
      largeDesktopAspectRatio: 0.9,
      addCard: true,
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: padding,
    );
  }
}

/// شبكة متجاوبة للأيقونات والإجراءات
class ResponsiveActionGrid extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const ResponsiveActionGrid({
    super.key,
    required this.children,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveGridEnhanced(
      children: children,
      mobileColumns: 2,
      tabletColumns: 3,
      desktopColumns: 4,
      largeDesktopColumns: 6,
      mobileAspectRatio: 1.0,
      tabletAspectRatio: 1.0,
      desktopAspectRatio: 1.0,
      largeDesktopAspectRatio: 1.0,
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: padding,
    );
  }
}

/// شبكة متجاوبة تلقائية بناءً على عرض العناصر
class ResponsiveAutoGrid extends StatelessWidget {
  final List<Widget> children;
  final double minItemWidth;
  final double? maxItemWidth;
  final double spacing;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final double aspectRatio;

  const ResponsiveAutoGrid({
    super.key,
    required this.children,
    required this.minItemWidth,
    this.maxItemWidth,
    this.spacing = 16.0,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.aspectRatio = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveGridEnhanced(
      children: children,
      minItemWidth: minItemWidth,
      maxItemWidth: maxItemWidth,
      mobileSpacing: spacing,
      tabletSpacing: spacing,
      desktopSpacing: spacing,
      largeDesktopSpacing: spacing,
      mobileAspectRatio: aspectRatio,
      tabletAspectRatio: aspectRatio,
      desktopAspectRatio: aspectRatio,
      largeDesktopAspectRatio: aspectRatio,
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: padding,
    );
  }
}