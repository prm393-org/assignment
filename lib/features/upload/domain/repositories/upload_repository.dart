abstract class UploadRepository {
  Future<List<String>> uploadImages(List<String> paths);
  Future<List<String>> uploadDocuments(List<String> paths);
}
