import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/db/app_database.dart';
import '../data/enums.dart';
import '../data/sync_controller.dart';
import '../providers/providers.dart';
import '../state/vault_ui.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import '../widgets/sheet_form.dart';
import '../widgets/shimmer.dart';
import 'scan_document_flow.dart';
import '../l10n/l10n_ext.dart';

(IconData, Color) _folderStyle(VaultFolder folder) {
  return switch (folder) {
    VaultFolder.family => (Icons.family_restroom_rounded, AppColors.tileBlue),
    VaultFolder.health => (Icons.medical_services_rounded, AppColors.tilePink),
    VaultFolder.house => (Icons.home_rounded, AppColors.tileGreen),
    VaultFolder.work => (Icons.work_rounded, AppColors.tileOrange),
    VaultFolder.car => (Icons.directions_car_rounded, AppColors.tilePurple),
    VaultFolder.finance => (
      Icons.account_balance_rounded,
      AppColors.tileTeal,
    ),
    VaultFolder.ids => (Icons.badge_rounded, AppColors.tileYellow),
  };
}

class VaultScreen extends ConsumerWidget {
  const VaultScreen({super.key, this.initialCategory = VaultFolder.allLabel});

  final String initialCategory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiCtrl = ref.read(vaultUiProvider.notifier);
    if (!VaultFolder.isAll(initialCategory)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        uiCtrl.applyInitialCategory(initialCategory);
      });
    }

    final ui = ref.watch(vaultUiProvider);
    final docsAsync = ref.watch(vaultDocumentsProvider(ui.category));
    final allDocs =
        ref.watch(vaultDocumentsProvider(VaultFolder.allLabel)).valueOrNull ??
            const [];
    final docs = docsAsync.valueOrNull ?? const <VaultDocument>[];
    final filtered = _filtered(docs, ui.query);
    final counts = _counts(allDocs);
    final expiring =
        ref.watch(vaultExpiringSoonProvider).valueOrNull ?? const [];
    final expiryByFolder = _expiryCounts(expiring);
    final failedCount =
        ref.watch(vaultFailedUploadCountProvider).valueOrNull ?? 0;

    return PopScope(
      canPop: ui.canPopRoute,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        uiCtrl.handleBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            ui.selecting
                ? context.l10n.nSelected(ui.selectedIds.length)
                : VaultFolder.isAll(ui.category)
                    ? context.l10n.screenVault
                    : VaultFolder.parse(ui.category).display(context.l10n),
          ),
          leading: ui.selecting
              ? IconButton(
                  tooltip: context.l10n.commonCancel,
                  onPressed: uiCtrl.cancelSelecting,
                  icon: const Icon(Icons.close_rounded),
                )
              : !VaultFolder.isAll(ui.category)
                  ? IconButton(
                      tooltip: context.l10n.vaultAllFolders,
                      onPressed: uiCtrl.showAllFolders,
                      icon: const Icon(Icons.arrow_back_rounded),
                    )
                  : null,
          actions: [
            if (ui.selecting) ...[
              IconButton(
                tooltip: context.l10n.vaultSharePack,
                onPressed:
                    ui.selectedIds.isEmpty ? null : () => _sharePack(context, ref),
                icon: const Icon(Icons.ios_share_rounded),
              ),
            ] else ...[
              IconButton(
                tooltip: context.l10n.vaultSelectShare,
                onPressed: uiCtrl.startSelecting,
                icon: const Icon(Icons.checklist_rounded),
              ),
              IconButton(
                tooltip: context.l10n.vaultScanCalendar,
                onPressed: () => startDocumentScanFlow(
                  context,
                  ref,
                  hint: context.l10n.vaultScanHint,
                ),
                icon: const Icon(Icons.document_scanner_rounded),
              ),
            ],
          ],
        ),
        floatingActionButton: ui.selecting
            ? null
            : FloatingActionButton(
                onPressed: () => _upload(context, ref),
                child: const Icon(Icons.upload_file_rounded),
              ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 84),
          children: [
            TextField(
              onChanged: uiCtrl.setQuery,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: context.l10n.searchVault,
                prefixIcon: const Icon(Icons.search_rounded),
                isDense: true,
              ),
            ),
            if (failedCount > 0 && !ui.selecting) ...[
              const SizedBox(height: 10),
              NestCard(
                color: const Color(0xFFFFE8D6),
                bordered: false,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_off_outlined, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        failedCount == 1
                            ? '1 file waiting to upload'
                            : '$failedCount files waiting to upload',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed:
                          ui.retrying ? null : () => _retryAll(context, ref),
                      child: Text(ui.retrying ? '…' : context.l10n.vaultRetryAll),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            if (VaultFolder.isAll(ui.category)) ...[
              if (expiring.isNotEmpty &&
                  ui.query.isEmpty &&
                  !ui.selecting) ...[
                SectionLabel(context.l10n.vaultExpiringSoon),
                NestCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < expiring.take(4).length; i++) ...[
                        ListTile(
                          onTap: () => _openDoc(context, ref, expiring[i]),
                          leading: const Icon(
                            Icons.event_busy_rounded,
                            color: AppColors.accent,
                          ),
                          title: Text(
                            expiring[i].title,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            _expiryLabel(context.l10n, expiring[i].expiresAt),
                          ),
                          trailing: SoftPill(
                            label: _expiryBadge(expiring[i].expiresAt),
                            selected: true,
                            onTap: () => _openDoc(context, ref, expiring[i]),
                          ),
                        ),
                        if (i != expiring.take(4).length - 1)
                          const Divider(height: 1, indent: 56),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
              if (ui.query.isEmpty)
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 0.92,
                  children: [
                    for (final folder in VaultFolder.values)
                      NestCard(
                        onTap: () => uiCtrl.setCategory(folder.label),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: _folderStyle(folder).$2
                                        .withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    _folderStyle(folder).$1,
                                    color: _folderStyle(folder).$2,
                                  ),
                                ),
                                if ((expiryByFolder[folder.label] ?? 0) > 0)
                                  Positioned(
                                    right: -4,
                                    top: -4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${expiryByFolder[folder.label]}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              folder.display(context.l10n),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '${counts[folder.label] ?? 0}',
                              style: const TextStyle(
                                color: AppColors.inkMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              if (ui.query.isEmpty) ...[
                const SizedBox(height: 6),
                SectionLabel(context.l10n.vaultRecentFiles),
              ] else
                SectionLabel(context.l10n.vaultSearchResults),
            ] else
              SectionLabel(
                VaultFolder.parse(ui.category).display(context.l10n),
              ),
            docsAsync.when(
              loading: () => const NestLoadingSkeleton(itemCount: 3),
              error: (e, _) => NestCard(child: Text('$e')),
              data: (_) => NestCard(
                padding: EdgeInsets.zero,
                child: filtered.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _emptyCopy(context.l10n, ui),
                          style: const TextStyle(color: AppColors.inkMuted),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : Column(
                        children: [
                          for (var i = 0; i < filtered.length; i++) ...[
                            ListTile(
                              onTap: () => _openDoc(context, ref, filtered[i]),
                              onLongPress: () => uiCtrl.startSelecting(
                                seedId: filtered[i].id,
                              ),
                              leading: ui.selecting
                                  ? Checkbox(
                                      value: ui.selectedIds
                                          .contains(filtered[i].id),
                                      onChanged: (_) =>
                                          _openDoc(context, ref, filtered[i]),
                                    )
                                  : Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppColors.primarySoft,
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        _iconFor(filtered[i]),
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                                    ),
                              title: Text(
                                filtered[i].title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '${filtered[i].category} · ${_relative(filtered[i].updatedAt)}'
                                '${filtered[i].expiresAt == null ? '' : ' · ${_expiryLabel(context.l10n, filtered[i].expiresAt)}'}'
                                ' · ${_uploadStatusLabel(context.l10n, filtered[i].uploadStatus)}',
                              ),
                              trailing: filtered[i].uploadStatus ==
                                      VaultUploadStatus.failed.storage
                                  ? IconButton(
                                      tooltip: context.l10n.vaultRetryUpload,
                                      onPressed: () =>
                                          _retryOne(context, ref, filtered[i]),
                                      icon: const Icon(
                                        Icons.cloud_upload_outlined,
                                        color: AppColors.accentDeep,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.chevron_right_rounded,
                                      color: AppColors.inkMuted,
                                    ),
                            ),
                            if (i != filtered.length - 1)
                              const Divider(height: 1, indent: 72),
                          ],
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _upload(BuildContext context, WidgetRef ref) async {
  final ui = ref.read(vaultUiProvider);
  final cat = VaultFolder.isAll(ui.category)
      ? VaultFolder.family.label
      : ui.category;
  try {
    final doc = await ref.read(vaultServiceProvider).pickAndUpload(
          category: cat,
          actorName: 'You',
        );
    if (!context.mounted) return;
    if (doc != null) {
      final status = doc.uploadStatus;
      final msg = status == VaultUploadStatus.synced.storage
          ? 'Saved & synced ${doc.title}'
          : status == VaultUploadStatus.failed.storage
              ? context.l10n.vaultSavedOffline
              : 'Saved ${doc.title}';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      await syncAfterWrite(ref, context: context);
    }
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.vaultAddFailed('$e'))),
    );
  }
}

Future<void> _retryAll(BuildContext context, WidgetRef ref) async {
  final ctrl = ref.read(vaultUiProvider.notifier);
  ctrl.setRetrying(true);
  try {
    final n = await ref.read(vaultServiceProvider).retryAllFailed();
    await syncAfterWrite(ref, context: context, quiet: n == 0);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          n == 0
              ? context.l10n.vaultStillOffline
              : 'Uploaded $n file${n == 1 ? '' : 's'}',
        ),
      ),
    );
  } finally {
    ctrl.setRetrying(false);
  }
}

Future<void> _retryOne(
  BuildContext context,
  WidgetRef ref,
  VaultDocument doc,
) async {
  final ok = await ref.read(vaultServiceProvider).uploadDocument(doc.id);
  if (ok) await syncAfterWrite(ref, context: context);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        ok
            ? context.l10n.vaultUploaded(doc.title)
            : context.l10n.vaultUploadFailedSnack,
      ),
    ),
  );
}

