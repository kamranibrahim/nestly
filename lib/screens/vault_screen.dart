import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/db/app_database.dart';
import '../data/sync_controller.dart';
import '../data/vault_upload_status.dart';
import '../providers/providers.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import '../widgets/sheet_form.dart';
import '../widgets/shimmer.dart';
import 'scan_document_flow.dart';

class VaultScreen extends ConsumerStatefulWidget {
  const VaultScreen({super.key, this.initialCategory = 'All'});

  final String initialCategory;

  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends ConsumerState<VaultScreen> {
  static const _folders = [
    (Icons.family_restroom_rounded, 'Family', AppColors.tileBlue),
    (Icons.medical_services_rounded, 'Health', AppColors.tilePink),
    (Icons.home_rounded, 'House', AppColors.tileGreen),
    (Icons.work_rounded, 'Work', AppColors.tileOrange),
    (Icons.directions_car_rounded, 'Car', AppColors.tilePurple),
    (Icons.account_balance_rounded, 'Finance', AppColors.tileTeal),
    (Icons.badge_rounded, 'IDs', AppColors.tileYellow),
  ];

  late String _category;
  String _query = '';
  bool _selecting = false;
  final Set<String> _selectedIds = {};
  bool _retrying = false;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
  }

  Future<void> _upload() async {
    final cat = _category == 'All' ? 'Family' : _category;
    try {
      final doc = await ref.read(vaultServiceProvider).pickAndUpload(
            category: cat,
            actorName: 'You',
          );
      if (!mounted) return;
      if (doc != null) {
        final status = doc.uploadStatus;
        final msg = status == VaultUploadStatus.synced
            ? 'Saved & synced ${doc.title}'
            : status == VaultUploadStatus.failed
                ? 'Saved on device — will upload when online'
                : 'Saved ${doc.title}';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        await syncAfterWrite(ref, context: context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not add file: $e')),
      );
    }
  }

  Future<void> _retryAll() async {
    setState(() => _retrying = true);
    try {
      final n = await ref.read(vaultServiceProvider).retryAllFailed();
      await syncAfterWrite(ref, context: context, quiet: n == 0);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            n == 0
                ? 'Still offline — files stay on this device'
                : 'Uploaded $n file${n == 1 ? '' : 's'}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  Future<void> _retryOne(VaultDocument doc) async {
    final ok = await ref.read(vaultServiceProvider).uploadDocument(doc.id);
    if (ok) await syncAfterWrite(ref, context: context);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Uploaded ${doc.title}' : 'Upload failed — try again later'),
      ),
    );
  }

