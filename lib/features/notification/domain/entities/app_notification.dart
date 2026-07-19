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
