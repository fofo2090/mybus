import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

/// ElevatedButton متجاوب
class ResponsiveElevatedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final Size? minimumSize;
  final Size? maximumSize;
  final bool isLoading;
  final Widget? loadingWidget;

  const ResponsiveElevatedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.padding,
    this.borderRadius,
    this.minimumSize,
    this.maximumSize,
    this.isLoading = false,
    this.loadingWidget,
  });

  @override
  Widget build(BuildContext context) {
    final responsivePadding = padding ?? ResponsiveHelper.getPadding(context,
      mobilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      tabletPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      desktopPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    );

    final responsiveBorderRadius = borderRadius ?? 
        BorderRadius.circular(ResponsiveHelper.getBorderRadius(context));

    final responsiveMinimumSize = minimumSize ?? Size(
      ResponsiveHelper.isMobile(context) ? 120 : 140,
      ResponsiveHelper.getButtonHeight(context),
    );

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        elevation: elevation,
        padding: responsivePadding,
        shape: RoundedRectangleBorder(borderRadius: responsiveBorderRadius),
        minimumSize: responsiveMinimumSize,
        maximumSize: maximumSize,
      ),
      child: isLoading 
          ? (loadingWidget ?? SizedBox(
              width: ResponsiveHelper.getIconSize(context, mobileSize: 16, tabletSize: 18, desktopSize: 20),
              height: ResponsiveHelper.getIconSize(context, mobileSize: 16, tabletSize: 18, desktopSize: 20),
              child: const CircularProgressIndicator(strokeWidth: 2),
            ))
          : child,
    );
  }
}

/// OutlinedButton متجاوب
class ResponsiveOutlinedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final BorderSide? side;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final Size? minimumSize;
  final Size? maximumSize;

  const ResponsiveOutlinedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.foregroundColor,
    this.backgroundColor,
    this.side,
    this.padding,
    this.borderRadius,
    this.minimumSize,
    this.maximumSize,
  });

  @override
  Widget build(BuildContext context) {
    final responsivePadding = padding ?? ResponsiveHelper.getPadding(context,
      mobilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      tabletPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      desktopPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    );

    final responsiveBorderRadius = borderRadius ?? 
        BorderRadius.circular(ResponsiveHelper.getBorderRadius(context));

    final responsiveMinimumSize = minimumSize ?? Size(
      ResponsiveHelper.isMobile(context) ? 120 : 140,
      ResponsiveHelper.getButtonHeight(context),
    );

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: foregroundColor,
        backgroundColor: backgroundColor,
        side: side,
        padding: responsivePadding,
        shape: RoundedRectangleBorder(borderRadius: responsiveBorderRadius),
        minimumSize: responsiveMinimumSize,
        maximumSize: maximumSize,
      ),
      child: child,
    );
  }
}

/// TextButton متجاوب
class ResponsiveTextButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final Size? minimumSize;
  final Size? maximumSize;

  const ResponsiveTextButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.foregroundColor,
    this.backgroundColor,
    this.padding,
    this.borderRadius,
    this.minimumSize,
    this.maximumSize,
  });

  @override
  Widget build(BuildContext context) {
    final responsivePadding = padding ?? ResponsiveHelper.getPadding(context,
      mobilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      tabletPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      desktopPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    );

    final responsiveBorderRadius = borderRadius ?? 
        BorderRadius.circular(ResponsiveHelper.getBorderRadius(context));

    final responsiveMinimumSize = minimumSize ?? Size(
      ResponsiveHelper.isMobile(context) ? 80 : 100,
      ResponsiveHelper.getButtonHeight(context) * 0.8,
    );

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: foregroundColor,
        backgroundColor: backgroundColor,
        padding: responsivePadding,
        shape: RoundedRectangleBorder(borderRadius: responsiveBorderRadius),
        minimumSize: responsiveMinimumSize,
        maximumSize: maximumSize,
      ),
      child: child,
    );
  }
}

