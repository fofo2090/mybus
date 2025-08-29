import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

/// Dialog متجاوب يتكيف مع حجم الشاشة
class ResponsiveDialog extends StatelessWidget {
  final String? title;
  final Widget? titleWidget;
  final Widget content;
  final List<Widget>? actions;
  final EdgeInsets? contentPadding;
  final EdgeInsets? actionsPadding;
  final Color? backgroundColor;
  final double? elevation;
  final ShapeBorder? shape;
  final bool scrollable;
  final MainAxisAlignment? actionsAlignment;

  const ResponsiveDialog({
    super.key,
    this.title,
    this.titleWidget,
    required this.content,
    this.actions,
    this.contentPadding,
    this.actionsPadding,
    this.backgroundColor,
    this.elevation,
    this.shape,
    this.scrollable = false,
    this.actionsAlignment,
  });

  @override
  Widget build(BuildContext context) {
    final responsiveContentPadding = contentPadding ?? ResponsiveHelper.getPadding(context,
      mobilePadding: const EdgeInsets.all(16),
      tabletPadding: const EdgeInsets.all(20),
      desktopPadding: const EdgeInsets.all(24),
    );

    final responsiveActionsPadding = actionsPadding ?? ResponsiveHelper.getPadding(context,
      mobilePadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      tabletPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      desktopPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
    );

    final responsiveShape = shape ?? RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(ResponsiveHelper.getBorderRadius(context)),
    );

    // في الشاشات الصغيرة، نجعل الحوار يأخذ عرض أكبر
    final dialogWidth = ResponsiveHelper.isMobile(context) 
        ? MediaQuery.of(context).size.width * 0.9
        : ResponsiveHelper.isTablet(context)
            ? MediaQuery.of(context).size.width * 0.7
            : MediaQuery.of(context).size.width * 0.5;

    Widget? titleWidget = this.titleWidget;
    if (title != null && titleWidget == null) {
      titleWidget = Text(
        title!,
        style: TextStyle(
          fontSize: ResponsiveHelper.getFontSize(context,
            mobileFontSize: 18,
            tabletFontSize: 20,
            desktopFontSize: 22,
          ),
          fontWeight: FontWeight.bold,
        ),
      );
    }

    return Dialog(
      backgroundColor: backgroundColor,
      elevation: elevation,
      shape: responsiveShape,
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: ResponsiveHelper.getMaxContentWidth(context),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (titleWidget != null)
              Padding(
                padding: responsiveContentPadding.copyWith(bottom: 0),
                child: titleWidget,
              ),
            
            Flexible(
              child: scrollable
                  ? SingleChildScrollView(
                      padding: responsiveContentPadding,
                      child: content,
                    )
                  : Padding(
                      padding: responsiveContentPadding,
                      child: content,
                    ),
            ),
            
            if (actions != null && actions!.isNotEmpty)
              Padding(
                padding: responsiveActionsPadding,
                child: ResponsiveHelper.isMobile(context)
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: actions!
                            .map((action) => Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: action,
                                ))
                            .toList(),
                      )
                    : Row(
                        mainAxisAlignment: actionsAlignment ?? MainAxisAlignment.end,
                        children: actions!
                            .expand((action) => [
                                  action,
                                  if (action != actions!.last)
                                    SizedBox(width: ResponsiveHelper.getSpacing(context)),
                                ])
                            .toList(),
                      ),
              ),
          ],
        ),
      ),
    );
  }

  /// عرض الحوار المتجاوب
  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    Widget? titleWidget,
    required Widget content,
    List<Widget>? actions,
    bool barrierDismissible = true,
    Color? barrierColor,
    String? barrierLabel,
    bool scrollable = false,
    MainAxisAlignment? actionsAlignment,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      barrierLabel: barrierLabel,
      builder: (context) => ResponsiveDialog(
        title: title,
        titleWidget: titleWidget,
        content: content,
        actions: actions,
        scrollable: scrollable,
        actionsAlignment: actionsAlignment,
      ),
    );
  }
}

/// BottomSheet متجاوب
class ResponsiveBottomSheet extends StatelessWidget {
  final Widget child;
  final String? title;
  final EdgeInsets? padding;
  final double? maxHeight;
  final bool showHandle;
  final Color? backgroundColor;
  final ShapeBorder? shape;

