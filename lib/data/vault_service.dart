import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'db/app_database.dart';
import 'repositories.dart';

class VaultService {
  VaultService(this._db);

  final AppDatabase _db;
  final _storage = FirebaseStorage.instance;

  Future<VaultDocument?> pickAndUpload({
    required String category,
    String? actorName,
  }) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg', 'heic', 'doc', 'docx'],
      withData: false,
    );
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.single;
    final path = file.path;
    if (path == null) return null;

    final nestId = await _db.getMeta('nestId');
    final title = p.basenameWithoutExtension(file.name);
    final vault = VaultRepository(_db);
    final timeline = TimelineRepository(_db);

    final doc = await vault.addLocalMeta(
      title: title,
      category: category,
      fileName: file.name,
      localPath: path,
      mimeType: file.extension,
      sizeBytes: file.size,
    );

    await timeline.add(
      message: '${actorName ?? 'Someone'} added $title to the vault',
      memberName: actorName ?? 'Family',
    );

    if (nestId != null && nestId.isNotEmpty) {
      try {
        final storagePath = 'nests/$nestId/vault/${doc.id}/${file.name}';
        await _storage.ref(storagePath).putFile(File(path));
        await vault.markUploaded(id: doc.id, storagePath: storagePath);
      } catch (e) {
        debugPrint('Vault upload deferred (offline?): $e');
      }
    }

    return doc;
  }

  /// Prefer local file; otherwise download from Storage into cache.
  Future<File?> resolveFile(VaultDocument doc) async {
    final local = doc.localPath;
    if (local != null && local.isNotEmpty) {
      final f = File(local);
      if (await f.exists()) return f;
    }

    final remote = doc.storagePath;
    if (remote == null || remote.isEmpty) return null;

    try {
      final dir = await getTemporaryDirectory();
      final out = File(p.join(dir.path, 'nestly_vault_${doc.id}_${doc.fileName}'));
      if (!await out.exists()) {
        await _storage.ref(remote).writeToFile(out);
      }
      await VaultRepository(_db).setLocalPath(id: doc.id, localPath: out.path);
      return out;
    } catch (e) {
      debugPrint('Vault download failed: $e');
      return null;
    }
  }

  Future<void> shareDocument(VaultDocument doc) async {
    final file = await resolveFile(doc);
    if (file == null) {
      throw StateError('File unavailable offline and not synced yet.');
    }
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, name: doc.fileName)],
        subject: doc.title,
        text: doc.notes.trim().isEmpty ? doc.title : '${doc.title}\n${doc.notes}',
      ),
    );
  }
}