Future<void> _sharePack(BuildContext context, WidgetRef ref) async {
  final selected = ref.read(vaultUiProvider).selectedIds;
  final all =
      ref.read(vaultDocumentsProvider(VaultFolder.allLabel)).valueOrNull ??
          const [];
  final docs = all.where((d) => selected.contains(d.id)).toList();
  if (docs.isEmpty) return;
  try {
    final n = await ref.read(vaultServiceProvider).shareDocuments(
          docs,
          l10n: context.l10n,
        );
    if (!context.mounted) return;
    ref.read(vaultUiProvider.notifier).cancelSelecting();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.vaultSharedFiles(n))),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$e')),
    );
  }
}

Future<void> _openDoc(
  BuildContext context,
  WidgetRef ref,
  VaultDocument doc,
) async {
  final ui = ref.read(vaultUiProvider);
  if (ui.selecting) {
    ref.read(vaultUiProvider.notifier).toggleSelected(doc.id);
    return;
  }
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (context) => _VaultDocSheet(
      doc: doc,
      folders: VaultFolder.values.map((f) => f.label).toList(),
      onRetryUpload: () => _retryOne(context, ref, doc),
    ),
  );
}

List<VaultDocument> _filtered(List<VaultDocument> docs, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return docs;
  return docs.where((d) {
    return d.title.toLowerCase().contains(q) ||
        d.fileName.toLowerCase().contains(q) ||
        d.category.toLowerCase().contains(q) ||
        d.notes.toLowerCase().contains(q);
  }).toList();
}

