import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Manages the app's private encrypted storage directory.
///
/// Documents are copied into a dedicated `secure_docs` folder inside the
/// application documents directory.  The SQLCipher database and Flutter
/// Secure Storage already handle key management; this service provides
/// helpers around the secure file directory.
class SecureStorageService {
  Directory? _secureDir;

  /// Initialise the secure documents directory, creating it if necessary.
  Future<Directory> get secureDirectory async {
    if (_secureDir != null) return _secureDir!;
    final appDir = await getApplicationDocumentsDirectory();
    _secureDir = Directory(p.join(appDir.path, 'secure_docs'));
    if (!_secureDir!.existsSync()) {
      await _secureDir!.create(recursive: true);
    }
    return _secureDir!;
  }

  /// Copy [file] into the secure directory, returning the new path.
  Future<String> storeFile(File file) async {
    final dir = await secureDirectory;
    final name = p.basename(file.path);
    final dest = p.join(dir.path, name);
    await file.copy(dest);
    return dest;
  }

  /// Delete a file from secure storage by its full path.
  Future<void> deleteFile(String path) async {
    final f = File(path);
    if (f.existsSync()) {
      await f.delete();
    }
  }
}