/// IconButton متجاوب
class ResponsiveIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final Color? color;
  final Color? backgroundColor;
  final double? iconSize;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final String? tooltip;

  const ResponsiveIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.color,
    this.backgroundColor,
    this.iconSize,
    this.padding,
    this.borderRadius,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final responsiveIconSize = iconSize ?? ResponsiveHelper.getIconSize(context);
    final responsivePadding = padding ?? ResponsiveHelper.getPadding(context,
      mobilePadding: const EdgeInsets.all(8),
      tabletPadding: const EdgeInsets.all(10),
      desktopPadding: const EdgeInsets.all(12),
    );

    if (backgroundColor != null) {
      return Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: borderRadius ?? BorderRadius.circular(ResponsiveHelper.getBorderRadius(context)),
        ),
        child: IconButton(
          onPressed: onPressed,
          icon: icon,
          color: color,
          iconSize: responsiveIconSize,
          padding: responsivePadding,
          tooltip: tooltip,
        ),
      );
    }

    return IconButton(
      onPressed: onPressed,
      icon: icon,
      color: color,
      iconSize: responsiveIconSize,
      padding: responsivePadding,
      tooltip: tooltip,
    );
  }
}

/// FloatingActionButton متجاوب
class ResponsiveFloatingActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final String? tooltip;
  final bool mini;

  const ResponsiveFloatingActionButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.tooltip,
    this.mini = false,
  });

  @override
  Widget build(BuildContext context) {
    // في الشاشات الصغيرة، نجعل الـ FAB أصغر
    final shouldBeMini = mini || ResponsiveHelper.isMobile(context);

    if (shouldBeMini) {
      return FloatingActionButton.small(
        onPressed: onPressed,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        elevation: elevation,
        tooltip: tooltip,
        child: child,
      );
    }

    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: elevation,
      tooltip: tooltip,
      child: child,
    );
  }
}

/// Button group متجاوب - يرتب الأزرار أفقياً أو عمودياً حسب حجم الشاشة
class ResponsiveButtonGroup extends StatelessWidget {
  final List<Widget> buttons;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final bool forceVertical;
  final double? spacing;

  const ResponsiveButtonGroup({
    super.key,
    required this.buttons,
    this.mainAxisAlignment = MainAxisAlignment.center,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.forceVertical = false,
    this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    final responsiveSpacing = spacing ?? ResponsiveHelper.getSpacing(context);
    final shouldBeVertical = forceVertical || ResponsiveHelper.isMobile(context);

    if (shouldBeVertical) {
      return Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: buttons
            .expand((button) => [button, SizedBox(height: responsiveSpacing)])
            .take(buttons.length * 2 - 1)
            .toList(),
      );
    }

    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: buttons
          .expand((button) => [button, SizedBox(width: responsiveSpacing)])
          .take(buttons.length * 2 - 1)
          .toList(),
    );
  }
}

/// Chip متجاوب
class ResponsiveChip extends StatelessWidget {
  final Widget label;
  final Widget? avatar;
  final VoidCallback? onDeleted;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? deleteIconColor;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;

  const ResponsiveChip({
    super.key,
    required this.label,
    this.avatar,
    this.onDeleted,
    this.onPressed,
    this.backgroundColor,
    this.deleteIconColor,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final responsivePadding = padding ?? ResponsiveHelper.getPadding(context,
      mobilePadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      tabletPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      desktopPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );

    if (onPressed != null) {
      return ActionChip(
        label: label,
        avatar: avatar,
        onPressed: onPressed,
        backgroundColor: backgroundColor,
        padding: responsivePadding,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(ResponsiveHelper.getBorderRadius(context)),
        ),
      );
    }

    return Chip(
      label: label,
      avatar: avatar,
      onDeleted: onDeleted,
      backgroundColor: backgroundColor,
      deleteIconColor: deleteIconColor,
      padding: responsivePadding,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(ResponsiveHelper.getBorderRadius(context)),
      ),
    );
  }
}