Map<String, int> _counts(List<VaultDocument> all) {
  final map = <String, int>{};
  for (final doc in all) {
    map[doc.category] = (map[doc.category] ?? 0) + 1;
  }
  return map;
}

Map<String, int> _expiryCounts(List<VaultDocument> expiring) {
  final map = <String, int>{};
  for (final doc in expiring) {
    map[doc.category] = (map[doc.category] ?? 0) + 1;
  }
  return map;
}

String _uploadStatusLabel(AppLocalizations l10n, String status) {
  return switch (VaultUploadStatus.parse(status)) {
    VaultUploadStatus.local => l10n.uploadLocal,
    VaultUploadStatus.uploading => l10n.uploadUploading,
    VaultUploadStatus.synced => l10n.uploadSynced,
    VaultUploadStatus.failed => l10n.uploadFailed,
  };
}

String _emptyCopy(AppLocalizations l10n, VaultUiState ui) {
  if (ui.query.isNotEmpty) {
    return l10n.vaultNoSearchMatch(ui.query);
  }
  if (VaultFolder.isAll(ui.category)) {
    return l10n.vaultEmptyBody;
  }
  final folder = _folderDisplay(l10n, ui.category);
  return l10n.vaultEmptyFolder(folder);
}

String _folderDisplay(AppLocalizations l10n, String category) {
  for (final folder in VaultFolder.values) {
    if (folder.label == category) {
      return folder.display(l10n);
    }
  }
  return category;
}

