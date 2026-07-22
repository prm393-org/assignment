import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/forum/domain/entities/forum_post.dart';

abstract class ForumRepository {
  Future<PaginatedResult<ForumPost>> getPosts({
    int page = 1,
    String? searchTerm,
    String? label,
  });

  Stream<PaginatedResult<ForumPost>> watchPosts({
    String? searchTerm,
    String? label,
  });

  Future<ForumPost> getPost(String postId);

  Future<ForumPost> createPost({
    required String title,
    required String content,
    List<String> labels = const [],
    List<String> imageUrls = const [],
  });

  Future<ForumPost> updatePost({
    required String postId,
    required String title,
    required String content,
    List<String> labels = const [],
    List<String> imageUrls = const [],
  });

  Future<void> deletePost(String postId);

  Future<List<ForumComment>> getComments(String postId);

  Stream<List<ForumComment>> watchComments(String postId);

  Future<ForumComment> createComment(String postId, String content);

  Future<ForumComment> updateComment({
    required String postId,
    required String commentId,
    required String content,
  });

  Future<void> deleteComment({
    required String postId,
    required String commentId,
  });
}
