import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/forum/domain/entities/forum_post.dart';

abstract class ForumRepository {
  Future<PaginatedResult<ForumPost>> getPosts({int page = 1, String? searchTerm});
  Future<ForumPost> getPost(String postId);
  Future<ForumPost> createPost({required String title, required String content});
  Future<List<ForumComment>> getComments(String postId);
  Future<ForumComment> createComment(String postId, String content);
}
