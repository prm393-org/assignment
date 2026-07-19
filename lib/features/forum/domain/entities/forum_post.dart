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
