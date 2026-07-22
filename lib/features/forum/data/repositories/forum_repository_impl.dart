import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chuoi_xanh_viet/core/error/failures.dart';
import 'package:chuoi_xanh_viet/core/error/firestore_exception_mapper.dart';
import 'package:chuoi_xanh_viet/core/firebase/firestore_refs.dart';
import 'package:chuoi_xanh_viet/core/firebase/notification_writer.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/auth/domain/entities/auth_user.dart';
import 'package:chuoi_xanh_viet/features/forum/domain/entities/forum_post.dart';
import 'package:chuoi_xanh_viet/features/forum/domain/repositories/forum_repository.dart';

const _pageSize = 50;

class ForumRepositoryImpl implements ForumRepository {
  ForumRepositoryImpl({
    required String? Function() currentUid,
    required AuthUser? Function() currentUser,
  }) : _currentUid = currentUid,
       _currentUser = currentUser;

  // Firestore security rules key on the Firebase Auth uid, never on the
  // backend's AuthUser.id — for email/password users those are different
  // id spaces (see AuthRepositoryImpl._ensureFirebaseShadowAccount).
  final String? Function() _currentUid;
  final AuthUser? Function() _currentUser;

  @override
  Future<PaginatedResult<ForumPost>> getPosts({
    int page = 1,
    String? searchTerm,
    String? label,
  }) async {
    try {
      final snapshot = await _postsQuery().get();
      final items = _filterPosts(
        snapshot.docs.map((d) => ForumPost.fromJson(_postJson(d))).toList(),
        searchTerm: searchTerm,
        label: label,
      );
      return PaginatedResult(items: items, total: items.length, limit: _pageSize);
    } catch (e) {
      throw mapFirestoreException(e);
    }
  }

  @override
  Stream<PaginatedResult<ForumPost>> watchPosts({
    String? searchTerm,
    String? label,
  }) {
    return _postsQuery().snapshots().map((snapshot) {
      final items = _filterPosts(
        snapshot.docs.map((d) => ForumPost.fromJson(_postJson(d))).toList(),
        searchTerm: searchTerm,
        label: label,
      );
      return PaginatedResult(items: items, total: items.length, limit: _pageSize);
    });
  }

  Query<Map<String, dynamic>> _postsQuery() => FirestoreRefs.forumPostsRef()
      .orderBy('createdAt', descending: true)
      .limit(_pageSize);

