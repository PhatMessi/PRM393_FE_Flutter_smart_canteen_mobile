/**
 * BUG FIX: Xử lý tràn giao diện (UI Overflow)
 * 
 * Vấn đề: Khi nội dung vượt quá kích thước container,
 *         app bị lỗi "A RenderFlex overflowed" hoặc bị cắt mất nội dung
 *         Đặc biệt khi trên các thiết bị có màn hình nhỏ
 * 
 * Fix: Cung cấp các utility widgets và hàm xử lý overflow
 *      Cho phép text wrap, scroll, hoặc fit nội dung vào container
 */

import 'package:flutter/material.dart';

// ============================================================================
// FIX 1: Adaptive Text Widget - Tự động wrap text khi tràn
// ============================================================================
class AdaptiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final int maxLines;
  final TextOverflow overflow;

  const AdaptiveText(
    this.text, {
    Key? key,
    this.style,
    this.textAlign = TextAlign.left,
    this.maxLines = 3,
    this.overflow = TextOverflow.ellipsis,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

// ============================================================================
// FIX 2: Horizontal Scrollable Row - Cho phép cuộn ngang khi content tràn
// ============================================================================
class ScrollableRow extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final EdgeInsets padding;
  final ScrollController? controller;

  const ScrollableRow({
    Key? key,
    required this.children,
    this.spacing = 8.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 8.0),
    this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: controller,
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) SizedBox(width: spacing),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// FIX 3: Flexible Column - Tự động fit content theo kích thước available
// ============================================================================
class FlexibleColumn extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;

  const FlexibleColumn({
    Key? key,
    required this.children,
    this.spacing = 8.0,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        for (int i = 0; i < children.length; i++) ...[
          Flexible(
            child: children[i],
          ),
          if (i < children.length - 1) SizedBox(height: spacing),
        ],
      ],
    );
  }
}

// ============================================================================
// FIX 4: Constrained Text - Giới hạn chiều rộng text để tránh overflow
// ============================================================================
class ConstrainedText extends StatelessWidget {
  final String text;
  final double maxWidth;
  final TextStyle? style;
  final TextAlign textAlign;
  final int maxLines;

  const ConstrainedText(
    this.text, {
    Key? key,
    this.maxWidth = 200,
    this.style,
    this.textAlign = TextAlign.left,
    this.maxLines = 2,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: maxWidth,
      child: Text(
        text,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ============================================================================
// FIX 5: Overflow Container - Container thông minh tránh overflow
// ============================================================================
class OverflowContainer extends StatelessWidget {
  final Widget child;
  final double? maxHeight;
  final double? maxWidth;
  final EdgeInsets padding;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final bool enableScroll;

  const OverflowContainer({
    Key? key,
    required this.child,
    this.maxHeight,
    this.maxWidth,
    this.padding = const EdgeInsets.all(8.0),
    this.backgroundColor,
    this.borderRadius,
    this.enableScroll = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget content = child;

    // Nếu có giới hạn kích thước, wrap đó
    if (maxWidth != null || maxHeight != null) {
      content = ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? double.infinity,
          maxHeight: maxHeight ?? double.infinity,
        ),
        child: enableScroll
            ? SingleChildScrollView(
                child: content,
              )
            : content,
      );
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      child: content,
    );
  }
}

// ============================================================================
// FIX 6: ResponsiveRow - Row tự động wrap thành column trên màn hình nhỏ
// ============================================================================
class ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  final double breakpoint; // Nếu width < breakpoint, chuyển thành column
  final double spacing;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;

  const ResponsiveRow({
    Key? key,
    required this.children,
    this.breakpoint = 600,
    this.spacing = 8.0,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < breakpoint;

    final List<Widget> spacedChildren = [
      for (int i = 0; i < children.length; i++) ...[
        Flexible(child: children[i]),
        if (i < children.length - 1)
          SizedBox(
            height: isSmallScreen ? spacing : 0,
            width: isSmallScreen ? 0 : spacing,
          ),
      ],
    ];

    return isSmallScreen
        ? Column(
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
            children: spacedChildren,
          )
        : Row(
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
            children: spacedChildren,
          );
  }
}

// ============================================================================
// FIX 7: Utility Functions - Các hàm tiện ích xử lý overflow
// ============================================================================
class OverflowUtils {
  /// Truncate text nếu quá dài
  static String truncateText({
    required String text,
    required int maxLength,
    String suffix = '...',
  }) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength)}$suffix';
  }

  /// Fit text vào width constraint
  static String fitTextToWidth({
    required String text,
    required int estimatedCharsPerLine,
  }) {
    if (text.length <= estimatedCharsPerLine) {
      return text;
    }
    // Thêm newline character để wrap text
    final buffer = StringBuffer();
    int charCount = 0;

    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      charCount++;

      if (charCount >= estimatedCharsPerLine && text[i] == ' ') {
        buffer.write('\n');
        charCount = 0;
      }
    }
    return buffer.toString();
  }

  /// Get responsive font size dựa trên screen width
  static double getResponsiveFontSize({
    required BuildContext context,
    double baseSize = 14,
    double maxSize = 20,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Giảm dần size khi màn hình nhỏ
    if (screenWidth < 400) {
      return baseSize * 0.9;
    } else if (screenWidth < 600) {
      return baseSize;
    } else {
      return (baseSize + maxSize) / 2;
    }
  }

  /// Get responsive padding dựa trên screen width
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 400) {
      return const EdgeInsets.all(8.0);
    } else if (screenWidth < 600) {
      return const EdgeInsets.all(12.0);
    } else {
      return const EdgeInsets.all(16.0);
    }
  }
}

// ============================================================================
// FIX 8: Expandable Container - Container có thể mở rộng để hiển thị nội dung
// ============================================================================
class ExpandableContainer extends StatefulWidget {
  final Widget child;
  final int maxLinesCollapsed;
  final String expandLabel;
  final String collapseLabel;
  final TextStyle? labelStyle;

  const ExpandableContainer({
    Key? key,
    required this.child,
    this.maxLinesCollapsed = 2,
    this.expandLabel = 'Xem thêm',
    this.collapseLabel = 'Ẩn bớt',
    this.labelStyle,
  }) : super(key: key);

  @override
  State<ExpandableContainer> createState() => _ExpandableContainerState();
}

class _ExpandableContainerState extends State<ExpandableContainer> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedCrossFade(
          firstChild: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: !_isExpanded ? double.infinity : 0,
              ),
              child: widget.child,
            ),
          ),
          secondChild: widget.child,
          crossFadeState:
              _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              _isExpanded ? widget.collapseLabel : widget.expandLabel,
              style: widget.labelStyle ??
                  TextStyle(
                    color: Colors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ),
      ],
    );
  }
}