IconData _iconFor(VaultDocument doc) {
  final name = doc.fileName.toLowerCase();
  if (name.endsWith('.pdf')) return Icons.picture_as_pdf_rounded;
  if (name.endsWith('.png') ||
      name.endsWith('.jpg') ||
      name.endsWith('.jpeg') ||
      name.endsWith('.heic')) {
    return Icons.image_rounded;
  }
  return Icons.insert_drive_file_rounded;
}

String _relative(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return DateFormat.MMMd().format(dt);
}

String _expiryLabel(AppLocalizations l10n, DateTime? expiresAt) {
  if (expiresAt == null) return '';
  final today = DateTime.now();
  final day = DateTime(expiresAt.year, expiresAt.month, expiresAt.day);
  final now = DateTime(today.year, today.month, today.day);
  final days = day.difference(now).inDays;
  if (days < 0) return 'Expired ${DateFormat.MMMd().format(expiresAt)}';
  if (days == 0) return l10n.expiresToday;
  if (days == 1) return l10n.expiresTomorrow;
  if (days <= 14) return l10n.expiresInDays(days);
  return 'Expires ${DateFormat.MMMd().format(expiresAt)}';
}

String _expiryBadge(DateTime? expiresAt) {
  if (expiresAt == null) return '';
  final today = DateTime.now();
  final day = DateTime(expiresAt.year, expiresAt.month, expiresAt.day);
  final now = DateTime(today.year, today.month, today.day);
  final days = day.difference(now).inDays;
  if (days < 0) return 'Expired';
  if (days == 0) return 'Today';
  if (days == 1) return 'Tomorrow';
  return '${days}d';
}

class _VaultDocSheet extends ConsumerStatefulWidget {
  const _VaultDocSheet({
    required this.doc,
    required this.folders,
    required this.onRetryUpload,
  });

  final VaultDocument doc;
  final List<String> folders;
  final VoidCallback onRetryUpload;

  @override
  ConsumerState<_VaultDocSheet> createState() => _VaultDocSheetState();
}

