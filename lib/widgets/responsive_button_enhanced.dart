import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

/// زر متجاوب محسن مع تخطيط مثالي
class ResponsiveButtonEnhanced extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final double? mobileHeight;
  final double? tabletHeight;
  final double? desktopHeight;
  final double? largeDesktopHeight;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? borderRadius;
  final double? elevation;
  final bool isLoading;
  final Widget? loadingWidget;
  final bool fullWidth;
  final ButtonType buttonType;

  const ResponsiveButtonEnhanced({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
    this.mobileHeight,
    this.tabletHeight,
    this.desktopHeight,
    this.largeDesktopHeight,
    this.padding,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius,
    this.elevation,
    this.isLoading = false,
    this.loadingWidget,
    this.fullWidth = false,
    this.buttonType = ButtonType.elevated,
  });

  @override
  Widget build(BuildContext context) {
    final buttonHeight = ResponsiveHelper.getButtonHeight(
      context,
      mobileHeight: mobileHeight ?? 44.0,
      tabletHeight: tabletHeight ?? 48.0,
      desktopHeight: desktopHeight ?? 52.0,
      largeDesktopHeight: largeDesktopHeight ?? 56.0,
    );

    final responsivePadding = padding ?? ResponsiveHelper.getPadding(
      context,
      mobilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      tabletPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      desktopPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      largeDesktopPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
    );

    final responsiveBorderRadius = borderRadius ?? ResponsiveHelper.getBorderRadius(context);

    final buttonStyle = style ?? _getDefaultStyle(
      context,
      buttonHeight,
      responsivePadding,
      responsiveBorderRadius,
    );

    Widget buttonChild = isLoading 
      ? (loadingWidget ?? _buildLoadingWidget(context))
      : child;

    Widget button = _buildButton(
      context,
      buttonChild,
      buttonStyle,
      isLoading ? null : onPressed,
    );

    if (fullWidth) {
      button = SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }

  Widget _buildButton(BuildContext context, Widget child, ButtonStyle style, VoidCallback? onPressed) {
    switch (buttonType) {
      case ButtonType.elevated:
        return ElevatedButton(
          onPressed: onPressed,
          style: style,
          child: child,
        );
      case ButtonType.outlined:
        return OutlinedButton(
          onPressed: onPressed,
          style: style,
          child: child,
        );
      case ButtonType.text:
        return TextButton(
          onPressed: onPressed,
          style: style,
          child: child,
        );
      case ButtonType.filled:
        return FilledButton(
          onPressed: onPressed,
          style: style,
          child: child,
        );
    }
  }

  ButtonStyle _getDefaultStyle(BuildContext context, double height, EdgeInsets padding, double borderRadius) {
    return ButtonStyle(
      minimumSize: MaterialStateProperty.all(Size(0, height)),
      padding: MaterialStateProperty.all(padding),
      backgroundColor: backgroundColor != null 
        ? MaterialStateProperty.all(backgroundColor)
        : null,
      foregroundColor: foregroundColor != null 
        ? MaterialStateProperty.all(foregroundColor)
        : null,
      elevation: elevation != null 
        ? MaterialStateProperty.all(elevation)
        : null,
      shape: MaterialStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget(BuildContext context) {
    final size = ResponsiveHelper.isMobile(context) ? 16.0 : 20.0;
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }
}

/// زر أيقونة متجاوب
class ResponsiveIconButtonEnhanced extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? size;
  final EdgeInsets? padding;
  final double? borderRadius;
  final bool isLoading;

  const ResponsiveIconButtonEnhanced({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
    this.size,
    this.padding,
    this.borderRadius,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonSize = size ?? ResponsiveHelper.getIconSize(context) + 16;
    final responsivePadding = padding ?? EdgeInsets.all(
      ResponsiveHelper.isMobile(context) ? 8.0 : 12.0,
    );
    final responsiveBorderRadius = borderRadius ?? ResponsiveHelper.getBorderRadius(context);

    Widget buttonIcon = isLoading 
      ? SizedBox(
          width: ResponsiveHelper.getIconSize(context),
          height: ResponsiveHelper.getIconSize(context),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              foregroundColor ?? Theme.of(context).colorScheme.primary,
            ),
          ),
        )
      : icon;

    Widget button = Container(
      width: buttonSize,
      height: buttonSize,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(responsiveBorderRadius),
      ),
      child: IconButton(
        onPressed: isLoading ? null : onPressed,
        icon: buttonIcon,
        color: foregroundColor,
        padding: responsivePadding,
        tooltip: tooltip,
      ),
    );

    return button;
  }
}

/// مجموعة أزرار متجاوبة
class ResponsiveButtonGroup extends StatelessWidget {
  final List<Widget> buttons;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final double? spacing;
  final bool wrapButtons;
  final bool stackOnMobile;

  const ResponsiveButtonGroup({
    super.key,
    required this.buttons,
    this.mainAxisAlignment = MainAxisAlignment.center,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.spacing,
    this.wrapButtons = false,
    this.stackOnMobile = true,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final effectiveSpacing = spacing ?? ResponsiveHelper.getSpacing(context);

    if (stackOnMobile && isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: buttons.map((button) => Padding(
          padding: EdgeInsets.only(bottom: effectiveSpacing),
          child: button,
        )).toList(),
      );
    }

    if (wrapButtons) {
      return Wrap(
        spacing: effectiveSpacing,
        runSpacing: effectiveSpacing,
        alignment: WrapAlignment.center,
        children: buttons,
      );
    }

    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: buttons.map((button) {
        final index = buttons.indexOf(button);
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: index > 0 ? effectiveSpacing / 2 : 0,
              right: index < buttons.length - 1 ? effectiveSpacing / 2 : 0,
            ),
            child: button,
          ),
        );
      }).toList(),
    );
  }
}

/// زر عائم متجاوب
class ResponsiveFloatingActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final bool mini;
  final bool isLoading;

  const ResponsiveFloatingActionButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.mini = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final effectiveMini = mini || isMobile;

    Widget fabChild = isLoading 
      ? SizedBox(
          width: effectiveMini ? 16 : 20,
          height: effectiveMini ? 16 : 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        )
      : child;

    return FloatingActionButton(
      onPressed: isLoading ? null : onPressed,
      tooltip: tooltip,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: elevation,
      mini: effectiveMini,
      child: fabChild,
    );
  }
}

/// أنواع الأزرار
enum ButtonType {
  elevated,
  outlined,
  text,
  filled,
}