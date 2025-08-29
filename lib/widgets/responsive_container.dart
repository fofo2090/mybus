import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

/// حاوي متجاوب يضمن التخطيط المثالي على جميع الشاشات
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? maxWidth;
  final bool centerContent;
  final bool addSafeArea;
  final Color? backgroundColor;
  final Alignment alignment;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.maxWidth,
    this.centerContent = true,
    this.addSafeArea = true,
    this.backgroundColor,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = ResponsiveHelper.getScreenWidth(context);
    final deviceType = ResponsiveHelper.getDeviceType(context);
    
    // تحديد العرض الأقصى بناءً على نوع الجهاز
    final effectiveMaxWidth = maxWidth ?? ResponsiveHelper.getMaxContentWidth(context);
    
    // تحديد الحشو المناسب
    final effectivePadding = padding ?? ResponsiveHelper.getPadding(context,
      mobilePadding: const EdgeInsets.all(16),
      tabletPadding: const EdgeInsets.all(24),
      desktopPadding: const EdgeInsets.all(32),
      largeDesktopPadding: const EdgeInsets.all(40),
    );

    // تحديد الهامش المناسب
    final effectiveMargin = margin ?? EdgeInsets.zero;

    Widget content = Container(
      width: screenWidth > effectiveMaxWidth ? effectiveMaxWidth : double.infinity,
      margin: effectiveMargin,
      padding: effectivePadding,
      decoration: backgroundColor != null 
        ? BoxDecoration(color: backgroundColor)
        : null,
      child: child,
    );

    // إضافة محاذاة للمحتوى في الشاشات الكبيرة
    if (centerContent && screenWidth > effectiveMaxWidth) {
      content = Align(
        alignment: alignment,
        child: content,
      );
    }

    // إضافة SafeArea إذا لزم الأمر
    if (addSafeArea) {
      content = SafeArea(child: content);
    }

    return content;
  }
}

/// حاوي متجاوب للصفحات الكاملة
class ResponsivePageContainer extends StatelessWidget {
  final Widget child;
  final bool addScrolling;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final bool addSafeArea;

  const ResponsivePageContainer({
    super.key,
    required this.child,
    this.addScrolling = true,
    this.padding,
    this.backgroundColor,
    this.addSafeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = ResponsiveContainer(
      padding: padding,
      backgroundColor: backgroundColor,
      addSafeArea: addSafeArea,
      child: child,
    );

    if (addScrolling) {
      content = SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: content,
      );
    }

    return content;
  }
}

/// حاوي متجاوب للنماذج
class ResponsiveFormContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? maxWidth;
  final bool addCard;
  final Color? cardColor;

  const ResponsiveFormContainer({
    super.key,
    required this.child,
    this.padding,
    this.maxWidth,
    this.addCard = true,
    this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = ResponsiveHelper.getDeviceType(context);
    
    // تحديد العرض الأقصى للنماذج
    final formMaxWidth = maxWidth ?? (deviceType == DeviceType.mobile ? double.infinity : 600);
    
    Widget content = ResponsiveContainer(
      maxWidth: formMaxWidth,
      padding: padding,
      child: child,
    );

    if (addCard) {
      content = Card(
        color: cardColor,
        elevation: ResponsiveHelper.isMobile(context) ? 2 : 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getBorderRadius(context),
          ),
        ),
        child: Padding(
          padding: ResponsiveHelper.getPadding(context),
          child: content,
        ),
      );
    }

    return content;
  }
}

/// حاوي متجاوب للمحتوى الجانبي
class ResponsiveSidebarContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final Color? backgroundColor;
  final bool addBorder;

  const ResponsiveSidebarContainer({
    super.key,
    required this.child,
    this.width,
    this.backgroundColor,
    this.addBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = ResponsiveHelper.getDeviceType(context);
    
    // تحديد عرض الشريط الجانبي
    final sidebarWidth = width ?? (deviceType == DeviceType.mobile ? 280 : 320);
    
    return Container(
      width: sidebarWidth,
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).cardColor,
        border: addBorder ? Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ) : null,
      ),
      child: child,
    );
  }
}

/// حاوي متجاوب للمحتوى الرئيسي مع شريط جانبي
class ResponsiveLayoutContainer extends StatelessWidget {
  final Widget sidebar;
  final Widget content;
  final bool showSidebar;
  final double? sidebarWidth;

  const ResponsiveLayoutContainer({
    super.key,
    required this.sidebar,
    required this.content,
    this.showSidebar = true,
    this.sidebarWidth,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = ResponsiveHelper.getDeviceType(context);
    final isMobile = deviceType == DeviceType.mobile;

    if (isMobile || !showSidebar) {
      return content;
    }

    return Row(
      children: [
        ResponsiveSidebarContainer(
          width: sidebarWidth,
          child: sidebar,
        ),
        Expanded(
          child: content,
        ),
      ],
    );
  }
}