import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/widget/spaced_list_widget.dart';

typedef PresentableStat = ({Widget label, Widget data, String? semanticLabel});

class StatsCard extends StatelessWidget {
  const StatsCard({
    super.key,
    this.title,
    this.titleStyle,
    this.padding = const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
    this.labelStyle,
    this.dataStyle,
    required this.stats,
  });

  final String? title;
  final TextStyle? titleStyle;
  final EdgeInsets padding;
  final TextStyle? labelStyle;
  final TextStyle? dataStyle;
  final List<PresentableStat> stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveTitleStyle = titleStyle ?? Theme.of(context).textTheme.bodySmall;
    final effectiveLabelStyle =
        labelStyle ?? Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w300);
    final effectiveDataStyle =
        dataStyle ?? Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w300);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF15233B).withValues(alpha: 0.92),
            const Color(0xFF0E1627).withValues(alpha: 0.88),
          ],
        ),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.26)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: padding.add(const EdgeInsets.symmetric(horizontal: 4, vertical: 2)),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null)
                ...[
                  Text(
                    title!,
                    style: effectiveTitleStyle?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const Gap(6),
                ],
              ...stats
                  .map((stat) {
                    Widget label = IconTheme.merge(
                      data: IconThemeData(size: 14, color: theme.colorScheme.onSurfaceVariant),
                      child: DefaultTextStyle(
                        style: effectiveLabelStyle!.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        overflow: TextOverflow.ellipsis,
                        child: stat.label,
                      ),
                    );
                    if (stat.semanticLabel != null) {
                      label = Tooltip(message: stat.semanticLabel, verticalOffset: 8, child: label);
                    }
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        label,
                        const Gap(8),
                        Flexible(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: DefaultTextStyle(
                              style: effectiveDataStyle!.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                              child: stat.data,
                            ),
                          ),
                        ),
                      ],
                    );
                  })
                  .toList()
                  .spaceBy(height: 6),
            ],
          ),
      ),
    );
  }
}
