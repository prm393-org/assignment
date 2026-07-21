import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/core/firebase/current_uid_provider.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/auth/presentation/providers/auth_notifier.dart';
import 'package:chuoi_xanh_viet/features/forum/data/repositories/forum_repository_impl.dart';
import 'package:chuoi_xanh_viet/features/forum/domain/entities/forum_post.dart';
import 'package:chuoi_xanh_viet/features/forum/domain/repositories/forum_repository.dart';

final forumRepositoryProvider = Provider<ForumRepository>((ref) {
  return ForumRepositoryImpl(
    currentUid: () => ref.read(currentFirebaseUidProvider),
    currentUser: () => ref.read(authNotifierProvider).user,
  );
});

final forumPostsProvider =
    StreamProvider.autoDispose<PaginatedResult<ForumPost>>((ref) {
  return ref.watch(forumRepositoryProvider).watchPosts();
});

final forumPostProvider =
    FutureProvider.autoDispose.family<ForumPost, String>((ref, id) {
  return ref.watch(forumRepositoryProvider).getPost(id);
});

final forumCommentsProvider =
    StreamProvider.autoDispose.family<List<ForumComment>, String>((ref, id) {
  return ref.watch(forumRepositoryProvider).watchComments(id);
});
