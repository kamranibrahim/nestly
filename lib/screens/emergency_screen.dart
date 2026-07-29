import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Emergency')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          NestCard(
            color: AppColors.dangerSoft,
            child: const Row(
              children: [
                Icon(Icons.wifi_off_rounded, color: AppColors.danger),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Available offline — critical info stays on this device.',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          NestCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < MockData.emergency.length; i++) ...[
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.dangerSoft,
                      child: Icon(
                        MockData.emergency[i].icon,
                        color: AppColors.danger,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      MockData.emergency[i].label,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.inkMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      MockData.emergency[i].value,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                        fontSize: 14.5,
                      ),
                    ),
                    isThreeLine: false,
                  ),
                  if (i != MockData.emergency.length - 1)
                    const Divider(height: 1, indent: 72),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