  List<ForumPost> _filterPosts(
    List<ForumPost> items, {
    String? searchTerm,
    String? label,
  }) {
    var result = items;
    if (label != null && label.trim().isNotEmpty && label != 'all') {
      final slug = label.trim();
      result = result.where((p) => p.labels.contains(slug)).toList();
    }
    if (searchTerm == null || searchTerm.trim().isEmpty) return result;
    final q = searchTerm.trim().toLowerCase();
    return result
        .where(
          (p) =>
              p.title.toLowerCase().contains(q) ||
              p.content.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Future<ForumPost> getPost(String postId) async {
    try {
      final doc = await FirestoreRefs.forumPostsRef().doc(postId).get();
      if (!doc.exists) {
        throw const ValidationFailure('Bài viết không tồn tại');
      }
      return ForumPost.fromJson(_postJson(doc));
    } catch (e) {
      if (e is Failure) rethrow;
      throw mapFirestoreException(e);
    }
  }

  @override
  Future<ForumPost> createPost({
    required String title,
    required String content,
    List<String> labels = const [],
    List<String> imageUrls = const [],
  }) async {
    try {
      final uid = _currentUid();
      if (uid == null) {
        throw const AuthFailure('Cần đăng nhập để đăng bài');
      }
      final user = _currentUser();
      final docRef = FirestoreRefs.forumPostsRef().doc();
      await docRef.set({
        'title': title,
        'content': content,
        'authorId': uid,
        'authorName': user?.fullName ?? 'Người dùng',
        'authorAvatarUrl': user?.avatarUrl,
        'authorRole': user?.role,
        'commentCount': 0,
        'likeCount': 0,
        'labels': labels,
        'imageUrls': imageUrls,
        'createdAt': FieldValue.serverTimestamp(),
      });
      final snap = await docRef.get();
      return ForumPost.fromJson(_postJson(snap));
    } catch (e) {
      if (e is Failure) rethrow;
      throw mapFirestoreException(e);
    }
  }

  @override
  Future<ForumPost> updatePost({
    required String postId,
    required String title,
    required String content,
    List<String> labels = const [],
    List<String> imageUrls = const [],
  }) async {
    try {
      final uid = _currentUid();
      if (uid == null) {
        throw const AuthFailure('Cần đăng nhập để sửa bài');
      }
      final postRef = FirestoreRefs.forumPostsRef().doc(postId);
      final snap = await postRef.get();
      if (!snap.exists) {
        throw const ValidationFailure('Bài viết không tồn tại');
      }
      final authorId = snap.data()?['authorId'] as String?;
      if (authorId != uid) {
        throw const AuthFailure('Chỉ sửa được bài viết của bạn');
      }
      await postRef.update({
        'title': title,
        'content': content,
        'labels': labels,
        'imageUrls': imageUrls,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final updated = await postRef.get();
      return ForumPost.fromJson(_postJson(updated));
    } catch (e) {
      if (e is Failure) rethrow;
      throw mapFirestoreException(e);
    }
  }

  @override
  Future<void> deletePost(String postId) async {
    try {
      final uid = _currentUid();
      if (uid == null) {
        throw const AuthFailure('Cần đăng nhập để xóa bài');
      }
      final postRef = FirestoreRefs.forumPostsRef().doc(postId);
      final snap = await postRef.get();
      if (!snap.exists) {
        throw const ValidationFailure('Bài viết không tồn tại');
      }
      final authorId = snap.data()?['authorId'] as String?;
      if (authorId != uid) {
        throw const AuthFailure('Chỉ xóa được bài viết của bạn');
      }
      final comments =
          await FirestoreRefs.forumCommentsRef(postId).limit(400).get();
      final batch = FirebaseFirestore.instance.batch();
      for (final d in comments.docs) {
        batch.delete(d.reference);
      }
      batch.delete(postRef);
      await batch.commit();
    } catch (e) {
      if (e is Failure) rethrow;
      throw mapFirestoreException(e);
    }
  }

  @override
  Future<List<ForumComment>> getComments(String postId) async {
    try {
      final snapshot = await _commentsQuery(postId).get();
      return snapshot.docs.map((d) => ForumComment.fromJson(_commentJson(d))).toList();
    } catch (e) {
      throw mapFirestoreException(e);
    }
  }

  @override
  Stream<List<ForumComment>> watchComments(String postId) {
    return _commentsQuery(postId).snapshots().map(
          (snapshot) => snapshot.docs
              .map((d) => ForumComment.fromJson(_commentJson(d)))
              .toList(),
        );
  }

  Query<Map<String, dynamic>> _commentsQuery(String postId) =>
      FirestoreRefs.forumCommentsRef(postId).orderBy('createdAt');

  @override
  Future<ForumComment> createComment(String postId, String content) async {
    try {
      final uid = _currentUid();
      if (uid == null) {
        throw const AuthFailure('Cần đăng nhập để bình luận');
      }
      final user = _currentUser();
      final postRef = FirestoreRefs.forumPostsRef().doc(postId);
      final commentRef = FirestoreRefs.forumCommentsRef(postId).doc();
      final postSnap = await postRef.get();
      // Comment create and commentCount bump must not share one batch:
      // until rules allow non-authors to bump commentCount, a batch would
      // fail the whole write with permission-denied.
      await commentRef.set({
        'content': content,
        'authorId': uid,
        'authorName': user?.fullName ?? 'Người dùng',
        'authorAvatarUrl': user?.avatarUrl,
        'authorRole': user?.role,
        'createdAt': FieldValue.serverTimestamp(),
      });
      try {
        await postRef.update({'commentCount': FieldValue.increment(1)});
      } catch (_) {
        // Best-effort counter; comment already persisted.
      }
      final postAuthorId = postSnap.data()?['authorId'] as String?;
      if (postAuthorId != null && postAuthorId != uid) {
        unawaited(notifyUser(
          userId: postAuthorId,
          title: 'Bình luận mới',
          content:
              '${user?.fullName ?? 'Người dùng'} đã bình luận về bài viết của bạn',
          type: 'forum',
          link: '/consumer/forum/$postId',
        ));
      }
      final snap = await commentRef.get();
      return ForumComment.fromJson(_commentJson(snap));
    } catch (e) {
      if (e is Failure) rethrow;
      throw mapFirestoreException(e);
    }
  }

  @override
  Future<ForumComment> updateComment({
    required String postId,
    required String commentId,
    required String content,
  }) async {
    try {
      final uid = _currentUid();
      if (uid == null) {
        throw const AuthFailure('Cần đăng nhập để sửa bình luận');
      }
      final commentRef = FirestoreRefs.forumCommentsRef(postId).doc(commentId);
      final snap = await commentRef.get();
      if (!snap.exists) {
        throw const ValidationFailure('Không tìm thấy bình luận');
      }
      final authorId = snap.data()?['authorId'] as String?;
      if (authorId != uid) {
        throw const AuthFailure('Chỉ sửa được bình luận của bạn');
      }
      await commentRef.update({
        'content': content,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final updated = await commentRef.get();
      return ForumComment.fromJson(_commentJson(updated));
    } catch (e) {
      if (e is Failure) rethrow;
      throw mapFirestoreException(e);
    }
  }

  @override
  Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    try {
      final uid = _currentUid();
      if (uid == null) {
        throw const AuthFailure('Cần đăng nhập để xóa bình luận');
      }
      final postRef = FirestoreRefs.forumPostsRef().doc(postId);
      final commentRef = FirestoreRefs.forumCommentsRef(postId).doc(commentId);
      final snap = await commentRef.get();
      if (!snap.exists) {
        throw const ValidationFailure('Không tìm thấy bình luận');
      }
      final authorId = snap.data()?['authorId'] as String?;
      if (authorId != uid) {
        throw const AuthFailure('Chỉ xóa được bình luận của bạn');
      }
      await commentRef.delete();
      try {
        await postRef.update({'commentCount': FieldValue.increment(-1)});
      } catch (_) {
        // Best-effort counter; comment already deleted.
      }
    } catch (e) {
      if (e is Failure) rethrow;
      throw mapFirestoreException(e);
    }
  }

  /// Firestore has no joins, so author info is denormalized straight onto
  /// each post/comment document. Reshaping it back into the nested
  /// `author: {...}` map here lets the existing `ForumPost.fromJson`/
  /// `ForumComment.fromJson` (built for the old REST response shape) be
  /// reused unchanged, keeping the domain entities storage-agnostic.
  Map<String, dynamic> _postJson(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return {
      'id': doc.id,
      'title': data['title'],
      'content': data['content'],
      'author': _authorJson(data),
      'commentCount': data['commentCount'],
      'likeCount': data['likeCount'],
      'createdAt': _isoFromTimestamp(data['createdAt']),
      'labels': data['labels'],
      'imageUrls': data['imageUrls'] ?? data['images'],
    };
  }

  Map<String, dynamic> _commentJson(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return {
      'id': doc.id,
      'content': data['content'],
      'author': _authorJson(data),
      'createdAt': _isoFromTimestamp(data['createdAt']),
    };
  }

  Map<String, dynamic> _authorJson(Map<String, dynamic> data) => {
        'id': data['authorId'],
        'fullName': data['authorName'],
        'avatarUrl': data['authorAvatarUrl'],
        'role': data['authorRole'],
      };

  String? _isoFromTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is String) return value;
    return null;
  }
}
