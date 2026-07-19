# -*- coding: utf-8 -*-
from pathlib import Path

ROOT = Path(r'd:\fpt\ky8\PRM393\assignment\lib')


def w(rel: str, content: str) -> None:
    p = ROOT / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(content.strip() + '\n', encoding='utf-8')
    print(rel)


# FORUM
w('features/forum/domain/entities/forum_post.dart', r'''
import 'package:equatable/equatable.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/core/utils/media_url.dart';

class ForumAuthor extends Equatable {
  const ForumAuthor({required this.id, required this.fullName, this.avatarUrl, this.role});
  final String id;
  final String fullName;
  final String? avatarUrl;
  final String? role;

  factory ForumAuthor.fromJson(Map<String, dynamic> json) => ForumAuthor(
        id: readString(json, ['id']),
        fullName: readString(json, ['fullName', 'full_name'], 'Người dùng'),
        avatarUrl: resolveMediaUrl(readStringOrNull(json, ['avatar', 'avatarUrl', 'avatar_url'])),
        role: readStringOrNull(json, ['role']),
      );

  @override
  List<Object?> get props => [id];
}

class ForumPost extends Equatable {
  const ForumPost({
    required this.id,
    required this.title,
    required this.content,
    this.author,
    this.commentCount = 0,
    this.likeCount = 0,
    this.createdAt,
    this.labels = const [],
  });

  final String id;
  final String title;
  final String content;
  final ForumAuthor? author;
  final int commentCount;
  final int likeCount;
  final String? createdAt;
  final List<String> labels;

  factory ForumPost.fromJson(Map<String, dynamic> json) {
    final author = asMap(json['author'] ?? json['users']);
    return ForumPost(
      id: readString(json, ['id']),
      title: readString(json, ['title']),
      content: readString(json, ['content']),
      author: author.isEmpty ? null : ForumAuthor.fromJson(author),
      commentCount: readInt(json, ['commentCount', 'comment_count']),
      likeCount: readInt(json, ['likeCount', 'like_count']),
      createdAt: readStringOrNull(json, ['createdAt', 'created_at']),
      labels: asList(json['labels']).map((e) => '$e').toList(),
    );
  }

  @override
  List<Object?> get props => [id];
}

class ForumComment extends Equatable {
  const ForumComment({
    required this.id,
    required this.content,
    this.author,
    this.createdAt,
  });

  final String id;
  final String content;
  final ForumAuthor? author;
  final String? createdAt;

  factory ForumComment.fromJson(Map<String, dynamic> json) {
    final author = asMap(json['author'] ?? json['users']);
    return ForumComment(
      id: readString(json, ['id']),
      content: readString(json, ['content']),
      author: author.isEmpty ? null : ForumAuthor.fromJson(author),
      createdAt: readStringOrNull(json, ['createdAt', 'created_at']),
    );
  }

  @override
  List<Object?> get props => [id];
}
''')

w('features/forum/domain/repositories/forum_repository.dart', r'''
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/forum/domain/entities/forum_post.dart';

abstract class ForumRepository {
  Future<PaginatedResult<ForumPost>> getPosts({int page = 1, String? searchTerm});
  Future<ForumPost> getPost(String postId);
  Future<ForumPost> createPost({required String title, required String content});
  Future<List<ForumComment>> getComments(String postId);
  Future<ForumComment> createComment(String postId, String content);
}
''')

w('features/forum/data/repositories/forum_repository_impl.dart', r'''
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
''')

w('features/forum/presentation/providers/forum_providers.dart', r'''
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
''')

# NOTIFICATION
w('features/notification/domain/entities/app_notification.dart', r'''
import 'package:equatable/equatable.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';

class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.title,
    required this.content,
    required this.read,
    required this.createdAt,
    this.type = 'system',
    this.link,
  });

  final String id;
  final String title;
  final String content;
  final bool read;
  final String createdAt;
  final String type;
  final String? link;

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: readString(json, ['id']),
        title: readString(json, ['title']),
        content: readString(json, ['content', 'body']),
        read: readBool(json, ['read', 'isRead', 'is_read']),
        createdAt: readString(json, ['createdAt', 'created_at']),
        type: readString(json, ['type'], 'system'),
        link: readStringOrNull(json, ['link', 'linkPath', 'link_path']),
      );

  @override
  List<Object?> get props => [id, read];
}
''')

w('features/notification/domain/repositories/notification_repository.dart', r'''
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/notification/domain/entities/app_notification.dart';

abstract class NotificationRepository {
  Future<PaginatedResult<AppNotification>> list({int page = 1, bool? unreadOnly});
  Future<void> markRead(String id);
  Future<void> markAllRead();
}
''')

