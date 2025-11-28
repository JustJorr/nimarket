import 'dart:io';
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseImageUpload {
  final SupabaseClient _client = Supabase.instance.client;

  Future<String?> uploadImage(
    File file,
    String folder, {
    required String bucketName,
  }) async {
    try {
      final timeStamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${timeStamp}_${file.path.split('/').last}';
      final path = '$folder/$fileName';
      final bytes = await file.readAsBytes();
      final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';

      // Upload using binary version
      await _client.storage.from(bucketName).uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(
          contentType: mimeType,
          cacheControl: '3600',
          upsert: false,
        ),
      );

      return _client.storage.from(bucketName).getPublicUrl(path);

    } catch (e) {
      print('⚠️ Supabase upload error: $e');
      return null;
    }
  }

  Future<bool> deleteImage(
    String path, {
    required String bucketName,
  }) async {
    try {
      await _client.storage.from(bucketName).remove([path]);
      return true;
    } catch (e) {
      print('⚠️ Supabase delete error: $e');
      return false;
    }
  }
}