class _VaultDocSheetState extends ConsumerState<_VaultDocSheet> {
  late final TextEditingController _title;
  late final TextEditingController _notes;
  late String _category;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.doc.title);
    _notes = TextEditingController(text: widget.doc.notes);
    _category = widget.doc.category;
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      await ref.read(vaultServiceProvider).shareDocument(widget.doc);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setExpiry() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.doc.expiresAt ??
          DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime(2000),
      lastDate: DateTime(2045),
      helpText: context.l10n.vaultExpiryHelp,
    );
    if (picked == null) return;
    await ref.read(vaultRepositoryProvider).updateMeta(
          id: widget.doc.id,
          expiresAt: DateTime(picked.year, picked.month, picked.day),
        );
    await syncAfterWrite(ref, context: context);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'We’ll remind you before ${DateFormat.yMMMd().format(picked)}',
        ),
      ),
    );
    Navigator.pop(context);
  }

  Future<void> _clearExpiry() async {
    await ref.read(vaultRepositoryProvider).updateMeta(
          id: widget.doc.id,
          clearExpiry: true,
        );
    await syncAfterWrite(ref, context: context);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.vaultExpiryCleared)),
    );
    Navigator.pop(context);
  }

  Future<void> _saveDetails() async {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    await ref.read(vaultRepositoryProvider).updateMeta(
          id: widget.doc.id,
          title: title,
          category: _category,
          notes: _notes.text.trim(),
        );
    await syncAfterWrite(ref, context: context);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.vaultUpdated)),
    );
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteDocumentTitle),
        content: Text(context.l10n.vaultRemoveBody(widget.doc.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.commonRemove),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(vaultRepositoryProvider).delete(widget.doc.id);
    await syncAfterWrite(ref, context: context);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.doc;
    final expiry = doc.expiresAt;
    final status = doc.uploadStatus;
    return sheetBody(
      context: context,
      children: [
        sheetHandle(),
        const SizedBox(height: 6),
        Text(
          context.l10n.vaultDetails,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          doc.fileName,
          style: const TextStyle(color: AppColors.inkMuted),
        ),
        const SizedBox(height: 6),
        Text(
          context.l10n.vaultStatusLabel(_uploadStatusLabel(context.l10n, status)),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: status == VaultUploadStatus.failed.storage
                ? AppColors.accentDeep
                : AppColors.inkSecondary,
          ),
        ),
        if (expiry != null) ...[
          const SizedBox(height: 6),
          Text(
            expiry.isBefore(DateTime.now())
                ? 'Expired ${DateFormat.yMMMd().format(expiry)} — renew or update'
                : 'Expires ${DateFormat.yMMMd().format(expiry)}',
            style: const TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: _title,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: context.l10n.commonTitle,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          context.l10n.vaultFolder,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final folder in widget.folders)
              SoftPill(
                label: VaultFolder.parse(folder).display(context.l10n),
                selected: _category == folder,
                onTap: () => setState(() => _category = folder),
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notes,
          minLines: 2,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: context.l10n.commonNotes,
            hintText: context.l10n.vaultNotesHint,
          ),
        ),
        const SizedBox(height: 10),
        if (VaultUploadStatus.needsUpload(status)) ...[
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              widget.onRetryUpload();
            },
            icon: const Icon(Icons.cloud_upload_outlined),
            label: Text(context.l10n.vaultRetryUpload),
          ),
          const SizedBox(height: 8),
        ],
        FilledButton.icon(
          onPressed: _busy ? null : _share,
          icon: const Icon(Icons.ios_share_rounded),
          label: Text(
            _busy ? context.l10n.vaultPreparing : context.l10n.vaultShareOpen,
          ),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: _saveDetails,
          child: Text(context.l10n.saveDetails),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _setExpiry,
          icon: const Icon(Icons.event_rounded),
          label: Text(
            expiry == null
                ? context.l10n.vaultSetExpiry
                : context.l10n.vaultChangeExpiry,
          ),
        ),
        if (expiry != null) ...[
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _clearExpiry,
            child: Text(context.l10n.vaultClearExpiry),
          ),
        ],
        const SizedBox(height: 8),
        TextButton(
          onPressed: _delete,
          child: Text(
            context.l10n.vaultRemoveFrom,
            style: const TextStyle(color: AppColors.danger),
          ),
        ),
      ],
    );
  }
}
