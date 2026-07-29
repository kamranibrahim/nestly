import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';

class VaultScreen extends StatelessWidget {
  const VaultScreen({super.key});

  static const _folders = [
    (Icons.family_restroom_rounded, 'Family', AppColors.tileBlue),
    (Icons.medical_services_rounded, 'Health', AppColors.tilePink),
    (Icons.home_rounded, 'House', AppColors.tileGreen),
    (Icons.work_rounded, 'Work', AppColors.tileOrange),
    (Icons.directions_car_rounded, 'Car', AppColors.tilePurple),
    (Icons.account_balance_rounded, 'Finance', AppColors.tileTeal),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Documents'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.upload_file_rounded),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
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
                  onTap: () {},
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
          NestCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < MockData.vault.length; i++) ...[
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        MockData.vault[i].icon,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      MockData.vault[i].title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${MockData.vault[i].category} · ${MockData.vault[i].updated}',
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.inkMuted,
                    ),
                  ),
                  if (i != MockData.vault.length - 1)
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
