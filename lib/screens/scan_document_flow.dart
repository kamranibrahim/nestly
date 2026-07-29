import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
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
  final picked = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'heic', 'pdf'],
    withData: true,
  );
  if (picked == null || picked.files.isEmpty) return;

  final file = picked.files.first;
  final bytes = file.bytes;
  if (bytes == null || bytes.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read that file')),
      );
    }
    return;
  }

  final mime = _mimeFor(file.extension, file.name);
  if (!context.mounted) return;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
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
              Text('Reading document…'),
            ],
          ),
        ),
      ),
    ),
  );

  try {
    final draft = await ref.read(documentAiServiceProvider).parseDocument(
          bytes: Uint8List.fromList(bytes),
          mimeType: mime,
          hint: hint,
        );
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    await showDocumentDraftSheet(context, ref, draft);
  } catch (e) {
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$e')),
    );
  }
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

class _DraftConfirmSheet extends ConsumerStatefulWidget {
  const _DraftConfirmSheet({required this.draft});

  final DocumentDraft draft;

  @override
  ConsumerState<_DraftConfirmSheet> createState() => _DraftConfirmSheetState();
}

class _DraftConfirmSheetState extends ConsumerState<_DraftConfirmSheet> {
  late final TextEditingController _title;
  late String _kind;
  late bool _allDay;
  late DateTime _startsAt;
  DateTime? _endsAt;
  late final TextEditingController _location;
  late final TextEditingController _amount;
  late final TextEditingController _notes;
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
    _notes = TextEditingController(text: d.notes ?? d.summary ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    setState(() => _busy = true);
    try {
      final members = ref.read(membersProvider).valueOrNull ?? const [];
      final memberId = members.isNotEmpty ? members.first.id : '';

      switch (_kind) {
        case 'expense':
          final amount = double.tryParse(_amount.text.trim()) ?? 0;
          await ref.read(expenseRepositoryProvider).addExpense(
                title: title,
                amount: amount,
                category: widget.draft.category ?? 'General',
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
                category: widget.draft.category ?? 'Family',
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
        SnackBar(content: Text('Could not save: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.draft;
    return sheetBody(
      context: context,
      children: [
        sheetHandle(),
        const SizedBox(height: 12),
        const Text(
          'Review scan',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
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
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            for (final kind in const ['event', 'expense', 'task'])
              SoftPill(
                label: kind[0].toUpperCase() + kind.substring(1),
                selected: _kind == kind,
                onTap: () => setState(() => _kind = kind),
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _title,
          decoration: const InputDecoration(labelText: 'Title'),
        ),
        if (_kind == 'event') ...[
          const SizedBox(height: 10),
          NestCard(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _startsAt,
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
              );
              if (date == null || !context.mounted) return;
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
            },
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
          const SizedBox(height: 10),
          TextField(
            controller: _location,
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
        const SizedBox(height: 10),
        TextField(
          controller: _notes,
          maxLines: 2,
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
        const SizedBox(height: 8),
      ],
    );
  }
}
