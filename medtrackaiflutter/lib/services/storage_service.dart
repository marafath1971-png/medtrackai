import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../core/utils/logger.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> saveLocalImage(File imageFile) async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final medicineDir = Directory(p.join(appDocDir.path, 'medicines'));
      
      if (!await medicineDir.exists()) {
        await medicineDir.create(recursive: true);
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final permanentFile = File(p.join(medicineDir.path, fileName));
      
      // Compress the image aggressively for low-end hardware compatibility
      final tempPath = p.join(medicineDir.path, 'temp_$fileName');
      final compressedXFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        tempPath,
        quality: 60,
        minWidth: 800,
        minHeight: 800,
      );

      if (compressedXFile != null) {
        final compressedFile = File(compressedXFile.path);
        await compressedFile.copy(permanentFile.path);
        await compressedFile.delete(); // Clean up temp
      } else {
        // Fallback to original if compression fails
        await imageFile.copy(permanentFile.path);
      }

      appLogger.i('[StorageService] Local image saved permanently: ${permanentFile.path}');
      return permanentFile.path;
    } catch (e) {
      appLogger.e('[StorageService] Local image save failed: $e');
      return null;
    }
  }

  Future<String?> uploadMedicineImage(String uid, File imageFile) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage
          .ref()
          .child('users')
          .child(uid)
          .child('medicines')
          .child(fileName);

      // Compress the image aggressively before upload
      final tempDir = await getTemporaryDirectory();
      final tempPath = p.join(tempDir.path, 'upload_temp_$fileName');
      final compressedXFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        tempPath,
        quality: 60,
        minWidth: 800,
        minHeight: 800,
      );
      
      final fileToUpload = compressedXFile != null ? File(compressedXFile.path) : imageFile;

      // 1. Wait for upload to COMPLETE before proceding, with a 15-second timeout
      final task = ref.putFile(
        fileToUpload,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await task.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw FirebaseException(
            plugin: 'firebase_storage',
            code: 'deadline-exceeded',
            message:
                'Image upload timed out after 15 seconds. Please check your network connection.',
          );
        },
      );

      if (snapshot.state == TaskState.success) {
        // 2. Wrap getDownloadURL in a small micro-delay or verification
        // for race conditions in some storage regions
        final downloadUrl = await ref.getDownloadURL();
        appLogger
            .i('[StorageService] Image uploaded successfully: $downloadUrl');
        
        // Clean up temporary compressed file
        if (fileToUpload.path != imageFile.path && await fileToUpload.exists()) {
          await fileToUpload.delete();
        }
        
        return downloadUrl;
      }
      return null;
    } on FirebaseException catch (e) {
      if (e.code == 'canceled') {
        appLogger.w('[StorageService] Upload canceled by user/system.');
      } else {
        appLogger.e(
            '[StorageService] Image upload failed (${e.code}): ${e.message}');
      }
      return null;
    } catch (e) {
      appLogger.e('[StorageService] Unexpected upload error: $e');
      return null;
    }
  }

  Future<void> deleteImage(String url) async {
    try {
      if (!url.startsWith('http')) {
        // Local file
        final file = File(url);
        if (await file.exists()) {
          await file.delete();
          appLogger.i('[StorageService] Local image deleted: $url');
        }
        return;
      }
      final ref = _storage.refFromURL(url);
      await ref.delete();
      appLogger.i('[StorageService] Image deleted successfully: $url');
    } catch (e) {
      appLogger.e('[StorageService] Image deletion failed: $e');
    }
  }
}
