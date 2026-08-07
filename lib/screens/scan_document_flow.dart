import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/document_ai_service.dart';
import '../data/enums.dart';
import '../data/member_roles.dart';
import '../providers/providers.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import '../widgets/shimmer.dart';
import '../widgets/sheet_form.dart';
import '../data/sync_controller.dart';
import '../l10n/l10n_ext.dart';

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
      SnackBar(content: Text(context.l10n.scanSignIn)),
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
      SnackBar(
        content: Text(context.l10n.scanPickerFailed(_friendlyError(e, context.l10n))),
      ),
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
      SnackBar(
        content: Text(context.l10n.scanReadFailed),
      ),
    );
    return;
  }

  if (bytes.length > 4 * 1024 * 1024) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.scanTooLarge),
      ),
    );
    return;
  }

  final mime = _mimeFor(file.extension, file.name);

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (dialogContext) => Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 22,
                height: 22,
                child: NestShimmerCircle(size: 22),
              ),
              const SizedBox(width: 14),
              Flexible(
                child: Text(dialogContext.l10n.scanReading),
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
        content: Text(_friendlyError(e, context.l10n)),
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
              Text(
                context.l10n.scanWhatScanning,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'A hint helps Casaio pick the right draft.',
                style: TextStyle(color: AppColors.inkSecondary),
              ),
              const SizedBox(height: 14),
              for (final option in [
                (label: context.l10n.scanReceipt, hint: context.l10n.scanReceiptHint),
                (
                  label: context.l10n.scanInviteEvent,
                  hint: context.l10n.scanInviteHint,
                ),
                (
                  label: context.l10n.scanSchoolNotice,
                  hint: context.l10n.scanSchoolHint,
                ),
                (label: context.l10n.scanBillLabel, hint: context.l10n.scanBillHint),
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

String _friendlyError(Object e, AppLocalizations l10n) {
  final raw = (e is DocumentAiException ? e.message : '$e')
      .replaceFirst(RegExp(r'^Bad state:\s*'), '')
      .replaceFirst(RegExp(r'^Exception:\s*'), '')
      .trim();
  switch (raw) {
    case 'Sign in to scan documents.':
      return l10n.scanSignIn;
    case 'That file is too large. Use a photo or PDF under about 4 MB.':
      return l10n.scanFileTooLargeAi;
    case 'Scan returned an empty result. Try a clearer photo.':
      return l10n.scanEmptyResult;
    case 'Scan returned an unexpected response. Try another photo.':
      return l10n.scanUnexpected;
    case 'Scan timed out. Try a clearer photo or a smaller file.':
      return l10n.scanTimedOut;
    case 'Could not reach Vertex AI. Check your connection and try again.':
      return l10n.scanReachFailed;
    case 'AI quota reached for today. Try again later.':
      return l10n.scanQuotaReached;
  }
  if (raw.contains('Firebase Blaze plan')) return l10n.scanNeedBlaze;
  if (raw.contains('Vertex AI Gemini is not ready')) {
    return l10n.scanVertexNotReady;
  }
  return raw.isEmpty ? l10n.scanFailed : raw;
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
  late ScanDraftKind _kind;
  late bool _allDay;
  late DateTime _startsAt;
  DateTime? _endsAt;
  late DateTime _dueAt;
  late String _assigneeId;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final d = widget.draft;
    _title = TextEditingController(text: d.title);
    _kind = ScanDraftKind.tryParse(d.kind) ??
        (d.amount != null ? ScanDraftKind.expense : ScanDraftKind.event);
    _allDay = d.allDay;
    _startsAt = d.startsAt ?? DateTime.now().add(const Duration(hours: 1));
    _endsAt = d.endsAt;
    final now = DateTime.now();
    _dueAt = d.startsAt ??
        DateTime(now.year, now.month, now.day).add(const Duration(days: 7));
    _location = TextEditingController(text: d.location ?? '');
    _amount = TextEditingController(
      text: d.amount == null ? '' : d.amount!.toStringAsFixed(2),
    );
    _category = TextEditingController(
      text: (d.category == null || d.category!.isEmpty)
          ? (_kind == ScanDraftKind.expense || _kind == ScanDraftKind.bill
              ? ExpenseCategory.general.label
              : VaultFolder.family.label)
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

  Future<void> _pickDue() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueAt,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (date == null || !mounted) return;
    setState(() {
      _dueAt = DateTime(date.year, date.month, date.day);
    });
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.scanNeedTitle)),
      );
      return;
    }
    if (_kind == ScanDraftKind.expense || _kind == ScanDraftKind.bill) {
      final amount = double.tryParse(_amount.text.trim());
      if (amount == null || amount < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.scanNeedAmount)),
        );
        return;
      }
    }

    setState(() => _busy = true);
    try {
      final members = List.of(ref.read(membersProvider).valueOrNull ?? const [])
        ..sort((a, b) => MemberRoles.adultLikeFirst(a.role, b.role));
      final memberId = _assigneeId.isNotEmpty
          ? _assigneeId
          : (members.isNotEmpty ? members.first.id : '');
      final category = _category.text.trim().isEmpty
          ? (_kind == ScanDraftKind.expense || _kind == ScanDraftKind.bill
              ? ExpenseCategory.general.label
              : VaultFolder.family.label)
          : _category.text.trim();

      switch (_kind) {
        case ScanDraftKind.expense:
          final amount = double.tryParse(_amount.text.trim()) ?? 0;
          await ref.read(expenseRepositoryProvider).addExpense(
                title: title,
                amount: amount,
                category: category,
                paidBy: memberId,
              );
        case ScanDraftKind.bill:
          final amount = double.tryParse(_amount.text.trim()) ?? 0;
          await ref.read(billRepositoryProvider).addBill(
                title: title,
                amount: amount,
                dueAt: _dueAt,
              );
          await ref
              .read(notificationServiceProvider)
              .rescheduleBillReminders();
        case ScanDraftKind.task:
          await ref.read(taskRepositoryProvider).addTask(
                title: title,
                assigneeId: memberId,
                dueLabel: TaskDueLabel.today.label,
              );
        case ScanDraftKind.event:
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

      await syncAfterWrite(ref, context: context);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            switch (_kind) {
              ScanDraftKind.expense => context.l10n.scanExpenseAdded,
              ScanDraftKind.bill => context.l10n.scanBillAdded,
              ScanDraftKind.task => context.l10n.scanTaskAdded,
              ScanDraftKind.event => context.l10n.scanEventAdded,
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.scanSaveFailed(_friendlyError(e, context.l10n)))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.draft;
    final members = List.of(ref.watch(membersProvider).valueOrNull ?? const [])
      ..sort((a, b) => MemberRoles.adultLikeFirst(a.role, b.role));
    final confidencePct = (d.confidence.clamp(0.0, 1.0) * 100).round();
    final defaultAssigneeId = members.isEmpty ? '' : members.first.id;

    return sheetBody(
      context: context,
      children: [
        sheetHandle(),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.scanReview,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
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
            child: Text(
              context.l10n.scanLowConfidence,
              style: const TextStyle(fontWeight: FontWeight.w600, height: 1.35),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final kind in ScanDraftKind.values)
              SoftPill(
                label: kind.display(context.l10n),
                selected: _kind == kind,
                onTap: () => setState(() {
                  _kind = kind;
                  if (_category.text == ExpenseCategory.general.label ||
                      _category.text == VaultFolder.family.label) {
                    _category.text =
                        (kind == ScanDraftKind.expense ||
                            kind == ScanDraftKind.bill)
                        ? ExpenseCategory.general.label
                        : VaultFolder.family.label;
                  }
                }),
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _title,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: context.l10n.commonTitle),
        ),
        if (_kind != ScanDraftKind.bill) ...[
          const SizedBox(height: 10),
          TextField(
            controller: _category,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: context.l10n.commonCategory),
          ),
        ],
        if (_kind == ScanDraftKind.event) ...[
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
                  label: _allDay ? context.l10n.commonAllDay : context.l10n.scanTimed,
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
                        ? context.l10n.scanEndTimeOptional
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
                    tooltip: context.l10n.scanClearEnd,
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
            decoration: InputDecoration(labelText: context.l10n.commonLocation),
          ),
        ],
        if (_kind == ScanDraftKind.expense || _kind == ScanDraftKind.bill) ...[
          const SizedBox(height: 10),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: _kind == ScanDraftKind.bill
                  ? context.l10n.scanAmountDue
                  : context.l10n.commonAmount,
              prefixText: (d.currency == null || d.currency!.isEmpty)
                  ? '\$ '
                  : '${d.currency} ',
            ),
          ),
        ],
        if (_kind == ScanDraftKind.bill) ...[
          const SizedBox(height: 10),
          NestCard(
            onTap: _pickDue,
            child: Row(
              children: [
                const Icon(Icons.event_available_rounded, color: AppColors.ink),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Due ${DateFormat.yMMMEd().format(_dueAt)}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const Icon(Icons.edit_calendar_outlined,
                    color: AppColors.inkMuted, size: 20),
              ],
            ),
          ),
        ],
        if ((_kind == ScanDraftKind.task || _kind == ScanDraftKind.expense) &&
            members.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            context.l10n.scanAssignTo,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final m in members)
                SoftPill(
                  label:
                      '${m.name.split(' ').first} · ${localizedMemberRole(m.role, context.l10n)}',
                  selected: _assigneeId == m.id ||
                      (_assigneeId.isEmpty && m.id == defaultAssigneeId),
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
          decoration: InputDecoration(labelText: context.l10n.commonNotes),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: _busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: NestShimmerCircle(size: 20),
                )
              : Text(switch (_kind) {
                  ScanDraftKind.expense => context.l10n.scanAddExpense,
                  ScanDraftKind.bill => context.l10n.scanAddBill,
                  ScanDraftKind.task => context.l10n.scanAddTask,
                  ScanDraftKind.event => context.l10n.scanAddEvent,
                }),
        ),
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: Text(context.l10n.commonDiscard),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}
