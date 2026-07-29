import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/db/app_database.dart';
import '../providers/providers.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';

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

  @override
  Widget build(BuildContext context) {
    final docsAsync = ref.watch(vaultDocumentsProvider(_category));
    final docs = docsAsync.valueOrNull ?? const <VaultDocument>[];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_category == 'All' ? 'Documents' : _category),
        actions: [
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          if (_category == 'All') ...[
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
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
                        const SizedBox(height: 10),
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
            const SizedBox(height: 20),
            const SectionLabel('Recent files'),
          ] else
            SectionLabel(_category),
          NestCard(
            padding: EdgeInsets.zero,
            child: docs.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
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
}