  Future<void> _sharePack() async {
    final all =
        ref.read(vaultDocumentsProvider('All')).valueOrNull ?? const [];
    final docs = all.where((d) => _selectedIds.contains(d.id)).toList();
    if (docs.isEmpty) return;
    try {
      final n = await ref.read(vaultServiceProvider).shareDocuments(docs);
      if (!mounted) return;
      setState(() {
        _selecting = false;
        _selectedIds.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Shared $n file${n == 1 ? '' : 's'}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  Future<void> _openDoc(VaultDocument doc) async {
    if (_selecting) {
      setState(() {
        if (_selectedIds.contains(doc.id)) {
          _selectedIds.remove(doc.id);
        } else {
          _selectedIds.add(doc.id);
        }
      });
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
        folders: _folders.map((f) => f.$2).toList(),
        onRetryUpload: () => _retryOne(doc),
      ),
    );
  }

  List<VaultDocument> _filtered(List<VaultDocument> docs) {
    final q = _query.trim().toLowerCase();
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

  String _emptyCopy() {
    if (_query.isNotEmpty) {
      return 'No documents match “$_query”. Try a title, note, or folder name.';
    }
    if (_category == 'All') {
      return 'No documents yet. Tap + to add IDs, insurance, or house papers.';
    }
    return 'Nothing in $_category yet. Tap + to add a file here.';
  }

  @override
  Widget build(BuildContext context) {
    final docsAsync = ref.watch(vaultDocumentsProvider(_category));
    final allDocs =
        ref.watch(vaultDocumentsProvider('All')).valueOrNull ?? const [];
    final docs = docsAsync.valueOrNull ?? const <VaultDocument>[];
    final filtered = _filtered(docs);
    final counts = _counts(allDocs);
    final expiring =
        ref.watch(vaultExpiringSoonProvider).valueOrNull ?? const [];
    final expiryByFolder = _expiryCounts(expiring);
    final failedCount =
        ref.watch(vaultFailedUploadCountProvider).valueOrNull ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _selecting
              ? '${_selectedIds.length} selected'
              : _category == 'All'
                  ? 'Documents'
                  : _category,
        ),
        leading: _selecting
            ? IconButton(
                tooltip: 'Cancel',
                onPressed: () => setState(() {
                  _selecting = false;
                  _selectedIds.clear();
                }),
                icon: const Icon(Icons.close_rounded),
              )
            : null,
        actions: [
          if (_selecting) ...[
            IconButton(
              tooltip: 'Share pack',
              onPressed: _selectedIds.isEmpty ? null : _sharePack,
              icon: const Icon(Icons.ios_share_rounded),
            ),
          ] else ...[
            IconButton(
              tooltip: 'Select to share',
              onPressed: () => setState(() => _selecting = true),
              icon: const Icon(Icons.checklist_rounded),
            ),
            IconButton(
              tooltip: 'Scan to calendar',
              onPressed: () => startDocumentScanFlow(
                context,
                ref,
                hint: 'This may be a family document or invitation',
              ),
              icon: const Icon(Icons.document_scanner_rounded),
            ),
            if (_category != 'All')
              TextButton(
                onPressed: () => setState(() => _category = 'All'),
                child: const Text('All'),
              ),
          ],
        ],
      ),
      floatingActionButton: _selecting
          ? null
          : FloatingActionButton(
              onPressed: _upload,
              child: const Icon(Icons.upload_file_rounded),
            ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(10, 4, 10, 72),
        children: [
          TextField(
            onChanged: (value) => setState(() => _query = value),
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'Search by title, notes, or folder',
              prefixIcon: Icon(Icons.search_rounded),
              isDense: true,
            ),
          ),
          if (failedCount > 0 && !_selecting) ...[
            const SizedBox(height: 10),
            NestCard(
              color: const Color(0xFFFFE8D6),
              bordered: false,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    onPressed: _retrying ? null : _retryAll,
                    child: Text(_retrying ? '…' : 'Retry all'),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          if (_category == 'All') ...[
            if (expiring.isNotEmpty && _query.isEmpty && !_selecting) ...[
              const SectionLabel('Expiring soon'),
              NestCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < expiring.take(4).length; i++) ...[
                      ListTile(
                        onTap: () => _openDoc(expiring[i]),
                        leading: const Icon(
                          Icons.event_busy_rounded,
                          color: AppColors.accent,
                        ),
                        title: Text(
                          expiring[i].title,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(_expiryLabel(expiring[i].expiresAt)),
                        trailing: SoftPill(
                          label: _expiryBadge(expiring[i].expiresAt),
                          selected: true,
                          onTap: () => _openDoc(expiring[i]),
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
            if (_query.isEmpty)
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 0.92,
                children: [
                  for (final folder in _folders)
                    NestCard(
                      onTap: () => setState(() => _category = folder.$2),
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
                                  color: folder.$3.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(folder.$1, color: folder.$3),
                              ),
                              if ((expiryByFolder[folder.$2] ?? 0) > 0)
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
                                      '${expiryByFolder[folder.$2]}',
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
                            folder.$2,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '${counts[folder.$2] ?? 0}',
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
            if (_query.isEmpty) ...[
              const SizedBox(height: 6),
              const SectionLabel('Recent files'),
            ] else
              const SectionLabel('Search results'),
          ] else
            SectionLabel(_category),
          docsAsync.when(
            loading: () => const NestLoadingSkeleton(itemCount: 3),
            error: (e, _) => NestCard(child: Text('$e')),
            data: (_) => NestCard(
              padding: EdgeInsets.zero,
              child: filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _emptyCopy(),
                        style: const TextStyle(color: AppColors.inkMuted),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < filtered.length; i++) ...[
                          ListTile(
                            onTap: () => _openDoc(filtered[i]),
                            onLongPress: () {
                              setState(() {
                                _selecting = true;
                                _selectedIds.add(filtered[i].id);
                              });
                            },
                            leading: _selecting
                                ? Checkbox(
                                    value: _selectedIds.contains(filtered[i].id),
                                    onChanged: (_) => _openDoc(filtered[i]),
                                  )
                                : Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppColors.primarySoft,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      _iconFor(filtered[i]),
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                  ),
                            title: Text(
                              filtered[i].title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              '${filtered[i].category} · ${_relative(filtered[i].updatedAt)}'
                              '${filtered[i].expiresAt == null ? '' : ' · ${_expiryLabel(filtered[i].expiresAt)}'}'
                              ' · ${VaultUploadStatus.label(filtered[i].uploadStatus)}',
                            ),
                            trailing: filtered[i].uploadStatus ==
                                    VaultUploadStatus.failed
                                ? IconButton(
                                    tooltip: 'Retry upload',
                                    onPressed: () => _retryOne(filtered[i]),
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
    );
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

  String _expiryLabel(DateTime? expiresAt) {
    if (expiresAt == null) return '';
    final today = DateTime.now();
    final day = DateTime(expiresAt.year, expiresAt.month, expiresAt.day);
    final now = DateTime(today.year, today.month, today.day);
    final days = day.difference(now).inDays;
    if (days < 0) return 'Expired ${DateFormat.MMMd().format(expiresAt)}';
    if (days == 0) return 'Expires today';
    if (days == 1) return 'Expires tomorrow';
    if (days <= 14) return 'Expires in $days days';
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
      helpText: 'When does this expire?',
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
      const SnackBar(content: Text('Expiry reminder cleared')),
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
      const SnackBar(content: Text('Document updated')),
    );
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove document?'),
        content: Text('Remove “${widget.doc.title}” from the nest vault.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
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
        const Text(
          'Document details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          doc.fileName,
          style: const TextStyle(color: AppColors.inkMuted),
        ),
        const SizedBox(height: 6),
        Text(
          'Status · ${VaultUploadStatus.label(status)}',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: status == VaultUploadStatus.failed
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
          decoration: const InputDecoration(
            labelText: 'Title',
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Folder',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final folder in widget.folders)
              SoftPill(
                label: folder,
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
          decoration: const InputDecoration(
            labelText: 'Notes',
            hintText: 'Renewal tips, last-4, who holds the original…',
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
            label: const Text('Retry upload'),
          ),
          const SizedBox(height: 8),
        ],
        FilledButton.icon(
          onPressed: _busy ? null : _share,
          icon: const Icon(Icons.ios_share_rounded),
          label: Text(_busy ? 'Preparing…' : 'Share / open'),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: _saveDetails,
          child: const Text('Save details'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _setExpiry,
          icon: const Icon(Icons.event_rounded),
          label: Text(
            expiry == null ? 'Set expiry reminder' : 'Change expiry date',
          ),
        ),
        if (expiry != null) ...[
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _clearExpiry,
            child: const Text('Clear expiry reminder'),
          ),
        ],
        const SizedBox(height: 8),
        TextButton(
          onPressed: _delete,
          child: const Text(
            'Remove from vault',
            style: TextStyle(color: AppColors.danger),
          ),
        ),
      ],
    );
  }
}
