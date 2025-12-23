import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageStorage {
  static const String _folderName = 'id_images';

  static Future<Directory> _imagesDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, _folderName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static String _safeImageExtension(String sourcePath) {
    final ext = p.extension(sourcePath).toLowerCase();
    const allowed = {'.jpg', '.jpeg', '.png', '.heic', '.webp'};
    return allowed.contains(ext) ? ext : '.jpg';
  }

  /// Copy [sourcePath] into app Documents/id_images and return the new (permanent) path.
  /// If anything fails, returns [sourcePath] so the UI can still show the picked image.
  static Future<String> savePermanently({
    required String sourcePath,
    required String prefix,
  }) async {
    final src = File(sourcePath);
    if (!await src.exists()) return sourcePath;

    try {
      final dir = await _imagesDir();
      final ext = _safeImageExtension(sourcePath);
      final name = '${prefix}_${DateTime.now().millisecondsSinceEpoch}$ext';
      final destPath = p.join(dir.path, name);

      final copied = await src.copy(destPath);
      return await copied.exists() ? copied.path : sourcePath;
    } catch (_) {
      return sourcePath;
    }
  }

  /// Deletes a file at [path] if it exists. Safe to call even if missing.
  static Future<void> deleteIfExists(String? path) async {
    final cleaned = path?.trim();
    if (cleaned == null || cleaned.isEmpty) return;

    try {
      final file = File(cleaned);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // ignore
    }
  }

  /// If the image was replaced, delete the old stored file safely.
  static Future<void> deleteOldIfReplaced({
    required String? oldPath,
    required String? newPath,
  }) async {
    final oldClean = oldPath?.trim();
    final newClean = newPath?.trim();

    if (oldClean == null || oldClean.isEmpty) return;
    if (newClean == null || newClean.isEmpty) return;
    if (oldClean == newClean) return;

    await deleteIfExists(oldClean);
  }
}
