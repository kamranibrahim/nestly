import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

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
}
