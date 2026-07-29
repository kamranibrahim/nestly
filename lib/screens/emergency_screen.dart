import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import '../widgets/sheet_form.dart';

class EmergencyScreen extends ConsumerWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(emergencyProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Emergency'),
        actions: [
          IconButton(
            onPressed: () => _addEntry(context, ref),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(10, 4, 10, 16),
        children: [
          const NestCard(
            color: AppColors.dangerSoft,
            child: Row(
              children: [
                Icon(Icons.wifi_off_rounded, color: AppColors.danger),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Available offline — critical info stays on this device and syncs when you are online.',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          entries.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('$e'),
            data: (items) {
              if (items.isEmpty) {
                return const NestCard(
                  child: Text(
                    'Add emergency contacts, allergies, and doctors.',
                    style: TextStyle(color: AppColors.inkMuted),
                  ),
                );
              }
              return NestCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.dangerSoft,
                          child: Icon(
                            _iconFor(items[i].iconName),
                            color: AppColors.danger,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          items[i].label,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.inkMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          items[i].value,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                            fontSize: 14.5,
                          ),
                        ),
                      ),
                      if (i != items.length - 1)
                        const Divider(height: 1, indent: 72),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String name) {
    switch (name) {
      case 'phone':
        return Icons.phone_in_talk_outlined;
      case 'doctor':
        return Icons.medical_services_outlined;
      case 'hospital':
        return Icons.local_hospital_outlined;
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'blood':
        return Icons.bloodtype_outlined;
      case 'shield':
        return Icons.health_and_safety_outlined;
      default:
        return Icons.info_outline_rounded;
    }
  }

  Future<void> _addEntry(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<({String label, String value})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return OwnedControllers(
          count: 2,
          builder: (context, c) {
            return sheetBody(
              context: context,
              children: [
                sheetHandle(),
                const SizedBox(height: 6),
                const Text(
                  'Emergency info',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: c[0],
                  decoration: const InputDecoration(labelText: 'Label'),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: c[1],
                  decoration: const InputDecoration(labelText: 'Details'),
                ),
                const SizedBox(height: 6),
                FilledButton(
                  onPressed: () => Navigator.pop(
                    context,
                    (label: c[0].text.trim(), value: c[1].text.trim()),
                  ),
                  child: const Text('Save offline'),
                ),
              ],
            );
          },
        );
      },
    );
    if (result != null &&
        result.label.isNotEmpty &&
        result.value.isNotEmpty) {
      await ref.read(emergencyRepositoryProvider).upsert(
            label: result.label,
            value: result.value,
          );
      try {
        await ref.read(syncServiceProvider).syncAll();
      } catch (_) {}
    }
  }
}
