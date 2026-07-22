import 'package:flutter/material.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/widgets/app_network_image.dart';
import 'package:chuoi_xanh_viet/features/forum/domain/entities/forum_post.dart';

class ForumAuthorAvatar extends StatelessWidget {
  const ForumAuthorAvatar({
    super.key,
    this.author,
    this.size = 40,
  });

  final ForumAuthor? author;
  final double size;

  @override
  Widget build(BuildContext context) {
    final name = author?.fullName.trim() ?? '';
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : '?';
    final url = author?.avatarUrl;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.mint,
        border: Border.all(color: AppColors.mintDeep, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null && url.isNotEmpty
          ? AppNetworkImage(url: url, width: size, height: size)
          : Center(
              child: Text(
                initial,
                style: TextStyle(
                  color: AppColors.forest,
                  fontWeight: FontWeight.w700,
                  fontSize: size * 0.38,
                ),
              ),
            ),
    );
  }
}
