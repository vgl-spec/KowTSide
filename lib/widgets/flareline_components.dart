import 'package:flutter/material.dart';

import '../core/theme.dart';

class FlarePageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> actions;

  const FlarePageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.actions = const <Widget>[],
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 960;
        final titleStyle = compact
            ? Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                )
            : Theme.of(context).textTheme.headlineSmall;
        final subtitleStyle = compact
            ? Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12)
            : Theme.of(context).textTheme.bodySmall;
        final titleBlock = ConstrainedBox(
          constraints: BoxConstraints(maxWidth: compact ? constraints.maxWidth : 740),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: titleStyle),
              const SizedBox(height: 6),
              Text(subtitle, style: subtitleStyle),
            ],
          ),
        );

        final actionsWrap = actions.isNotEmpty
            ? Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: compact ? WrapAlignment.start : WrapAlignment.end,
                children: actions,
              )
            : null;

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock,
              if (actionsWrap != null) ...[const SizedBox(height: 12), actionsWrap],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: titleBlock),
            if (actionsWrap != null) ...[
              const SizedBox(width: 12),
              Flexible(child: Align(alignment: Alignment.topRight, child: actionsWrap)),
            ],
          ],
        );
      },
    );
  }
}

class FlareSurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const FlareSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.55)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.surface,
            AppTheme.surfaceLow.withValues(alpha: 0.95),
          ],
        ),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class FlareSectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;

  const FlareSectionTitle({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 10), trailing!],
      ],
    );
  }
}

class FlareMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String hint;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final String? actionLabel;

  const FlareMetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.hint,
    required this.icon,
    required this.color,
    this.onTap,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 900;
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: color,
                  fontSize: compact ? 18 : null,
                ),
              ),
            ),
            Container(
              width: compact ? 34 : 38,
              height: compact ? 34 : 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: compact ? 18 : 21),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w900,
            color: color,
            fontSize: compact ? 44 : null,
          ),
        ),
        const SizedBox(height: 4),
        Text(hint, style: Theme.of(context).textTheme.bodySmall),
        if (onTap != null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                actionLabel ?? 'Open details',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.arrow_forward_rounded, size: 16, color: color),
            ],
          ),
        ],
      ],
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 170),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: FlareSurfaceCard(padding: const EdgeInsets.all(18), child: body),
        ),
      ),
    );
  }
}

class FlarePill extends StatelessWidget {
  final String label;
  final Color color;

  const FlarePill({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class FlareEmptyState extends StatelessWidget {
  final String message;

  const FlareEmptyState({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      child: Text(message, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
