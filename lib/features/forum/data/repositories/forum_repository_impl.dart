import 'package:dio/dio.dart';
import 'package:chuoi_xanh_viet/core/error/exception_mapper.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/forum/domain/entities/forum_post.dart';
import 'package:chuoi_xanh_viet/features/forum/domain/repositories/forum_repository.dart';

class ForumRepositoryImpl implements ForumRepository {
  ForumRepositoryImpl(this._dio);
  final Dio _dio;

  @override
  Future<PaginatedResult<ForumPost>> getPosts({
    int page = 1,
    String? searchTerm,
  }) async {
    try {
      final res = await _dio.get('/forum/posts', queryParameters: {
        'page': page,
        'limit': 15,
        if (searchTerm != null && searchTerm.isNotEmpty) 'searchTerm': searchTerm,
      });
      return PaginatedResult.fromJson(unwrapData(res.data), ForumPost.fromJson);
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<ForumPost> getPost(String postId) async {
    try {
      final res = await _dio.get('/forum/posts/$postId');
      return ForumPost.fromJson(asMap(unwrapData(res.data)));
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<ForumPost> createPost({
    required String title,
    required String content,
  }) async {
    try {
      final res = await _dio.post('/forum/posts', data: {
        'title': title,
        'content': content,
      });
      return ForumPost.fromJson(asMap(unwrapData(res.data)));
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<List<ForumComment>> getComments(String postId) async {
    try {
      final res = await _dio.get('/forum/posts/$postId/comments');
      final data = unwrapData(res.data);
      if (data is List) return mapList(data, ForumComment.fromJson);
      return PaginatedResult.fromJson(data, ForumComment.fromJson).items;
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<ForumComment> createComment(String postId, String content) async {
    try {
      final res = await _dio.post('/forum/posts/$postId/comments', data: {
        'content': content,
      });
      return ForumComment.fromJson(asMap(unwrapData(res.data)));
    } catch (e) {
      throw mapDioException(e);
    }
  }
}