w('features/notification/data/repositories/notification_repository_impl.dart', r'''
import 'package:dio/dio.dart';
import 'package:chuoi_xanh_viet/core/error/exception_mapper.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/notification/domain/entities/app_notification.dart';
import 'package:chuoi_xanh_viet/features/notification/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(this._dio);
  final Dio _dio;

  @override
  Future<PaginatedResult<AppNotification>> list({
    int page = 1,
    bool? unreadOnly,
  }) async {
    try {
      final res = await _dio.get('/notification', queryParameters: {
        'page': page,
        'limit': 30,
        if (unreadOnly != null) 'unread_only': unreadOnly ? 'true' : 'false',
      });
      return PaginatedResult.fromJson(
        unwrapData(res.data),
        AppNotification.fromJson,
      );
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<void> markRead(String id) async {
    try {
      await _dio.patch('/notification/$id/read');
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<void> markAllRead() async {
    try {
      await _dio.patch('/notification/read-all');
    } catch (e) {
      throw mapDioException(e);
    }
  }
}
''')

w('features/notification/presentation/providers/notification_providers.dart', r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/core/network/dio_client.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/notification/data/repositories/notification_repository_impl.dart';
import 'package:chuoi_xanh_viet/features/notification/domain/entities/app_notification.dart';
import 'package:chuoi_xanh_viet/features/notification/domain/repositories/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(ref.watch(dioProvider));
});

final notificationsProvider =
    FutureProvider.autoDispose<PaginatedResult<AppNotification>>((ref) {
  return ref.watch(notificationRepositoryProvider).list();
});
''')

# REVIEW
w('features/review/domain/entities/shop_review.dart', r'''
import 'package:equatable/equatable.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/core/utils/media_url.dart';

class ShopReview extends Equatable {
  const ShopReview({
    required this.id,
    required this.rating,
    required this.createdAt,
    this.comment,
    this.reviewerName,
    this.productName,
    this.productImageUrl,
  });

  final String id;
  final int rating;
  final String createdAt;
  final String? comment;
  final String? reviewerName;
  final String? productName;
  final String? productImageUrl;

  factory ShopReview.fromJson(Map<String, dynamic> json) {
    final reviewer = asMap(json['reviewer'] ?? json['users']);
    final product = asMap(json['product'] ?? json['products']);
    return ShopReview(
      id: readString(json, ['id']),
      rating: readInt(json, ['rating']),
      createdAt: readString(json, ['createdAt', 'created_at']),
      comment: readStringOrNull(json, ['comment']),
      reviewerName: readStringOrNull(reviewer, ['fullName', 'full_name']),
      productName: readStringOrNull(product, ['name']),
      productImageUrl: resolveMediaUrl(
        readStringOrNull(product, ['imageUrl', 'image_url']),
      ),
    );
  }

  @override
  List<Object?> get props => [id];
}
''')

w('features/review/domain/repositories/review_repository.dart', r'''
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/review/domain/entities/shop_review.dart';

abstract class ReviewRepository {
  Future<PaginatedResult<ShopReview>> listByProduct(String productId);
  Future<PaginatedResult<ShopReview>> listByShop(String shopId);
  Future<ShopReview> createReview({
    required String orderId,
    required String productId,
    required int rating,
    String? comment,
  });
}
''')

w('features/review/data/repositories/review_repository_impl.dart', r'''
import 'package:dio/dio.dart';
import 'package:chuoi_xanh_viet/core/error/exception_mapper.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/review/domain/entities/shop_review.dart';
import 'package:chuoi_xanh_viet/features/review/domain/repositories/review_repository.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  ReviewRepositoryImpl(this._dio);
  final Dio _dio;

  @override
  Future<PaginatedResult<ShopReview>> listByProduct(String productId) async {
    try {
      final res = await _dio.get('/review/product/$productId');
      return PaginatedResult.fromJson(unwrapData(res.data), ShopReview.fromJson);
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<PaginatedResult<ShopReview>> listByShop(String shopId) async {
    try {
      final res = await _dio.get('/review/shop/$shopId');
      return PaginatedResult.fromJson(unwrapData(res.data), ShopReview.fromJson);
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<ShopReview> createReview({
    required String orderId,
    required String productId,
    required int rating,
    String? comment,
  }) async {
    try {
      final res = await _dio.post('/review', data: {
        'order_id': orderId,
        'product_id': productId,
        'rating': rating,
        if (comment != null) 'comment': comment,
      });
      return ShopReview.fromJson(asMap(unwrapData(res.data)));
    } catch (e) {
      throw mapDioException(e);
    }
  }
}
''')

w('features/review/presentation/providers/review_providers.dart', r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/core/network/dio_client.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/review/data/repositories/review_repository_impl.dart';
import 'package:chuoi_xanh_viet/features/review/domain/entities/shop_review.dart';
import 'package:chuoi_xanh_viet/features/review/domain/repositories/review_repository.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepositoryImpl(ref.watch(dioProvider));
});

final productReviewsProvider = FutureProvider.autoDispose
    .family<PaginatedResult<ShopReview>, String>((ref, productId) {
  return ref.watch(reviewRepositoryProvider).listByProduct(productId);
});

final shopReviewsProvider = FutureProvider.autoDispose
    .family<PaginatedResult<ShopReview>, String>((ref, shopId) {
  return ref.watch(reviewRepositoryProvider).listByShop(shopId);
});
''')

print('part3a done')
