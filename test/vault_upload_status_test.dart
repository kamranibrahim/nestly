import 'package:flutter_test/flutter_test.dart';
import 'package:nestly/data/vault_upload_status.dart';

void main() {
  test('needsUpload covers local and failed', () {
    expect(VaultUploadStatus.needsUpload(VaultUploadStatus.local), isTrue);
    expect(VaultUploadStatus.needsUpload(VaultUploadStatus.failed), isTrue);
    expect(VaultUploadStatus.needsUpload(VaultUploadStatus.uploading), isFalse);
    expect(VaultUploadStatus.needsUpload(VaultUploadStatus.synced), isFalse);
  });

  test('labels are human readable', () {
    expect(VaultUploadStatus.label(VaultUploadStatus.local), 'Local');
    expect(VaultUploadStatus.label(VaultUploadStatus.failed), 'Failed');
    expect(VaultUploadStatus.label(VaultUploadStatus.synced), 'Synced');
  });
}
