import 'package:dio/dio.dart';
import 'package:chuoi_xanh_viet/core/error/exception_mapper.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/upload/domain/repositories/upload_repository.dart';

class UploadRepositoryImpl implements UploadRepository {
  UploadRepositoryImpl(this._dio);
  final Dio _dio;

  @override
  Future<List<String>> uploadImages(List<String> paths) async {
    return _upload(
      path: '/upload',
      field: 'images',
      paths: paths,
    );
  }

  @override
  Future<List<String>> uploadDocuments(List<String> paths) async {
    return _upload(
      path: '/upload/documents',
      field: 'documents',
      paths: paths,
    );
  }

  Future<List<String>> _upload({
    required String path,
    required String field,
    required List<String> paths,
  }) async {
    if (paths.isEmpty) return const [];
    try {
      final form = FormData();
      for (final filePath in paths) {
        form.files.add(
          MapEntry(
            field,
            await MultipartFile.fromFile(
              filePath,
              filename: _filename(filePath),
            ),
          ),
        );
      }
      final res = await _dio.post(path, data: form);
      final data = asMap(unwrapData(res.data));
      return mapList(data['items'] ?? data, (item) {
        return readString(item, ['url']);
      }).where((url) => url.isNotEmpty).toList();
    } catch (e) {
      throw mapDioException(e);
    }
  }

  String _filename(String path) {
    final normalized = path.replaceAll('\\', '/');
    final parts = normalized.split('/');
    return parts.isNotEmpty && parts.last.isNotEmpty ? parts.last : 'file';
  }
}
