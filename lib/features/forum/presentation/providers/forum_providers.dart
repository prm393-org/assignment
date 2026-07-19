import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/core/network/dio_client.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/forum/data/repositories/forum_repository_impl.dart';
import 'package:chuoi_xanh_viet/features/forum/domain/entities/forum_post.dart';
import 'package:chuoi_xanh_viet/features/forum/domain/repositories/forum_repository.dart';

final forumRepositoryProvider = Provider<ForumRepository>((ref) {
  return ForumRepositoryImpl(ref.watch(dioProvider));
});

final forumPostsProvider =
    FutureProvider.autoDispose<PaginatedResult<ForumPost>>((ref) {
  return ref.watch(forumRepositoryProvider).getPosts();
});

final forumPostProvider =
    FutureProvider.autoDispose.family<ForumPost, String>((ref, id) {
  return ref.watch(forumRepositoryProvider).getPost(id);
});

final forumCommentsProvider =
    FutureProvider.autoDispose.family<List<ForumComment>, String>((ref, id) {
  return ref.watch(forumRepositoryProvider).getComments(id);
});
