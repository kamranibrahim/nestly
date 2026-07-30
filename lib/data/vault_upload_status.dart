/// Upload lifecycle for vault files (Firebase Storage), separate from Firestore [dirty].
abstract final class VaultUploadStatus {
  static const local = 'local';
  static const uploading = 'uploading';
  static const synced = 'synced';
  static const failed = 'failed';

  static const all = {local, uploading, synced, failed};

  static String label(String status) {
    switch (status) {
      case uploading:
        return 'Uploading';
      case synced:
        return 'Synced';
      case failed:
        return 'Failed';
      case local:
      default:
        return 'Local';
    }
  }

  /// Needs a Storage put (has bytes on device, not yet on Storage).
  static bool needsUpload(String status) =>
      status == local || status == failed;
}
