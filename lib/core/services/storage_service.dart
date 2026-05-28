import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../constants/app_constants.dart';
import '../errors/exceptions.dart';
import '../utils/logger.dart';

class StorageService {
  // Lazy getter — only accessed when Firebase is available.
  FirebaseStorage get _storage => FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  final _uuid = const Uuid();

  /// Compresses an image to JPEG ≤ 800×800 at 80% quality.
  /// Returns the compressed [File], or the original if compression fails.
  Future<File> _compressImage(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = '${dir.path}/${_uuid.v4()}.jpg';
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 80,
        minWidth: 800,
        minHeight: 800,
        format: CompressFormat.jpeg,
      );
      return result != null ? File(result.path) : file;
    } catch (_) {
      return file;
    }
  }

  /// Pick an image from gallery and upload to Firebase Storage.
  /// Returns the download URL.
  Future<String> pickAndUploadAvatar(String userId) async {
    final xFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
    );

    if (xFile == null) throw const ServerException(message: 'No image selected');

    final raw = File(xFile.path);
    final fileSize = await raw.length();
    if (fileSize > AppConstants.maxImageSizeBytes) {
      throw const ServerException(message: 'Image must be smaller than 5 MB');
    }

    final compressed = await _compressImage(raw);
    return _uploadFile(
      file: compressed,
      path: '${AppConstants.avatarsPath}/$userId/avatar.jpg',
      contentType: 'image/jpeg',
    );
  }

  /// Compress and upload a payment receipt; returns the download URL.
  Future<String> uploadReceiptFile(File file, String bookingId) async {
    final compressed = await _compressImage(file);
    return _uploadFile(
      file: compressed,
      path: 'receipts/$bookingId.jpg',
      contentType: 'image/jpeg',
    );
  }

  /// Upload a tournament cover image.
  Future<String> uploadTournamentImage(File file, String tournamentId) async {
    final fileName = '${_uuid.v4()}.jpg';
    return _uploadFile(
      file: file,
      path: '${AppConstants.tournamentImagesPath}/$tournamentId/$fileName',
      contentType: 'image/jpeg',
    );
  }

  /// Upload a venue image; returns the download URL.
  Future<String> uploadVenueImage(File file, String venueId) async {
    final compressed = await _compressImage(file);
    final fileName = '${_uuid.v4()}.jpg';
    return _uploadFile(
      file: compressed,
      path: 'venue_images/$venueId/$fileName',
      contentType: 'image/jpeg',
    );
  }

  Future<String> _uploadFile({
    required File file,
    required String path,
    required String contentType,
  }) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: contentType),
      );

      // Log progress (optional)
      uploadTask.snapshotEvents.listen((snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        AppLogger.debug('Upload progress: ${(progress * 100).toStringAsFixed(0)}%');
      });

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      AppLogger.info('File uploaded: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      AppLogger.error('Upload failed', e);
      throw ServerException(message: 'Failed to upload file: $e');
    }
  }

  Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      AppLogger.warning('Failed to delete file', e);
    }
  }
}

final storageServiceProvider = Provider<StorageService>(
  (ref) => StorageService(),
);
