import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/db/app_database.dart';
import '../providers/providers.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import '../widgets/sheet_form.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved ${doc.title}')),
        );
        try {
          await ref.read(syncServiceProvider).syncAll();
        } catch (_) {}
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    }
  }

  Future<void> _openDoc(VaultDocument doc) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => _VaultDocSheet(doc: doc),
    );
  }

  @override
  Widget build(BuildContext context) {
    final docsAsync = ref.watch(vaultDocumentsProvider(_category));
    final docs = docsAsync.valueOrNull ?? const <VaultDocument>[];
    final expiring =
        ref.watch(vaultExpiringSoonProvider).valueOrNull ?? const [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_category == 'All' ? 'Documents' : _category),
        actions: [
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _upload,
        child: const Icon(Icons.upload_file_rounded),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(10, 4, 10, 72),
        children: [
          if (_category == 'All') ...[
            if (expiring.isNotEmpty) ...[
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
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.inkMuted,
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
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: folder.$3.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(folder.$1, color: folder.$3),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          folder.$2,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            const SectionLabel('Recent files'),
          ] else
            SectionLabel(_category),
          NestCard(
            padding: EdgeInsets.zero,
            child: docs.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'No documents yet. Tap + to add one.',
                      style: TextStyle(color: AppColors.inkMuted),
                      textAlign: TextAlign.center,
                    ),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < docs.length; i++) ...[
                        ListTile(
                          onTap: () => _openDoc(docs[i]),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _iconFor(docs[i]),
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            docs[i].title,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${docs[i].category} · ${_relative(docs[i].updatedAt)}'
                            '${docs[i].expiresAt == null ? '' : ' · ${_expiryLabel(docs[i].expiresAt)}'}'
                            '${docs[i].storagePath == null ? ' · local' : ''}',
                          ),
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.inkMuted,
                          ),
                        ),
                        if (i != docs.length - 1)
                          const Divider(height: 1, indent: 72),
                      ],
                    ],
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
    return 'Expires ${DateFormat.MMMd().format(expiresAt)}';
  }
}

class _VaultDocSheet extends ConsumerStatefulWidget {
  const _VaultDocSheet({required this.doc});

  final VaultDocument doc;

  @override
  ConsumerState<_VaultDocSheet> createState() => _VaultDocSheetState();
}

class _VaultDocSheetState extends ConsumerState<_VaultDocSheet> {
  late final TextEditingController _notes;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _notes = TextEditingController(text: widget.doc.notes);
  }

  @override
  void dispose() {
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
    );
    if (picked == null) return;
    await ref.read(vaultRepositoryProvider).updateMeta(
          id: widget.doc.id,
          expiresAt: DateTime(picked.year, picked.month, picked.day),
        );
    try {
      await ref.read(syncServiceProvider).syncAll();
    } catch (_) {}
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Expiry set to ${DateFormat.yMMMd().format(picked)}'),
      ),
    );
    Navigator.pop(context);
  }

  Future<void> _saveNotes() async {
    await ref.read(vaultRepositoryProvider).updateMeta(
          id: widget.doc.id,
          notes: _notes.text.trim(),
        );
    try {
      await ref.read(syncServiceProvider).syncAll();
    } catch (_) {}
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notes saved')),
    );
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
    try {
      await ref.read(syncServiceProvider).syncAll();
    } catch (_) {}
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.doc;
    final expiry = doc.expiresAt;
    return sheetBody(
      context: context,
      children: [
        sheetHandle(),
        const SizedBox(height: 6),
        Text(
          doc.title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          '${doc.category} · ${doc.fileName}',
          style: const TextStyle(color: AppColors.inkMuted),
        ),
        if (expiry != null) ...[
          const SizedBox(height: 6),
          Text(
            'Expires ${DateFormat.yMMMd().format(expiry)}',
            style: const TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
        FilledButton.icon(
          onPressed: _busy ? null : _share,
          icon: const Icon(Icons.ios_share_rounded),
          label: Text(_busy ? 'Preparing…' : 'Share / open'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _setExpiry,
          icon: const Icon(Icons.event_rounded),
          label: Text(expiry == null ? 'Set expiry date' : 'Change expiry'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _saveNotes,
          child: const Text('Save notes'),
        ),
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
