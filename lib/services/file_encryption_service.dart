import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'content_encryption_service.dart';

/// Encrypts document content with AES-256-GCM before it enters app storage.
class FileEncryptionService {
  FileEncryptionService({required String keyMaterial})
      : _contentEncryption =
            ContentEncryptionService(keyMaterial: keyMaterial);

  final ContentEncryptionService _contentEncryption;

  Future<void> encryptFile({
    required String sourcePath,
    required String destinationPath,
  }) async {
    final bytes = await File(sourcePath).readAsBytes();
    final encrypted = await _contentEncryption.encrypt(bytes);
    await File(destinationPath).writeAsBytes(
      encrypted,
      flush: true,
    );
  }

  Future<File> decryptToFile({
    required String sourcePath,
    required String destinationPath,
  }) async {
    final encrypted = await File(sourcePath).readAsBytes();
    final decrypted = await _contentEncryption.decrypt(encrypted);
    final file = File(destinationPath);
    await file.writeAsBytes(decrypted, flush: true);
    return file;
  }

  Future<File> decryptForViewing(String encryptedPath) async {
    final directory = await getTemporaryDirectory();
    final viewDirectory = Directory(path.join(directory.path, 'weka_cert_view'));
    await viewDirectory.create(recursive: true);
    final viewPath = path.join(
      viewDirectory.path,
      '${path.basenameWithoutExtension(encryptedPath)}${path.extension(encryptedPath)}',
    );
    return decryptToFile(sourcePath: encryptedPath, destinationPath: viewPath);
  }

}
