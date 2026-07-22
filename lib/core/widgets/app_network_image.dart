import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/media_url.dart';

class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final resolved = resolveMediaUrl(url);
    final child = resolved == null
        ? Container(
            width: width,
            height: height,
            color: AppColors.hairline,
            child: const Icon(Icons.image_outlined, color: AppColors.muted),
          )
        : CachedNetworkImage(
            imageUrl: resolved,
            width: width,
            height: height,
            fit: fit,
            placeholder: (_, _) => Container(
              width: width,
              height: height,
              color: AppColors.hairline,
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            errorWidget: (_, _, _) => Container(
              width: width,
              height: height,
              color: AppColors.hairline,
              child: const Icon(Icons.broken_image_outlined, color: AppColors.muted),
            ),
          );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }
}