  const ResponsiveBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.padding,
    this.maxHeight,
    this.showHandle = true,
    this.backgroundColor,
    this.shape,
  });

  @override
  Widget build(BuildContext context) {
    final responsivePadding = padding ?? ResponsiveHelper.getPadding(context);
    final responsiveMaxHeight = maxHeight ?? MediaQuery.of(context).size.height * 0.8;

    final responsiveShape = shape ?? RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(ResponsiveHelper.getBorderRadius(context) * 1.5),
      ),
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: responsiveMaxHeight,
        maxWidth: ResponsiveHelper.getMaxContentWidth(context),
      ),
      decoration: ShapeDecoration(
        color: backgroundColor ?? Colors.white,
        shape: responsiveShape,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showHandle)
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: ResponsiveHelper.isMobile(context) ? 40 : 60,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          
          if (title != null)
            Padding(
              padding: responsivePadding.copyWith(bottom: 0),
              child: Text(
                title!,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getFontSize(context,
                    mobileFontSize: 18,
                    tabletFontSize: 20,
                    desktopFontSize: 22,
                  ),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          
          Flexible(
            child: Padding(
              padding: responsivePadding,
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  /// عرض BottomSheet متجاوب
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    EdgeInsets? padding,
    double? maxHeight,
    bool showHandle = true,
    Color? backgroundColor,
    ShapeBorder? shape,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      builder: (context) => ResponsiveBottomSheet(
        title: title,
        padding: padding,
        maxHeight: maxHeight,
        showHandle: showHandle,
        backgroundColor: backgroundColor,
        shape: shape,
        child: child,
      ),
    );
  }
}

/// AlertDialog متجاوب مع أزرار متكيفة
class ResponsiveAlertDialog extends StatelessWidget {
  final String? title;
  final String? content;
  final Widget? titleWidget;
  final Widget? contentWidget;
  final String? confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final Color? confirmColor;
  final Color? cancelColor;
  final IconData? icon;
  final Color? iconColor;

  const ResponsiveAlertDialog({
    super.key,
    this.title,
    this.content,
    this.titleWidget,
    this.contentWidget,
    this.confirmText,
    this.cancelText,
    this.onConfirm,
    this.onCancel,
    this.confirmColor,
    this.cancelColor,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[];
    
    if (cancelText != null || onCancel != null) {
      actions.add(
        TextButton(
          onPressed: onCancel ?? () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(
            foregroundColor: cancelColor ?? Colors.grey.shade600,
          ),
          child: Text(
            cancelText ?? 'إلغاء',
            style: TextStyle(
              fontSize: ResponsiveHelper.getFontSize(context,
                mobileFontSize: 14,
                tabletFontSize: 16,
                desktopFontSize: 18,
              ),
            ),
          ),
        ),
      );
    }
    
    if (confirmText != null || onConfirm != null) {
      actions.add(
        ElevatedButton(
          onPressed: onConfirm ?? () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor ?? const Color(0xFF1E88E5),
            foregroundColor: Colors.white,
          ),
          child: Text(
            confirmText ?? 'تأكيد',
            style: TextStyle(
              fontSize: ResponsiveHelper.getFontSize(context,
                mobileFontSize: 14,
                tabletFontSize: 16,
                desktopFontSize: 18,
              ),
            ),
          ),
        ),
      );
    }

    Widget? titleWidget = this.titleWidget;
    if (title != null && titleWidget == null) {
      titleWidget = Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: iconColor ?? const Color(0xFF1E88E5),
              size: ResponsiveHelper.getIconSize(context,
                mobileSize: 20,
                tabletSize: 24,
                desktopSize: 28,
              ),
            ),
            SizedBox(width: ResponsiveHelper.getSpacing(context) * 0.5),
          ],
          Expanded(
            child: Text(
              title!,
              style: TextStyle(
                fontSize: ResponsiveHelper.getFontSize(context,
                  mobileFontSize: 16,
                  tabletFontSize: 18,
                  desktopFontSize: 20,
                ),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    }

    Widget? contentWidget = this.contentWidget;
    if (content != null && contentWidget == null) {
      contentWidget = Text(
        content!,
        style: TextStyle(
          fontSize: ResponsiveHelper.getFontSize(context,
            mobileFontSize: 14,
            tabletFontSize: 16,
            desktopFontSize: 18,
          ),
        ),
      );
    }

    return ResponsiveDialog(
      titleWidget: titleWidget,
      content: contentWidget ?? const SizedBox(),
      actions: actions,
      scrollable: true,
    );
  }

  /// عرض تأكيد متجاوب
  static Future<bool?> showConfirmation({
    required BuildContext context,
    String? title,
    String? content,
    String? confirmText,
    String? cancelText,
    Color? confirmColor,
    Color? cancelColor,
    IconData? icon,
    Color? iconColor,
  }) {
    return ResponsiveDialog.show<bool>(
      context: context,
      content: ResponsiveAlertDialog(
        title: title,
        content: content,
        confirmText: confirmText,
        cancelText: cancelText,
        confirmColor: confirmColor,
        cancelColor: cancelColor,
        icon: icon,
        iconColor: iconColor,
      ),
    );
  }
}
