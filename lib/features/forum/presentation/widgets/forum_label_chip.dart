import 'package:flutter/material.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/features/forum/domain/forum_labels.dart';

class ForumLabelChip extends StatelessWidget {
  const ForumLabelChip({
    super.key,
    required this.slug,
    this.label,
    this.selected = false,
    this.onTap,
    this.compact = false,
  });

  final String slug;
  final String? label;
  final bool selected;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final text = label ?? ForumLabels.labelOf(slug);
    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 4 : 8,
      ),
      decoration: BoxDecoration(
        color: selected ? AppColors.forest : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? AppColors.forest : AppColors.hairline,
        ),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: selected ? AppColors.onPrimary : AppColors.body,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
      ),
    );
    if (onTap == null) return child;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: child,
      ),
    );
  }
}

class ForumTopicFilterBar extends StatelessWidget {
  const ForumTopicFilterBar({
    super.key,
    required this.selectedSlug,
    required this.onChanged,
  });

  final String? selectedSlug;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ForumLabelChip(
              slug: 'all',
              label: 'Tất cả',
              selected: selectedSlug == null,
              onTap: () => onChanged(null),
            ),
          ),
          for (final slug in ForumLabels.all)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ForumLabelChip(
                slug: slug,
                selected: selectedSlug == slug,
                onTap: () => onChanged(selectedSlug == slug ? null : slug),
              ),
            ),
        ],
      ),
    );
  }
}
