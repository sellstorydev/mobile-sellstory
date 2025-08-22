import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import 'dart:typed_data';

class UploadService extends GetxService {
  static UploadService get to => Get.find();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload image file to Firebase Storage with resize
  Future<String> uploadImage({
    required File file,
    required String workspaceId,
    required String chatroomId,
    Function(double)? onProgress,
  }) async {
    try {
      final fileName = path.basename(file.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(fileName).toLowerCase();

      // อ่านและ resize รูปภาพ
      final resizedImageBytes = await _resizeImage(file);

      // สร้าง path ที่เป็นระเบียบ
      final storagePath = 'workspaces/$workspaceId/chatrooms/$chatroomId/images/$timestamp.jpg';

      // สร้าง reference
      final ref = _storage.ref().child(storagePath);

      // อัพโหลดไฟล์ที่ resize แล้ว
      final uploadTask = ref.putData(
        resizedImageBytes,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'workspaceId': workspaceId,
            'chatroomId': chatroomId,
            'originalName': fileName,
            'uploadedAt': DateTime.now().toIso8601String(),
            'resized': 'true',
          },
        ),
      );

      // ติดตาม progress
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      // รอให้อัพโหลดเสร็จ
      final snapshot = await uploadTask;

      // ได้ download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Upload image failed: $e');
    }
  }

  /// Resize image to smaller size while maintaining quality
  Future<Uint8List> _resizeImage(File imageFile) async {
    try {
      // อ่านรูปภาพ
      final bytes = await imageFile.readAsBytes();
      final originalImage = img.decodeImage(bytes);

      if (originalImage == null) {
        throw Exception('Cannot decode image');
      }

      // กำหนดขนาดสูงสุด
      const int maxWidth = 1280;
      const int maxHeight = 1280;
      const int quality = 85; // คุณภาพ JPEG (0-100)

      // คำนวณขนาดใหม่โดยคงอัตราส่วน
      int newWidth = originalImage.width;
      int newHeight = originalImage.height;

      if (newWidth > maxWidth || newHeight > maxHeight) {
        final double aspectRatio = newWidth / newHeight;

        if (newWidth > newHeight) {
          // รูปแนวนอน
          newWidth = maxWidth;
          newHeight = (maxWidth / aspectRatio).round();
        } else {
          // รูปแนวตั้ง
          newHeight = maxHeight;
          newWidth = (maxHeight * aspectRatio).round();
        }
      }

      // Resize รูปภาพ
      final resizedImage = img.copyResize(
        originalImage,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.average, // ให้ความคมชัดสูงสุด
      );

      // แปลงเป็น JPEG พร้อมบีบอัด
      final compressedBytes = img.encodeJpg(resizedImage, quality: quality);

      // Log ข้อมูลเพื่อ debug
      final originalSize = bytes.length;
      final compressedSize = compressedBytes.length;
      final compressionRatio = ((originalSize - compressedSize) / originalSize * 100).toStringAsFixed(1);

      print('Image resize completed:');
      print('Original: ${originalImage.width}x${originalImage.height} (${(originalSize / 1024).toStringAsFixed(1)} KB)');
      print('Resized: ${newWidth}x${newHeight} (${(compressedSize / 1024).toStringAsFixed(1)} KB)');
      print('Compression: $compressionRatio% smaller');

      return Uint8List.fromList(compressedBytes);
    } catch (e) {
      throw Exception('Image resize failed: $e');
    }
  }

  /// Upload file to Firebase Storage
  Future<String> uploadFile({
    required File file,
    required String workspaceId,
    required String chatroomId,
    Function(double)? onProgress,
  }) async {
    try {
      final fileName = path.basename(file.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(fileName).toLowerCase();

      // สร้าง path ที่เป็นระเบียบ
      final storagePath = 'workspaces/$workspaceId/chatrooms/$chatroomId/files/$timestamp-$fileName';

      // สร้าง reference
      final ref = _storage.ref().child(storagePath);

      // อัพโหลดไฟล์
      final uploadTask = ref.putFile(
        file,
        SettableMetadata(
          contentType: _getContentType(extension),
          customMetadata: {
            'workspaceId': workspaceId,
            'chatroomId': chatroomId,
            'originalName': fileName,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // ติดตาม progress
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      // รอให้อัพโหลดเสร็จ
      final snapshot = await uploadTask;

      // ได้ download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Upload file failed: $e');
    }
  }

  /// Upload video file to Firebase Storage
  Future<String> uploadVideo({
    required File file,
    required String workspaceId,
    required String chatroomId,
    Function(double)? onProgress,
  }) async {
    try {
      final fileName = path.basename(file.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(fileName).toLowerCase();

      // สร้าง path ที่เป็นระเบียบ
      final storagePath = 'workspaces/$workspaceId/chatrooms/$chatroomId/videos/$timestamp$extension';

      // สร้าง reference
      final ref = _storage.ref().child(storagePath);

      // อัพโหลดไฟล์
      final uploadTask = ref.putFile(
        file,
        SettableMetadata(
          contentType: _getContentType(extension),
          customMetadata: {
            'workspaceId': workspaceId,
            'chatroomId': chatroomId,
            'originalName': fileName,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // ติดตาม progress
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      // รอให้อัพโหลดเสร็จ
      final snapshot = await uploadTask;

      // ได้ download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Upload video failed: $e');
    }
  }

  /// Get appropriate content type based on file extension
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      // Images
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';

      // Videos
      case '.mp4':
        return 'video/mp4';
      case '.mov':
        return 'video/quicktime';
      case '.avi':
        return 'video/x-msvideo';

      // Documents
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.xls':
        return 'application/vnd.ms-excel';
      case '.xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case '.ppt':
        return 'application/vnd.ms-powerpoint';
      case '.pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case '.txt':
        return 'text/plain';

      default:
        return 'application/octet-stream';
    }
  }

  /// Delete file from Firebase Storage
  Future<void> deleteFile(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Delete file failed: $e');
    }
  }

  /// Get file metadata
  Future<FullMetadata> getFileMetadata(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      return await ref.getMetadata();
    } catch (e) {
      throw Exception('Get file metadata failed: $e');
    }
  }
}
