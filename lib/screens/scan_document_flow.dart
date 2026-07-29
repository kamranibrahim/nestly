import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/document_ai_service.dart';
import '../providers/providers.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import '../widgets/sheet_form.dart';

final documentAiServiceProvider = Provider<DocumentAiService>((ref) {
  return DocumentAiService();
});

/// Pick a photo/PDF, run AI parse, confirm, and save into the nest.
Future<void> startDocumentScanFlow(
  BuildContext context,
  WidgetRef ref, {
  String? hint,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);

  final user = ref.read(authStateProvider).valueOrNull;
  if (user == null) {
    messenger?.showSnackBar(
      const SnackBar(content: Text('Sign in to scan documents.')),
    );
    return;
  }

  final resolvedHint = hint ?? await _pickScanHint(context);
  if (!context.mounted) return;
  if (resolvedHint == null) return;

  late final FilePickerResult? picked;
  try {
    picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'heic', 'pdf'],
      withData: true,
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not open the file picker: ${_friendlyError(e)}')),
    );
    return;
  }
  if (!context.mounted) return;
  if (picked == null || picked.files.isEmpty) return;

  final file = picked.files.first;
  final bytes = await _bytesFromPickedFile(file);
  if (!context.mounted) return;
  if (bytes == null || bytes.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Could not read that file. Try a smaller JPEG/PNG or PDF.',
        ),
      ),
    );
    return;
  }

  if (bytes.length > 4 * 1024 * 1024) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('File is too large — keep photos/PDFs under ~4 MB.'),
      ),
    );
    return;
  }

  final mime = _mimeFor(file.extension, file.name);

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (_) => const Center(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
              SizedBox(width: 14),
              Flexible(
                child: Text('Reading document…\nUsually under a minute'),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  try {
    final draft = await ref.read(documentAiServiceProvider).parseDocument(
          bytes: bytes,
          mimeType: mime,
          hint: resolvedHint.isEmpty ? null : resolvedHint,
        );
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    await showDocumentDraftSheet(context, ref, draft);
  } catch (e) {
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_friendlyError(e)),
        duration: const Duration(seconds: 5),
      ),
    );
  }
}

Future<Uint8List?> _bytesFromPickedFile(PlatformFile file) async {
  if (file.bytes != null && file.bytes!.isNotEmpty) {
    return Uint8List.fromList(file.bytes!);
  }
  if (!kIsWeb && file.path != null && file.path!.isNotEmpty) {
    try {
      return await File(file.path!).readAsBytes();
    } catch (_) {
      return null;
    }
  }
  return null;
}

Future<String?> _pickScanHint(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              sheetHandle(),
              const SizedBox(height: 10),
              const Text(
                'What are you scanning?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'A hint helps Nestly pick the right draft.',
                style: TextStyle(color: AppColors.inkSecondary),
              ),
              const SizedBox(height: 14),
              for (final option in const [
                (label: 'Receipt', hint: 'Store receipt — extract total as expense'),
                (label: 'Invite / event', hint: 'Invitation or appointment — calendar event'),
                (label: 'School notice', hint: 'School notice or sports schedule'),
                (label: 'Bill', hint: 'Utility or service bill'),
                (label: 'Other', hint: ''),
              ]) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    option.label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.pop(context, option.hint),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

Future<void> showDocumentDraftSheet(
  BuildContext context,
  WidgetRef ref,
  DocumentDraft draft,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (context) => _DraftConfirmSheet(draft: draft),
  );
}

String _mimeFor(String? extension, String name) {
  final ext = (extension ?? name.split('.').last).toLowerCase();
  return switch (ext) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    'heic' => 'image/heic',
    'heif' => 'image/heif',
    'pdf' => 'application/pdf',
    _ => 'image/jpeg',
  };
}

