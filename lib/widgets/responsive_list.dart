import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

/// ListView متجاوب مع تخطيط متكيف
class ResponsiveListView extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final Axis scrollDirection;
  final bool reverse;
  final ScrollController? controller;

  const ResponsiveListView({
    super.key,
    required this.children,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final responsivePadding = padding ?? ResponsiveHelper.getPadding(context);

    return ListView(
      padding: responsivePadding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      scrollDirection: scrollDirection,
      reverse: reverse,
      controller: controller,
      children: children,
    );
  }
}

/// ListView.builder متجاوب
class ResponsiveListViewBuilder extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final Axis scrollDirection;
  final bool reverse;
  final ScrollController? controller;
  final Widget Function(BuildContext context, int index)? separatorBuilder;

  const ResponsiveListViewBuilder({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.controller,
    this.separatorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final responsivePadding = padding ?? ResponsiveHelper.getPadding(context);

    if (separatorBuilder != null) {
      return ListView.separated(
        itemCount: itemCount,
        itemBuilder: itemBuilder,
        separatorBuilder: separatorBuilder!,
        padding: responsivePadding,
        shrinkWrap: shrinkWrap,
        physics: physics,
        scrollDirection: scrollDirection,
        reverse: reverse,
        controller: controller,
      );
    }

    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      padding: responsivePadding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      scrollDirection: scrollDirection,
      reverse: reverse,
      controller: controller,
    );
  }
}

/// ListTile متجاوب
class ResponsiveListTile extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsets? contentPadding;
  final bool dense;
  final Color? tileColor;
  final Color? selectedTileColor;
  final bool selected;

  const ResponsiveListTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.contentPadding,
    this.dense = false,
    this.tileColor,
    this.selectedTileColor,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final responsiveContentPadding = contentPadding ?? ResponsiveHelper.getPadding(context,
      mobilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      tabletPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      desktopPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    );

    return ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: onTap,
      contentPadding: responsiveContentPadding,
      dense: dense,
      tileColor: tileColor,
      selectedTileColor: selectedTileColor,
      selected: selected,
    );
  }
}

/// ExpansionTile متجاوب
class ResponsiveExpansionTile extends StatelessWidget {
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final List<Widget> children;
  final ValueChanged<bool>? onExpansionChanged;
  final bool initiallyExpanded;
  final EdgeInsets? tilePadding;
  final EdgeInsets? childrenPadding;

  const ResponsiveExpansionTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    required this.children,
    this.onExpansionChanged,
    this.initiallyExpanded = false,
    this.tilePadding,
    this.childrenPadding,
  });

  @override
  Widget build(BuildContext context) {
    final responsiveTilePadding = tilePadding ?? ResponsiveHelper.getPadding(context,
      mobilePadding: const EdgeInsets.symmetric(horizontal: 12),
      tabletPadding: const EdgeInsets.symmetric(horizontal: 16),
      desktopPadding: const EdgeInsets.symmetric(horizontal: 20),
    );

    final responsiveChildrenPadding = childrenPadding ?? ResponsiveHelper.getPadding(context,
      mobilePadding: const EdgeInsets.symmetric(horizontal: 16),
      tabletPadding: const EdgeInsets.symmetric(horizontal: 20),
      desktopPadding: const EdgeInsets.symmetric(horizontal: 24),
    );

    return ExpansionTile(
      title: title,
      subtitle: subtitle,
      leading: leading,
      trailing: trailing,
      children: children,
      onExpansionChanged: onExpansionChanged,
      initiallyExpanded: initiallyExpanded,
      tilePadding: responsiveTilePadding,
      childrenPadding: responsiveChildrenPadding,
    );
  }
}

/// Card للقائمة مع تخطيط متجاوب
class ResponsiveListCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? margin;
  final EdgeInsets? padding;

  const ResponsiveListCard({
    super.key,
    required this.child,
    this.onTap,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final responsiveMargin = margin ?? ResponsiveHelper.getPadding(context,
      mobilePadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      tabletPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      desktopPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );

    final responsivePadding = padding ?? ResponsiveHelper.getPadding(context,
      mobilePadding: const EdgeInsets.all(12),
      tabletPadding: const EdgeInsets.all(16),
      desktopPadding: const EdgeInsets.all(20),
    );

    Widget cardContent = Container(
      margin: responsiveMargin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getBorderRadius(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: ResponsiveHelper.isMobile(context) ? 4 : 8,
            offset: Offset(0, ResponsiveHelper.isMobile(context) ? 2 : 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: responsivePadding,
        child: child,
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(ResponsiveHelper.getBorderRadius(context)),
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}

/// Divider متجاوب
class ResponsiveDivider extends StatelessWidget {
  final double? height;
  final double? thickness;
  final double? indent;
  final double? endIndent;
  final Color? color;

  const ResponsiveDivider({
    super.key,
    this.height,
    this.thickness,
    this.indent,
    this.endIndent,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final responsiveIndent = indent ?? ResponsiveHelper.getSpacing(context);
    final responsiveEndIndent = endIndent ?? ResponsiveHelper.getSpacing(context);

    return Divider(
      height: height,
      thickness: thickness,
      indent: responsiveIndent,
      endIndent: responsiveEndIndent,
      color: color,
    );
  }
}

/// SliverList متجاوب
class ResponsiveSliverList extends StatelessWidget {
  final SliverChildDelegate delegate;

  const ResponsiveSliverList({
    super.key,
    required this.delegate,
  });

  @override
  Widget build(BuildContext context) {
    return SliverList(delegate: delegate);
  }
}

/// SliverGrid متجاوب
class ResponsiveSliverGrid extends StatelessWidget {
  final SliverChildDelegate delegate;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final int? largeDesktopColumns;
  final double? mobileAspectRatio;
  final double? tabletAspectRatio;
  final double? desktopAspectRatio;
  final double? largeDesktopAspectRatio;

  const ResponsiveSliverGrid({
    super.key,
    required this.delegate,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
    this.largeDesktopColumns,
    this.mobileAspectRatio,
    this.tabletAspectRatio,
    this.desktopAspectRatio,
    this.largeDesktopAspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = ResponsiveHelper.getGridCrossAxisCount(
      context,
      mobileCount: mobileColumns ?? 1,
      tabletCount: tabletColumns ?? 2,
      desktopCount: desktopColumns ?? 3,
      largeDesktopCount: largeDesktopColumns ?? 4,
    );

    final childAspectRatio = ResponsiveHelper.getChildAspectRatio(
      context,
      mobileRatio: mobileAspectRatio ?? 0.8,
      tabletRatio: tabletAspectRatio ?? 0.9,
      desktopRatio: desktopAspectRatio ?? 1.0,
      largeDesktopRatio: largeDesktopAspectRatio ?? 1.1,
    );

    final spacing = ResponsiveHelper.getSpacing(context);

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      delegate: delegate,
    );
  }
}
