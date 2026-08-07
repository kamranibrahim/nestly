import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import 'db/app_database.dart';
import 'repositories.dart';
import 'vault_upload_status.dart';

class VaultService {
  VaultService(this._db);

  final AppDatabase _db;
  final _storage = FirebaseStorage.instance;

  VaultRepository get _vault => VaultRepository(_db);

  Future<VaultDocument?> pickAndUpload({
    required String category,
    String? actorName,
  }) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [
        'pdf',
        'png',
        'jpg',
        'jpeg',
        'heic',
        'doc',
        'docx',
      ],
      withData: false,
    );
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.single;
    final path = file.path;
    if (path == null) return null;

    final title = p.basenameWithoutExtension(file.name);
    final timeline = TimelineRepository(_db);

    final doc = await _vault.addLocalMeta(
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

    await uploadDocument(doc.id);
    return await _vault.getById(doc.id) ?? doc;
  }

  /// Upload (or re-upload) one doc's bytes to Storage. Returns true on success.
  Future<bool> uploadDocument(String id) async {
    final doc = await _vault.getById(id);
    if (doc == null || doc.deleted) return false;

    final nestId = (await _db.getMeta('nestId')) ?? doc.nestId;
    if (nestId == null || nestId.isEmpty) return false;

    final local = doc.localPath;
    if (local == null || local.isEmpty) return false;
    final file = File(local);
    if (!await file.exists()) {
      await _vault.markUploadFailed(id);
      return false;
    }

    // Already on Storage — just normalize status.
    if (doc.storagePath != null && doc.storagePath!.isNotEmpty) {
      if (doc.uploadStatus != VaultUploadStatus.synced.storage) {
        await _vault.setUploadStatus(id, VaultUploadStatus.synced.storage);
      }
      return true;
    }

    await _vault.setUploadStatus(id, VaultUploadStatus.uploading.storage);
    try {
      final storagePath = 'nests/$nestId/vault/${doc.id}/${doc.fileName}';
      await _storage.ref(storagePath).putFile(file);
      await _vault.markUploaded(id: id, storagePath: storagePath);
      return true;
    } catch (e) {
      debugPrint('Vault upload failed: $e');
      await _vault.markUploadFailed(id);
      return false;
    }
  }

  /// Retry every pending / failed local file. Returns count uploaded.
  Future<int> retryAllFailed() async {
    final pending = await _vault.listPendingUploads();
    var ok = 0;
    for (final doc in pending) {
      if (await uploadDocument(doc.id)) ok++;
    }
    return ok;
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
      final out =
          File(p.join(dir.path, 'nestly_vault_${doc.id}_${doc.fileName}'));
      if (!await out.exists()) {
        await _storage.ref(remote).writeToFile(out);
      }
      await _vault.setLocalPath(id: doc.id, localPath: out.path);
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

  /// Share multiple docs as a pack (skips files that can't be resolved).
  Future<int> shareDocuments(
    List<VaultDocument> docs, {
    AppLocalizations? l10n,
  }) async {
    final files = <XFile>[];
    for (final doc in docs) {
      final file = await resolveFile(doc);
      if (file != null) {
        files.add(XFile(file.path, name: doc.fileName));
      }
    }
    if (files.isEmpty) {
      throw StateError(l10n?.vaultNoFilesShare ?? 'No files available to share yet.');
    }
    await SharePlus.instance.share(
      ShareParams(
        files: files,
        subject: l10n?.vaultPackSubject(files.length) ??
            'Casaio vault pack (${files.length})',
        text: l10n?.vaultPackText ?? 'Shared from Casaio vault',
      ),
    );
    return files.length;
  }
}