String _friendlyError(Object e) {
  if (e is DocumentAiException) return e.message;
  final raw = '$e'
      .replaceFirst(RegExp(r'^Bad state:\s*'), '')
      .replaceFirst(RegExp(r'^Exception:\s*'), '')
      .trim();
  return raw.isEmpty ? 'Scan failed. Try again.' : raw;
}

class _DraftConfirmSheet extends ConsumerStatefulWidget {
  const _DraftConfirmSheet({required this.draft});

  final DocumentDraft draft;

  @override
  ConsumerState<_DraftConfirmSheet> createState() => _DraftConfirmSheetState();
}

class _DraftConfirmSheetState extends ConsumerState<_DraftConfirmSheet> {
  late final TextEditingController _title;
  late final TextEditingController _location;
  late final TextEditingController _amount;
  late final TextEditingController _category;
  late final TextEditingController _notes;
  late String _kind;
  late bool _allDay;
  late DateTime _startsAt;
  DateTime? _endsAt;
  late String _assigneeId;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final d = widget.draft;
    _title = TextEditingController(text: d.title);
    _kind = d.kind == 'unknown' ? 'event' : d.kind;
    if (_kind != 'event' && _kind != 'expense' && _kind != 'task') {
      _kind = d.amount != null ? 'expense' : 'event';
    }
    _allDay = d.allDay;
    _startsAt = d.startsAt ?? DateTime.now().add(const Duration(hours: 1));
    _endsAt = d.endsAt;
    _location = TextEditingController(text: d.location ?? '');
    _amount = TextEditingController(
      text: d.amount == null ? '' : d.amount!.toStringAsFixed(2),
    );
    _category = TextEditingController(
      text: (d.category == null || d.category!.isEmpty)
          ? (_kind == 'expense' ? 'General' : 'Family')
          : d.category!,
    );
    _notes = TextEditingController(text: d.notes ?? d.summary ?? '');
    _assigneeId = '';
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _amount.dispose();
    _category.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickStarts() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startsAt,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (date == null || !mounted) return;
    TimeOfDay? time;
    if (!_allDay) {
      time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_startsAt),
      );
    }
    if (!mounted) return;
    setState(() {
      _startsAt = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? (_allDay ? 9 : _startsAt.hour),
        time?.minute ?? (_allDay ? 0 : _startsAt.minute),
      );
    });
  }

  Future<void> _pickEnds() async {
    final initial = _endsAt ?? _startsAt.add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (date == null || !mounted) return;
    TimeOfDay? time;
    if (!_allDay) {
      time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initial),
      );
    }
    if (!mounted) return;
    setState(() {
      _endsAt = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? (_allDay ? 17 : initial.hour),
        time?.minute ?? (_allDay ? 0 : initial.minute),
      );
    });
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a title before saving')),
      );
      return;
    }
    if (_kind == 'expense') {
      final amount = double.tryParse(_amount.text.trim());
      if (amount == null || amount < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid amount')),
        );
        return;
      }
    }

    setState(() => _busy = true);
    try {
      final members = ref.read(membersProvider).valueOrNull ?? const [];
      final memberId = _assigneeId.isNotEmpty
          ? _assigneeId
          : (members.isNotEmpty ? members.first.id : '');
      final category = _category.text.trim().isEmpty
          ? (_kind == 'expense' ? 'General' : 'Family')
          : _category.text.trim();

      switch (_kind) {
        case 'expense':
          final amount = double.tryParse(_amount.text.trim()) ?? 0;
          await ref.read(expenseRepositoryProvider).addExpense(
                title: title,
                amount: amount,
                category: category,
                paidBy: memberId,
              );
        case 'task':
          await ref.read(taskRepositoryProvider).addTask(
                title: title,
                assigneeId: memberId,
                dueLabel: 'Today',
              );
        default:
          await ref.read(eventRepositoryProvider).addEvent(
                title: title,
                startsAt: _startsAt,
                endsAt: _endsAt,
                allDay: _allDay,
                location: _location.text.trim().isEmpty
                    ? null
                    : _location.text.trim(),
                memberId: memberId,
                category: category,
              );
      }

      try {
        await ref.read(syncServiceProvider).syncAll();
      } catch (_) {}

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _kind == 'expense'
                ? 'Expense added'
                : _kind == 'task'
                    ? 'Task added'
                    : 'Event added',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: ${_friendlyError(e)}')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.draft;
    final members = ref.watch(membersProvider).valueOrNull ?? const [];
    final confidencePct = (d.confidence.clamp(0.0, 1.0) * 100).round();

    return sheetBody(
      context: context,
      children: [
        sheetHandle(),
        const SizedBox(height: 8),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Review scan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            SoftPill(
              label: '$confidencePct% sure',
              selected: !d.isLowConfidence,
              background: d.isLowConfidence ? AppColors.tileYellow : null,
            ),
          ],
        ),
        if (d.summary != null && d.summary!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            d.summary!,
            style: const TextStyle(
              color: AppColors.inkSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (d.isLowConfidence) ...[
          const SizedBox(height: 10),
          NestCard(
            color: AppColors.tileYellow,
            bordered: false,
            child: const Text(
              'Low confidence — double-check the title, date, and amount before saving.',
              style: TextStyle(fontWeight: FontWeight.w600, height: 1.35),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            for (final kind in const ['event', 'expense', 'task'])
              SoftPill(
                label: kind[0].toUpperCase() + kind.substring(1),
                selected: _kind == kind,
                onTap: () => setState(() {
                  _kind = kind;
                  if (_category.text == 'General' ||
                      _category.text == 'Family') {
                    _category.text =
                        kind == 'expense' ? 'General' : 'Family';
                  }
                }),
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _title,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Title'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _category,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Category'),
        ),
        if (_kind == 'event') ...[
          const SizedBox(height: 10),
          NestCard(
            onTap: _pickStarts,
            child: Row(
              children: [
                const Icon(Icons.event_rounded, color: AppColors.ink),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _allDay
                        ? DateFormat.yMMMEd().format(_startsAt)
                        : DateFormat.yMMMEd().add_jm().format(_startsAt),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                SoftPill(
                  label: _allDay ? 'All day' : 'Timed',
                  selected: _allDay,
                  onTap: () => setState(() => _allDay = !_allDay),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          NestCard(
            onTap: _pickEnds,
            child: Row(
              children: [
                const Icon(Icons.schedule_rounded, color: AppColors.inkMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _endsAt == null
                        ? 'End time (optional)'
                        : (_allDay
                            ? DateFormat.yMMMEd().format(_endsAt!)
                            : DateFormat.yMMMEd().add_jm().format(_endsAt!)),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _endsAt == null
                          ? AppColors.inkMuted
                          : AppColors.ink,
                    ),
                  ),
                ),
                if (_endsAt != null)
                  IconButton(
                    tooltip: 'Clear end',
                    onPressed: () => setState(() => _endsAt = null),
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _location,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Location'),
          ),
        ],
        if (_kind == 'expense') ...[
          const SizedBox(height: 10),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Amount',
              prefixText: (d.currency == null || d.currency!.isEmpty)
                  ? '\$ '
                  : '${d.currency} ',
            ),
          ),
        ],
        if ((_kind == 'task' || _kind == 'expense') && members.isNotEmpty) ...[
          const SizedBox(height: 10),
          const Text(
            'Assign to',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final m in members)
                SoftPill(
                  label: m.name.split(' ').first,
                  selected: _assigneeId == m.id ||
                      (_assigneeId.isEmpty && m.id == members.first.id),
                  onTap: () => setState(() => _assigneeId = m.id),
                ),
            ],
          ),
        ],
        const SizedBox(height: 10),
        TextField(
          controller: _notes,
          maxLines: 2,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Notes'),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: _busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(_kind == 'expense'
                  ? 'Add expense'
                  : _kind == 'task'
                      ? 'Add task'
                      : 'Add event'),
        ),
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Discard'),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}
